"""
Trip model for storing trip information.
"""

from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Text
from sqlalchemy.orm import relationship
from datetime import datetime

from app.database import Base


class Trip(Base):
    """Trip model representing a travel trip."""
    
    __tablename__ = "trips"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    budget = Column(Float, nullable=True)
    currency = Column(String(10), default="USD")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    receipts = relationship(
        "Receipt",
        back_populates="trip",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<Trip(id={self.id}, name='{self.name}')>"
