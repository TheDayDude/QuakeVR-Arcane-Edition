@echo off
cd /d "%~dp0"
start "" "%~dp0ironwail-ad.exe" -game quakevr -game ad -game advr +exec advr_start.cfg %*
