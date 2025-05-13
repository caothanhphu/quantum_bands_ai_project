@echo OFF
ECHO Starting CI/CD Deployment Process...

REM Bước 1: Kiểm tra Docker (Tùy chọn, vì workflow đã có thể làm)
ECHO Verifying Docker installation...
docker --version
IF %ERRORLEVEL% NEQ 0 (
    ECHO Docker command failed. Exiting.
    EXIT /B 1
)

REM Bước 2: Build Docker image
ECHO Building Docker image...
docker build --no-cache --progress=plain -t quantumbands-fastapi-image -f Dockerfile .
IF %ERRORLEVEL% NEQ 0 (
    ECHO Docker build failed. Exiting.
    EXIT /B 1
)

REM Bước 3: Dừng và xóa container cũ
ECHO Stopping and Removing existing container...
SET "containerName=quantumbands-fastapi-container"
FOR /F "tokens=*" %%i IN ('docker ps -a -q --filter "name=%containerName%"') DO (
    ECHO Stopping and removing existing container: %containerName% (%%i)
    docker stop %containerName%
    docker rm %containerName%
)
IF NOT ERRORLEVEL 1 (
    ECHO No existing container named %containerName% found or it was successfully removed.
)


REM Bước 4: Chạy container mới
ECHO Running new Docker container...
REM Các biến môi trường DB_PASSWORD và JWT_SECRET sẽ được truyền từ GitHub Actions workflow
REM và được runner thiết lập thành biến môi trường cho tiến trình chạy file batch này.
docker run -d --restart always ^
    -p 6020:8080 ^
    --name %containerName% ^
    -e PROJECT_NAME="%PROJECT_NAME%" ^
    -e PROJECT_VERSION="%PROJECT_VERSION%" ^
    -e LOG_LEVEL="%LOG_LEVEL%" ^
    -e DB_SERVER="%DB_SERVER%" ^
    -e DB_PORT="%DB_PORT%" ^
    -e DB_USER="%DB_USER%" ^
    -e DB_PASSWORD="%DB_PASSWORD%" ^
    -e DB_NAME="%DB_NAME%" ^
    -e DB_DRIVER="%DB_DRIVER%" ^
    quantumbands-fastapi-image

IF %ERRORLEVEL% NEQ 0 (
    ECHO Failed to run new Docker container. Exiting.
    EXIT /B 1
)

ECHO New container '%containerName%' started. Access it on host at http://localhost:6020
ECHO Deployment process completed successfully.
EXIT /B 0
