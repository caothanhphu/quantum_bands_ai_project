# File: app/core/config.py

import logging
import os
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from urllib.parse import quote_plus # For URL encoding the driver string

class Settings(BaseSettings):
    """
    Application settings are loaded from environment variables.
    Pydantic's BaseSettings provides validation and type hints.
    """
    PROJECT_NAME: str = "Quantum Bands AI Investment Fund Management System"
    PROJECT_VERSION: str = "0.1.0-mvp"
    LOG_LEVEL: str = "INFO"

    # MSSQL Database Configuration
    DB_SERVER: str
    DB_PORT: str = "1433"
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str
    DB_DRIVER: str = "{ODBC Driver 17 for SQL Server}" # Default driver, can be overridden

    # SQLAlchemy Database URL, constructed if not provided directly
    DATABASE_URL: str | None = None

    # Pydantic settings configuration
    model_config = SettingsConfigDict(
        env_file=".env",        # Load environment variables from .env file
        extra="ignore"          # Ignore extra fields not defined in this model
    )

    def get_mssql_url(self) -> str:
        """
        Constructs the MSSQL connection string for SQLAlchemy.
        Ensures the driver string is URL-encoded.
        Handles optional port for named instances and encodes user/password.
        """
        if self.DATABASE_URL: # Nếu DATABASE_URL được cung cấp trực tiếp, dùng nó
            return self.DATABASE_URL

        driver_encoded = quote_plus(self.DB_DRIVER)
        
        server_spec = self.DB_SERVER # Giá trị từ .env, có thể là 'hostname' hoặc 'hostname\SQLEXPRESS'
        if self.DB_PORT and self.DB_PORT.strip(): # Nếu DB_PORT được cung cấp và không rỗng
            server_spec = f"{self.DB_SERVER}:{self.DB_PORT.strip()}"
            
        user_encoded = quote_plus(self.DB_USER)
        password_encoded = quote_plus(self.DB_PASSWORD)

        # Chuỗi kết nối cơ bản
        # Ví dụ: "mssql+pyodbc://user:password@server_or_server_instance/dbname?driver=EncodedDriverName"
        # Thêm Encrypt=no;TrustServerCertificate=yes có thể cần thiết cho một số môi trường local/test
        # hoặc khi không có SSL certificate hợp lệ. Cân nhắc kỹ về bảo mật khi dùng các tùy chọn này.
        # Đối với production, nên dùng Encrypt=yes và có certificate hợp lệ.
        connection_string = f"mssql+pyodbc://{user_encoded}:{password_encoded}@{server_spec}/{self.DB_NAME}?driver={driver_encoded}"

        # Các tham số kết nối bổ sung (tùy chọn)
        # connection_params = {
        #     "Encrypt": "no", # Hoặc "yes" nếu server yêu cầu và client hỗ trợ
        #     # "TrustServerCertificate": "yes", # Chỉ dùng nếu bạn hiểu rõ về rủi ro bảo mật
        #     # "timeout": "30", # Thời gian chờ kết nối (giây)
        # }
        # query_params = "&".join(f"{k}={v}" for k, v in connection_params.items())
        # if query_params:
        #     connection_string += f"&{query_params}"
        
        # Giữ nguyên Encrypt=no từ phiên bản trước nếu đó là yêu cầu ban đầu
        # Nếu không chắc, có thể bỏ đi và để driver tự quyết định hoặc cấu hình rõ ràng hơn
        connection_string += "&Encrypt=no"


        return connection_string

@lru_cache() # Cache the settings object to avoid reloading .env multiple times
def get_settings() -> Settings:
    """
    Returns the cached Settings instance.
    """
    return Settings()

# Initialize settings
settings = get_settings()

# --- Basic Logging Configuration ---
# Get numeric log level from string
numeric_log_level = getattr(logging, settings.LOG_LEVEL.upper(), None)
if not isinstance(numeric_log_level, int):
    # Fallback to INFO if LOG_LEVEL is invalid
    logging.warning(f"Invalid log level: {settings.LOG_LEVEL}. Defaulting to INFO.")
    numeric_log_level = logging.INFO

logging.basicConfig(
    level=numeric_log_level,
    format="%(asctime)s - %(levelname)s - %(name)s - %(module)s.%(funcName)s:L%(lineno)d - %(message)s",
    handlers=[
        logging.StreamHandler()  # Log to console
        # Example: Add a file handler if needed
        # logging.FileHandler("app.log", mode='a')
    ]
)

# Get a logger instance for this module
module_logger = logging.getLogger(__name__)
module_logger.info("Logging configured successfully.")
module_logger.info(f"Project: {settings.PROJECT_NAME}, Version: {settings.PROJECT_VERSION}, Log Level: {settings.LOG_LEVEL}")

# Example of accessing a setting
module_logger.debug(f"Database server configured: {settings.DB_SERVER}")