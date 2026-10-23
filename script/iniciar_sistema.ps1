$ErrorActionPreference = "Stop"
$projectPath = Split-Path -Parent $PSScriptRoot
$serverPidFile = Join-Path $PSScriptRoot "hotel-events-server.pid"
$cssPidFile = Join-Path $PSScriptRoot "hotel-events-css.pid"
$railsPidFile = Join-Path $projectPath "tmp\pids\server.pid"
$logFile = Join-Path $projectPath "log\inicializacao-local.log"
Set-Location $projectPath

function Write-StartupLog([string]$message) {
  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $message" | Add-Content -Path $logFile -Encoding UTF8
}

function Show-Notice([string]$message, [int]$style = 64) {
  try {
    $shell = New-Object -ComObject WScript.Shell
    $null = $shell.Popup($message, 0, "Hotel Eventos", $style)
  } catch { }
}

function Open-LocalApp {
  try {
    $shell = New-Object -ComObject WScript.Shell
    $shell.Run("http://localhost:3000", 1, $false)
    Write-StartupLog "Sistema aberto no navegador."
  } catch {
    Write-StartupLog "AVISO: sistema ativo em http://localhost:3000; o navegador nao abriu automaticamente."
    Show-Notice "O sistema está pronto. Abra http://localhost:3000 no navegador." 64
  }
}

function Invoke-LoggedCommand([string]$command, [string]$label) {
  $outputFile = Join-Path $env:TEMP "hotel-events-$label-output.log"
  $errorFile = Join-Path $env:TEMP "hotel-events-$label-error.log"
  Remove-Item $outputFile, $errorFile -ErrorAction SilentlyContinue
  $process = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', $command) `
    -WorkingDirectory $projectPath -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $outputFile -RedirectStandardError $errorFile
  foreach ($file in @($outputFile, $errorFile)) {
    if (Test-Path $file) { Get-Content $file | Add-Content -Path $logFile -Encoding UTF8 }
  }
  Remove-Item $outputFile, $errorFile -ErrorAction SilentlyContinue
  return $process.ExitCode
}

function Start-HiddenCommand([string]$commandFile, [string]$pidFile) {
  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = $env:ComSpec
  $startInfo.Arguments = '/d /c ""' + $commandFile + '""'
  $startInfo.WorkingDirectory = $projectPath
  $startInfo.CreateNoWindow = $true
  $startInfo.UseShellExecute = $false
  $process = [System.Diagnostics.Process]::Start($startInfo)
  $process.Id | Set-Content -Path $pidFile -Encoding ASCII
  return $process.Id
}

function Test-ServerReady {
  try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/users/sign_in" -TimeoutSec 2 -UseBasicParsing
    return ($response.StatusCode -ge 200)
  } catch {
    return $false
  }
}

try {
  if (Test-ServerReady) {
    $cssRoot = if (Test-Path $cssPidFile) { (Get-Content $cssPidFile -Raw).Trim() } else { "" }
    if ($cssRoot -match '^\d+$' -and -not (Get-Process -Id ([int]$cssRoot) -ErrorAction SilentlyContinue)) {
      Remove-Item $cssPidFile -ErrorAction SilentlyContinue
      $cssRoot = ""
    }
    if (-not $cssRoot) {
      $cssId = Start-HiddenCommand (Join-Path $PSScriptRoot "iniciar_estilos.cmd") $cssPidFile
      Write-StartupLog "Compilador de estilos iniciado (PID $cssId)."
    }
    Write-StartupLog "Servidor existente detectado; nenhuma segunda instancia foi iniciada."
    Open-LocalApp
    exit 0
  }

  if (Test-Path $railsPidFile) {
    $railsId = (Get-Content $railsPidFile -Raw -ErrorAction SilentlyContinue).Trim()
    $railsProcess = if ($railsId -match '^\d+$') { Get-Process -Id ([int]$railsId) -ErrorAction SilentlyContinue } else { $null }
    if ($railsProcess -and $railsProcess.ProcessName -eq "ruby") {
      Write-StartupLog "Servidor Rails (PID $railsId) ainda inicializando; aguardando resposta."
      $alreadyStarting = $true
    } else {
      Remove-Item $railsPidFile -ErrorAction SilentlyContinue
      Write-StartupLog "Arquivo PID obsoleto do Rails removido ($railsId)."
    }
  }

  if (-not $alreadyStarting) {
    if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) { throw "Ruby não foi encontrado. É necessário instalar o Ruby 4.0 para este computador." }
    if (-not (Get-Command bundle -ErrorAction SilentlyContinue)) { throw "Bundler não foi encontrado. A instalação do Ruby está incompleta." }

    Write-StartupLog "Verificando dependências."
    if ((Invoke-LoggedCommand 'bundle check' 'dependencies') -ne 0) {
      throw "Faltam dependências do sistema. Consulte o responsável pela instalação."
    }

    Write-StartupLog "Preparando o banco de dados."
    if ((Invoke-LoggedCommand 'bundle exec rails db:prepare' 'database') -ne 0) {
      throw "Não foi possível preparar o banco de dados. Consulte a pasta log."
    }

    $serverId = Start-HiddenCommand (Join-Path $PSScriptRoot "iniciar_servidor.cmd") $serverPidFile
    Write-StartupLog "Servidor Rails iniciado (PID $serverId)."

    $cssId = Start-HiddenCommand (Join-Path $PSScriptRoot "iniciar_estilos.cmd") $cssPidFile
    Write-StartupLog "Compilador de estilos iniciado (PID $cssId)."
  }

  $ready = $false
  for ($attempt = 0; $attempt -lt 60; $attempt++) {
    if (Test-ServerReady) { $ready = $true; break }
    Start-Sleep -Seconds 2
  }
  if (-not $ready) { throw "O servidor não respondeu após 2 minutos. Consulte log/servidor-local.log." }

  Open-LocalApp
} catch {
  $details = $_.Exception.Message
  if ([string]::IsNullOrWhiteSpace($details)) { $details = $_.ToString() }
  Write-StartupLog "ERRO: $details"
  Show-Notice "Não foi possível iniciar o Hotel Eventos.`n`n$details`n`nConsulte a pasta log para ver os detalhes." 16
  exit 1
}
