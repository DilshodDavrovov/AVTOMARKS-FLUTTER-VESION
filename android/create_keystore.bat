@echo off
echo Creating keystore for VENONS:AVTOMARKS...
echo.

REM Try to find Java keytool
set KEYTOOL_PATH=

REM Check common Java locations
if exist "%JAVA_HOME%\bin\keytool.exe" (
    set KEYTOOL_PATH=%JAVA_HOME%\bin\keytool.exe
) else if exist "%ProgramFiles%\Java\jdk*\bin\keytool.exe" (
    for /d %%i in ("%ProgramFiles%\Java\jdk*") do set KEYTOOL_PATH=%%i\bin\keytool.exe
) else if exist "%ProgramFiles(x86)%\Java\jdk*\bin\keytool.exe" (
    for /d %%i in ("%ProgramFiles(x86)%\Java\jdk*") do set KEYTOOL_PATH=%%i\bin\keytool.exe
)

if "%KEYTOOL_PATH%"=="" (
    echo ERROR: Java keytool not found!
    echo Please install Java JDK or set JAVA_HOME environment variable.
    echo.
    echo You can download Java from: https://adoptium.net/
    pause
    exit /b 1
)

echo Using keytool from: %KEYTOOL_PATH%
echo.

cd /d "%~dp0app"

"%KEYTOOL_PATH%" -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key -storepass venons2024 -keypass venons2024 -dname "CN=VENONS AVTOMARKS, OU=Development, O=VENONS, L=City, ST=State, C=UZ"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Keystore created successfully!
    echo File: %CD%\key.jks
    echo.
    echo You can now build release APK with: flutter build apk --release
) else (
    echo.
    echo ERROR: Failed to create keystore!
)

pause
