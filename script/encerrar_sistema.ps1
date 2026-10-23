$ErrorActionPreference = "SilentlyContinue"
$projectPath = Split-Path -Parent $PSScriptRoot
$pidFiles = @(
  (Join-Path $PSScriptRoot "hotel-events-server.pid"),
  (Join-Path $PSScriptRoot "hotel-events-css.pid")
)

foreach ($pidFile in $pidFiles) {
  if (Test-Path $pidFile) {
    $processId = (Get-Content $pidFile -Raw).Trim()
    if ($processId -match '^\d+$' -and (Get-Process -Id ([int]$processId) -ErrorAction SilentlyContinue)) {
      & taskkill.exe /PID $processId /T /F | Out-Null
    }
    Remove-Item $pidFile
  }
}

$railsPidFile = Join-Path $projectPath "tmp\pids\server.pid"
if (Test-Path $railsPidFile) {
  $railsId = (Get-Content $railsPidFile -Raw).Trim()
  if ($railsId -match '^\d+$' -and (Get-Process -Id ([int]$railsId) -ErrorAction SilentlyContinue)) {
    & taskkill.exe /PID $railsId /T /F | Out-Null
  }
  Start-Sleep -Seconds 2
  if ($railsId -match '^\d+$' -and -not (Get-Process -Id ([int]$railsId) -ErrorAction SilentlyContinue)) {
    Remove-Item $railsPidFile
  }
}

$listener = netstat.exe -ano -p tcp | Select-String '127\.0\.0\.1:3000\s+.*LISTENING'
Add-Type -AssemblyName PresentationFramework
if ($listener) {
  [System.Windows.MessageBox]::Show("O servidor ainda parece ativo na porta 3000. Tente encerrar novamente.", "Hotel Eventos", "OK", "Warning") | Out-Null
} else {
  [System.Windows.MessageBox]::Show("Hotel Eventos foi encerrado.", "Hotel Eventos", "OK", "Information") | Out-Null
}
