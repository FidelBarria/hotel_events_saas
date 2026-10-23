@echo off
cd /d "%~dp0.."
bundle exec rails tailwindcss:watch >> "%~dp0..\log\estilos-local.log" 2>&1
