@echo off
cd /d "%~dp0"
where godot >nul 2>nul
if errorlevel 1 (
  echo Importald az itt talalhato project.godot fajlt Godot 4.7.2-ben, majd F5.
  echo Vagy add a Godot mappajat a PATH-hoz godot.exe nevvel.
  pause
  exit /b 1
)
godot --path .
