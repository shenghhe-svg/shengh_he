@echo off
setlocal
if "%MS_INSTALL_ROOT%"=="" (
  echo Please set MS_INSTALL_ROOT to your BIOVIA Materials Studio install directory.
  echo Example: set "MS_INSTALL_ROOT=C:\Program Files\BIOVIA\Materials Studio"
  exit /b 1
)
set "MS_MCP_ROOT=%~dp0.."
if "%MS_MCP_QUEUE_DIR%"=="" set "MS_MCP_QUEUE_DIR=%MS_MCP_ROOT%\workspace\.mcp-queue"
cd /d "%~dp0"
call "%MS_INSTALL_ROOT%\etc\Scripting\bin\RunMatScript.bat" mcp_loop_gui
endlocal
