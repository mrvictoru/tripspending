"""
Category model for spending categorization.
"""

from sqlalchemy import Column, Integer, String, JSON
from datetime import datetime

from app.database import Base


class Category(Base):
    """Category model for organizing spending."""
    
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    icon = Column(String(50), nullable=True)
    color = Column(String(20), nullable=True)
    keywords = Column(JSON, nullable=True)  # Keywords for auto-categorization
    
    def __repr__(self):
        return f"<Category(id={self.id}, name='{self.name}')>"
