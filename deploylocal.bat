echo Dang thiet lap bien moi truong cho Test...
set PROJECT_NAME=quantum_bands_ai_project
set PROJECT_VERSION=latest
set LOG_LEVEL=INFO
set DB_SERVER=host.docker.internal
set DB_PORT=1433
set DB_USER=finix
set DB_PASSWORD=YourStrongP@sswordHere_123!
set DB_NAME=FinixAI
set DB_DRIVER=ODBC Driver 18 for SQL Server

echo.
echo Bat dau chay deploy.bat...
call deploy.bat %PROJECT_NAME% %PROJECT_VERSION%

echo.
echo Kiem tra Docker containers:
docker ps -a --filter "name=%PROJECT_NAME%-container"

echo.
echo De xem log cua container (thay ten container neu can):
echo docker logs %PROJECT_NAME%-container