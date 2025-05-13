# File: app/core/db.py

import logging
from sqlalchemy import create_engine, text as sql_text
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import SQLAlchemyError

from .config import settings # Import settings from the config module

# Get a logger instance for this module
logger = logging.getLogger(__name__)

SQLALCHEMY_DATABASE_URL = settings.get_mssql_url()

logger.info(f"Attempting to connect to database. URL (password hidden): "
            f"{SQLALCHEMY_DATABASE_URL.replace(settings.DB_PASSWORD, '********') if settings.DB_PASSWORD else SQLALCHEMY_DATABASE_URL}")

try:
    # Create SQLAlchemy engine
    # echo=True will log all SQL statements - useful for debugging, controlled by LOG_LEVEL in production
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        pool_pre_ping=True,  # Checks connection health before use
        echo=(settings.LOG_LEVEL.upper() == "DEBUG") # Log SQL queries if log level is DEBUG
    )

    # Create a session factory
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    # Base class for declarative class definitions (ORM models)
    Base = declarative_base()

    logger.info("SQLAlchemy engine and SessionLocal configured.")

    # Optional: Test the connection on setup
    # This can be moved to a startup event in main.py if preferred
    # try:
    #     with engine.connect() as connection:
    #         connection.execute(sql_text("SELECT 1")) # Simple query to test connection
    #         logger.info("Successfully connected to the database and executed a test query.")
    # except SQLAlchemyError as e:
    #     logger.error(f"Database connection test failed: {e}")
    #     # Depending on the application's needs, you might want to raise an exception here
    #     # or handle it to allow the app to start even if DB is temporarily down.
    #     # For MVP, logging the error might be sufficient initially.
    # except Exception as e: # Catch any other unexpected error during connection test
    #     logger.error(f"An unexpected error occurred during database connection test: {e}")


except Exception as e:
    logger.error(f"Fatal error configuring database: {e}", exc_info=True)
    # If DB connection is critical for startup, it might be best to exit.
    # For now, we'll log the error and the application might fail later if DB is needed.
    # raise SystemExit(f"Could not establish database connection: {e}")


def get_db_session():
    """
    Dependency to get a database session.
    Ensures the session is closed after the request.
    """
    db = None
    try:
        db = SessionLocal()
        yield db
    finally:
        if db:
            db.close()