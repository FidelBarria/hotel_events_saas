@echo off
cd /d "%~dp0.."
bundle exec rails server >> "%~dp0..\log\servidor-local.log" 2>&1
