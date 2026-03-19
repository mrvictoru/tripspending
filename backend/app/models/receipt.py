"""
Receipt model for storing receipt and spending information.
"""

from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime

from app.database import Base


class Receipt(Base):
    """Receipt model representing a spending receipt."""
    
    __tablename__ = "receipts"
    
    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=False, index=True)
    
    # Receipt details
    merchant_name = Column(String(255), nullable=True)
    total_amount = Column(Float, nullable=False, default=0)
    currency = Column(String(10), default="USD")
    category = Column(String(100), nullable=True, index=True)
    purchase_date = Column(DateTime, nullable=True)
    
    # Line items (stored as JSON)
    items = Column(JSON, nullable=True)
    
    # OCR data
    raw_text = Column(Text, nullable=True)
    image_path = Column(String(500), nullable=True)
    
    # Location data
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    address = Column(Text, nullable=True)
    
    # Additional info
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    trip = relationship("Trip", back_populates="receipts")
    
    def __repr__(self):
        return f"<Receipt(id={self.id}, merchant='{self.merchant_name}', amount={self.total_amount})>"
