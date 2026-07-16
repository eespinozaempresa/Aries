@echo off
echo Iniciando Aries ERP...

echo [1/2] Arrancando backend NestJS...
start "Aries - Backend" powershell -NoExit -Command "cd 'C:\Users\refulio\Downloads\Aries\backend'; npm run start:dev"

echo Esperando 8 segundos para que el backend este listo...
timeout /t 8 /nobreak > nul

echo [2/2] Arrancando Flutter Web...
start "Aries - Flutter Web" powershell -NoExit -Command "cd 'C:\Users\refulio\Downloads\Aries\mobile'; & 'C:\Users\refulio\develop\flutter\bin\flutter.bat' run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1"

echo.
echo Listo. Chrome abrira automaticamente cuando Flutter termine de compilar.
echo Puedes cerrar esta ventana.
pause
