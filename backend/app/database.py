"""
Database connection for the standalone Chanda PPE backend.

IMPORTANT: this points at its OWN database (e.g. chanda_ppe), created by
running ppe_module_schema_v2.0.sql. It never connects to chanda_store.
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = os.getenv(
    "PPE_DATABASE_URL",
    "postgresql://ppe_user:ppe_password@localhost:5432/chanda_ppe",
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
