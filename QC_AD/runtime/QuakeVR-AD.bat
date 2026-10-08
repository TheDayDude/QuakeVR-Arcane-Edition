@echo off
cd /d "%~dp0"
set "AD_HD_GAME="
if exist "%~dp0ad_hd\textures\" set "AD_HD_GAME=-game ad_hd"
start "" "%~dp0ironwail-ad.exe" -game quakevr -game ad %AD_HD_GAME% -game advr +exec advr_start.cfg %*
