@echo off

SET VSWHERE="C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere"

:: See https://github.com/microsoft/vswhere/wiki/Find-VC
for /f "usebackq delims=*" %%i in (`%VSWHERE% -latest -property installationPath`) do (
  call "%%i\VC\Auxiliary\Build\vcvarsall.bat" %*
)

bash -c "export -p > env.sh"
