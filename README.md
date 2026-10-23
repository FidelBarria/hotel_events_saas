# Hotel Eventos

## Usar no Windows

1. Dê dois cliques no atalho **Hotel Eventos** nesta pasta.
2. Aguarde a abertura do navegador. Na primeira inicialização, o sistema prepara o banco de dados.
3. Para fechar, dê dois cliques em **Encerrar Sistema.vbs**.

O atalho inicia o sistema sem abrir janelas de terminal. Se aparecer uma mensagem de erro, consulte os arquivos da pasta `log` ou peça ajuda ao responsável pela instalação.

## Backups automaticos

Depois de cada criacao, alteracao ou exclusao confirmada no banco, o sistema cria uma copia consistente do SQLite em `storage/backups`. Sao mantidas as 30 copias mais recentes. Os arquivos ficam neste computador, junto com os dados do sistema.
