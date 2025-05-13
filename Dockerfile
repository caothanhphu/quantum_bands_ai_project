# Sử dụng base image Python 3.13 chính thức.
# Hãy kiểm tra Docker Hub để có tag chính xác, ví dụ: python:3.13-slim hoặc python:3.13.3-slim
# Giả sử python:3.13-slim đã có sẵn và hỗ trợ 3.13.3
FROM python:3.13-slim

# Đặt các biến môi trường cho Poetry
# Thay thế 1.8.2 bằng phiên bản Poetry ổn định mới nhất nếu cần
ENV POETRY_VERSION=2.1.3
ENV POETRY_HOME="/opt/poetry"
# Cấu hình Poetry để cài đặt packages vào system Python của container
# thay vì tạo virtual environment riêng. Đây là cách làm phổ biến trong Docker.
ENV POETRY_VIRTUALENVS_CREATE="false"

# Thêm thư mục bin của Poetry vào PATH
ENV PATH="$POETRY_HOME/bin:$PATH"

# --- CÀI ĐẶT CÁC GÓI HỆ THỐNG VÀ DEPENDENCIES ---

# Bước 1: Cập nhật apt và cài đặt các công cụ cơ bản + prerequisites cho Poetry và ODBC
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        gnupg \
        apt-transport-https \
        unixodbc-dev \  
    && rm -rf /var/lib/apt/lists/*
RUN echo "BUOC 1 HOAN TAT: Cong cu co ban va unixodbc-dev da duoc cai dat."

# Bước 2: Cài đặt Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
RUN echo "BUOC 2 HOAN TAT: Poetry da duoc cai dat."

# Bước 3: Thiết lập Microsoft repository để cài đặt ODBC driver
RUN set -e && \
    export DEBIAN_VERSION_MAJOR=$(cat /etc/debian_version 2>/dev/null | cut -d'.' -f1 || echo "unknown") && \
    echo "Phien ban Debian duoc phat hien: $DEBIAN_VERSION_MAJOR" && \
    if [ "$DEBIAN_VERSION_MAJOR" = "unknown" ] || ! curl --output /dev/null --silent --head --fail "https://packages.microsoft.com/config/debian/${DEBIAN_VERSION_MAJOR}/packages-microsoft-prod.deb"; then \
        echo "LOI NGHIEM TRONG: Khong tim thay package config cua Microsoft cho phien ban Debian $DEBIAN_VERSION_MAJOR. Kiem tra URL va phien ban Debian duoc ho tro." ; \
        exit 1; \
    else \
        echo "Dang tai packages-microsoft-prod.deb cho Debian $DEBIAN_VERSION_MAJOR..." && \
        curl -L -o packages-microsoft-prod.deb "https://packages.microsoft.com/config/debian/${DEBIAN_VERSION_MAJOR}/packages-microsoft-prod.deb" && \
        echo "Dang cai dat packages-microsoft-prod.deb..." && \
        dpkg -i packages-microsoft-prod.deb && \
        echo "Da xoa packages-microsoft-prod.deb." && \
        rm packages-microsoft-prod.deb ; \
    fi
RUN echo "BUOC 3 HOAN TAT: Microsoft repository da duoc cau hinh."

# Bước 4: Cập nhật apt-get lại và cài đặt Microsoft ODBC driver & tools
RUN set -e && \
    apt-get update && \
    echo "Dang tien hanh cai dat msodbcsql17 va mssql-tools17..." && \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql18 \
        mssql-tools18 && \
    echo "Da cai dat xong msodbcsql18 va mssql-tools18." && \
    rm -rf /var/lib/apt/lists/*
RUN echo "BUOC 4 HOAN TAT: Microsoft ODBC Driver (msodbcsql18) va tools da duoc cai dat."

# >>> THÊM BƯỚC DEBUG NÀY VÀO NẾU CHƯA CÓ <<<
RUN echo "--- Thong tin Debug Driver ODBC ---" && \
    echo "1. Kiem tra cau hinh unixODBC (odbcinst -j):" && \
    (odbcinst -j || echo "Lenh odbcinst -j that bai hoac khong tim thay.") && \
    echo "---" && \
    echo "2. Noi dung file /etc/odbcinst.ini (neu ton tai):" && \
    (cat /etc/odbcinst.ini 2>/dev/null || echo "/etc/odbcinst.ini khong tim thay hoac khong doc duoc.") && \
    echo "---" && \
    echo "3. Liet ke cac driver da dang ky voi odbcinst (odbcinst -q -d):" && \
    (odbcinst -q -d || echo "Lenh odbcinst -q -d that bai.") && \
    echo "---" && \
    echo "4. Tim kiem file thu vien libmsodbcsql-17:" && \
    (find /opt /usr -name "libmsodbcsql-17.*" 2>/dev/null || echo "Khong tim thay file libmsodbcsql-17 nao.") && \
    echo "--- Ket thuc Thong tin Debug Driver ODBC ---"
RUN echo "BUOC DEBUG ODBC HOAN TAT."
# >>> KẾT THÚC BƯỚC DEBUG <<<

# Bước 5: (Tùy chọn nhưng khuyến nghị) Thêm ODBC tools vào PATH
ENV PATH="${PATH}:/opt/mssql-tools17/bin"
RUN echo "BUOC 5 HOAN TAT: ODBC tools da duoc them vao PATH."

# Bước 6: Dọn dẹp các gói không cần thiết cuối cùng
RUN apt-get autoremove -y && \
    apt-get clean
RUN echo "BUOC 6 HOAN TAT: He thong da duoc don dep."

# --- CÀI ĐẶT ỨNG DỤNG PYTHON ---
WORKDIR /app

COPY poetry.lock pyproject.toml ./

RUN poetry install --no-root --no-interaction --no-ansi
RUN echo "Cac dependency cua ung dung da duoc cai dat."

COPY ./app /app/app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]