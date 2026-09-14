@echo off
cd /d "%~dp0"
where godot >nul 2>nul
if errorlevel 1 (
  echo A Godot 4.7.2 godot.exe legyen a PATH-ban.
  echo Editorban jobb felul valaszd a Forward+ renderelot, majd inditsd ujra.
  pause
  exit /b 1
)
godot --path . --rendering-method forward_plus --rendering-driver vulkan
