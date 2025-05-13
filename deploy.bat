@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM Script để build Docker image, dừng/xóa container cũ và chạy container mới.
REM Sử dụng các biến môi trường được truyền từ GitHub Actions workflow cho các cấu hình nhạy cảm.

REM Tham số đầu vào:
REM %1: Tên cơ sở của Docker image (ví dụ: myfastapiapp)
REM %2: Tag cụ thể cho Docker image (ví dụ: commit SHA)

REM Kiểm tra các tham số đầu vào
IF "%~1"=="" (
    ECHO Loi: Ten co so cua image (tham so 1) la bat buoc.
    EXIT /B 1
)
IF "%~2"=="" (
    ECHO Loi: Tag cu the cho image (tham so 2) la bat buoc.
    EXIT /B 1
)

SET BASE_IMAGE_NAME=%1
SET SPECIFIC_TAG=%2
SET LATEST_TAG=latest
SET CONTAINER_NAME=%BASE_IMAGE_NAME%-container

ECHO =========== BUOC 1: BUILD DOCKER IMAGE ===========
ECHO Dang build Docker image: %BASE_IMAGE_NAME%:%SPECIFIC_TAG% va %BASE_IMAGE_NAME%:%LATEST_TAG%
docker build -t %BASE_IMAGE_NAME%:%SPECIFIC_TAG% -t %BASE_IMAGE_NAME%:%LATEST_TAG% .
IF ERRORLEVEL 1 (
    ECHO Build Docker image THAT BAI!
    EXIT /B %ERRORLEVEL%
)
ECHO Build Docker image THANH CONG.
ECHO.

ECHO =========== BUOC 2: CAP NHAT DOCKER CONTAINER ===========
ECHO Dang dung container hien tai (neu co): %CONTAINER_NAME%
docker stop %CONTAINER_NAME% > nul 2>&1
ECHO Dang xoa container hien tai (neu co): %CONTAINER_NAME%
docker rm %CONTAINER_NAME% > nul 2>&1
ECHO Container cu da duoc dung va xoa (bo qua loi neu khong tim thay).
ECHO.

ECHO Dang chay container moi: %CONTAINER_NAME% tu image %BASE_IMAGE_NAME%:%SPECIFIC_TAG%
REM Cac bien moi truong nhu DB_SERVER, DB_USER, PROJECT_NAME, v.v.
REM duoc mong doi la da duoc thiet lap trong moi truong cua shell
REM boi buoc 'env:' trong GitHub Actions workflow.

docker run -d --name %CONTAINER_NAME% -p 6020:8000 --restart always ^
    -e PROJECT_NAME="%PROJECT_NAME%" ^
    -e PROJECT_VERSION="%PROJECT_VERSION%" ^
    -e LOG_LEVEL="%LOG_LEVEL%" ^
    -e DB_SERVER="%DB_SERVER%" ^
    -e DB_PORT="%DB_PORT%" ^
    -e DB_USER="%DB_USER%" ^
    -e DB_PASSWORD="%DB_PASSWORD%" ^
    -e DB_NAME="%DB_NAME%" ^
    -e DB_DRIVER="%DB_DRIVER%" ^
    %BASE_IMAGE_NAME%:%SPECIFIC_TAG%

IF ERRORLEVEL 1 (
    ECHO Chay container moi THAT BAI!
    EXIT /B %ERRORLEVEL%
)
ECHO Container moi %CONTAINER_NAME% da khoi dong thanh cong voi image %BASE_IMAGE_NAME%:%SPECIFIC_TAG%.
ECHO.

ECHO =========== HOAN TAT DEPLOYMENT ===========
EXIT /B 0