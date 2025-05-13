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

# Cài đặt các gói hệ thống cần thiết và Poetry
# curl dùng để tải script cài đặt Poetry
# unixodbc-dev cần cho pyodbc (nếu kết nối MSSQL từ container Linux)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    apt-transport-https \
    unixodbc-dev \
    && curl -sSL https://install.python-poetry.org | python3 - \
    # Cài đặt Microsoft ODBC Driver cho SQL Server (cho container Linux)
    # Script này dành cho Debian (base image python:*-slim thường là Debian)
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/$(cat /etc/debian_version | cut -d'.' -f1)/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 \
    # Dọn dẹp để giảm kích thước image
    && apt-get remove --purge -y curl gnupg apt-transport-https \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Kiểm tra phiên bản Poetry (tùy chọn)
# RUN poetry --version

# Đặt thư mục làm việc trong container
WORKDIR /app

# Sao chép file cấu hình của Poetry
# Quan trọng: Sao chép những file này trước để tận dụng Docker layer caching.
# Nếu chỉ code thay đổi mà dependencies không đổi, Docker sẽ không cần cài lại dependencies.
COPY poetry.lock pyproject.toml ./

# Cài đặt dependencies của dự án bằng Poetry
# --no-dev: không cài các dependency chỉ dành cho môi trường phát triển
# --no-interaction: không yêu cầu tương tác người dùng
# --no-ansi: không dùng màu mè ANSI trong output
RUN poetry install --no-dev --no-interaction --no-ansi

# Sao chép toàn bộ code của ứng dụng (thư mục app và các file khác nếu có)
COPY ./app /app/app
# Ví dụ nếu bạn có file .env.example muốn đưa vào image:
# COPY .env.example /app/.env.example

# Expose port mà ứng dụng FastAPI sẽ chạy
EXPOSE 8000

# Lệnh để chạy ứng dụng khi container khởi động
# Lệnh này giả định uvicorn là một dependency trong pyproject.toml
# và có thể được chạy trực tiếp.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]