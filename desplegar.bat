@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

set "API_URL_PROD=https://aries-nsnz.onrender.com/api/v1"
set "FLUTTER=C:\Users\refulio\develop\flutter\bin\flutter.bat"
set "ROOT=%~dp0"

echo ============================================
echo   Aries - Despliegue a produccion
echo   Backend:  Render  (%API_URL_PROD%)
echo   Frontend: Firebase Hosting (aries-pe.web.app)
echo   Base de datos: Supabase
echo ============================================
echo.

REM --- 0) Recordatorio de migraciones de Supabase (no se aplican solas) ---
if exist "%ROOT%supabase\migrations" (
    echo [0/5] Migraciones en supabase\migrations\:
    dir /b /o:n "%ROOT%supabase\migrations"
    echo.
    echo   Si agregaste un archivo .sql nuevo ahi arriba, debes aplicarlo TU MISMO
    echo   en el SQL Editor de Supabase antes de continuar. El backend NO
    echo   corre migraciones automaticamente al desplegar.
    echo.
    set /p SUPABASE_OK="¿Ya aplicaste (o no hay) migraciones pendientes en Supabase? (S/N): "
    if /I not "!SUPABASE_OK!"=="S" (
        echo.
        echo Aplica las migraciones pendientes en https://app.supabase.com y vuelve a correr este script.
        pause
        exit /b 1
    )
)

echo.
echo [1/5] Estado de git...
git status --porcelain > "%TEMP%\aries_git_status.txt"
findstr /r "." "%TEMP%\aries_git_status.txt" >nul
if %errorlevel%==0 (
    echo Hay cambios sin commitear:
    git status --short
    echo.
    set /p DOCOMMIT="¿Commit y push de estos cambios a GitHub ahora? (S/N): "
    if /I "!DOCOMMIT!"=="S" (
        set /p COMMITMSG="Mensaje del commit: "
        git add -A
        git commit -m "!COMMITMSG!"
        if errorlevel 1 (
            echo ERROR al commitear. Abortando.
            pause
            exit /b 1
        )
    ) else (
        echo Continuando SIN commitear los cambios locales pendientes.
    )
) else (
    echo No hay cambios pendientes sin commitear.
)

echo.
echo [2/5] Subiendo a GitHub - esto dispara el auto-deploy del backend en Render...
git push origin master
if errorlevel 1 (
    echo ERROR al hacer push a GitHub. Abortando.
    pause
    exit /b 1
)

echo.
echo Render suele tardar 2 a 5 minutos en desplegar el backend tras el push.
echo Puedes seguir el progreso en: https://dashboard.render.com
echo.
set /p SIGUIENTE="Presiona ENTER cuando el deploy en Render haya terminado para continuar..."

echo.
echo [3/5] Verificando que el backend de produccion responda...
curl -s -o nul -w "  %API_URL_PROD%/auth/empresas -> HTTP %%{http_code}\n" "%API_URL_PROD%/auth/empresas"

echo.
echo [4/5] Compilando Flutter Web para produccion (apuntando a Render)...
cd /d "%ROOT%mobile"
call "%FLUTTER%" build web --release --dart-define=API_URL=%API_URL_PROD%
if errorlevel 1 (
    echo ERROR compilando Flutter Web. Abortando.
    cd /d "%ROOT%"
    pause
    exit /b 1
)
cd /d "%ROOT%"

echo.
echo [5/5] Desplegando a Firebase Hosting...
call npx firebase deploy --only hosting
if errorlevel 1 (
    echo ERROR desplegando a Firebase Hosting. Abortando.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Despliegue completo: https://aries-pe.web.app
echo ============================================
pause
