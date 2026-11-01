@echo off
setlocal
cd /d "%~dp0"

rem Include the standard MSYS2 UCRT64 install if VS Code's Path is stale.
where g++ >nul 2>nul
if errorlevel 1 if exist "C:\msys64\ucrt64\bin\g++.exe" set "PATH=C:\msys64\ucrt64\bin;%PATH%"
where g++ >nul 2>nul
if errorlevel 1 goto missing

echo Building C++ terrain generator...
g++ -std=c++17 -O2 -g -Wall -Wextra -pedantic "hi.c++" -o "voxel.exe"
if errorlevel 1 goto failed
"%CD%\voxel.exe" 42 48 world
if errorlevel 1 goto failed
if not exist "world.html" goto failed
start "" "%CD%\world.html"
exit /b 0

:missing
echo A C++ compiler was not found.
echo Install MSYS2 from https://www.msys2.org/ then open its UCRT64 terminal.
echo Run: pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-gdb
echo Add C:\msys64\ucrt64\bin to your Windows user Path, then restart VS Code.
echo Open terrain.html to view the included sample without installing anything.
pause
exit /b 1

:failed
echo.
echo Build or terrain generation failed. Read the error above.
echo Close any running voxel.exe before rebuilding.
echo You can open terrain.html to view the included sample.
pause
exit /b 1
