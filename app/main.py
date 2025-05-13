# File: app/main.py

import logging
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text as sql_text # For executing raw SQL if needed

# Initialize settings and logging first by importing from core.config
# This ensures logging is set up before other modules try to use it.
from .core.config import settings, module_logger as config_module_logger
# Import db module to ensure engine and SessionLocal are initialized
from .core import db

# Logger for the main application file
main_app_logger = logging.getLogger(__name__)

# In a real application, your ORM models would be defined in app/models/
# and then Base.metadata.create_all(bind=db.engine) would create them.
# Example:
# from .models.user_model import User # Assuming you have a User model
# db.Base.metadata.create_all(bind=db.engine)
# For this initial setup, we don't have models yet.

# Create FastAPI app instance
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
    description="API Backend for Quantum Bands AI Investment Fund Management System"
    # Add other OpenAPI metadata as needed: docs_url, redoc_url, openapi_tags, etc.
)

@app.on_event("startup")
async def on_startup():
    """
    Actions to perform when the application starts.
    """
    main_app_logger.info(f"Application '{settings.PROJECT_NAME}' version {settings.PROJECT_VERSION} starting up...")
    # Test database connection on startup
    try:
        with db.engine.connect() as connection:
            result = connection.execute(sql_text("SELECT 1 AS connection_test"))
            row = result.fetchone()
            if row and row.connection_test == 1:
                 main_app_logger.info("Database connection successful on startup.")
            else:
                main_app_logger.warning("Database connection test query did not return expected result.")
    except Exception as e:
        main_app_logger.error(f"Failed to connect to the database on startup: {e}", exc_info=True)
        # Depending on policy, might raise to prevent startup or just log
        # For MVP, logging is often sufficient, but for production, you might want to halt.

@app.on_event("shutdown")
async def on_shutdown():
    """
    Actions to perform when the application shuts down.
    """
    main_app_logger.info(f"Application '{settings.PROJECT_NAME}' shutting down.")

@app.get("/", tags=["Root"])
async def read_root():
    """
    Root endpoint to check if the API is running.
    """
    main_app_logger.info("Root endpoint '/' was accessed.")
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "version": settings.PROJECT_VERSION
    }

@app.get("/health/db", tags=["Health Check"])
async def health_check_db(session: Session = Depends(db.get_db_session)):
    """
    Checks database connectivity by executing a simple query.
    """
    main_app_logger.debug("Attempting database health check...")
    try:
        # Perform a simple query to check if the database is responsive
        session.execute(sql_text("SELECT 1"))
        main_app_logger.info("Database health check successful.")
        return {"status": "healthy", "database_connection": "ok"}
    except Exception as e:
        main_app_logger.error(f"Database health check failed: {e}", exc_info=True)
        # Return a 503 Service Unavailable error if DB connection fails
        raise HTTPException(
            status_code=503,
            detail=f"Database connection error: {str(e)}"
        )

# Example usage of the config logger to show it works
config_module_logger.info("This log message comes from the logger instance created in config.py.")

# (Tương lai) Include routers from other modules here
# from .apis import some_router
# app.include_router(some_router.router, prefix="/some_path", tags=["Some Tag"])

main_app_logger.info(f"FastAPI application '{settings.PROJECT_NAME}' initialized and ready.")