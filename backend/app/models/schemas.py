"""
Pydantic schemas for API request/response validation.
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import date, datetime


# Trip schemas
class TripCreate(BaseModel):
    """Schema for creating a trip."""
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    budget: Optional[float] = Field(None, ge=0)
    currency: str = Field(default="USD", max_length=10)


class TripUpdate(BaseModel):
    """Schema for updating a trip."""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    budget: Optional[float] = Field(None, ge=0)
    currency: Optional[str] = Field(None, max_length=10)


class TripResponse(BaseModel):
    """Schema for trip response."""
    id: int
    name: str
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    budget: Optional[float] = None
    currency: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class TripWithStats(TripResponse):
    """Schema for trip response with statistics."""
    receipt_count: int = 0
    total_spent: float = 0


# Receipt schemas
class ReceiptCreate(BaseModel):
    """Schema for creating a receipt."""
    trip_id: int
    merchant_name: Optional[str] = None
    total_amount: float = Field(..., ge=0)
    currency: str = Field(default="USD", max_length=10)
    category: Optional[str] = None
    purchase_date: Optional[datetime] = None
    items: Optional[List[dict]] = None
    raw_text: Optional[str] = None
    image_path: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    notes: Optional[str] = None


class ReceiptUpdate(BaseModel):
    """Schema for updating a receipt."""
    merchant_name: Optional[str] = None
    total_amount: Optional[float] = Field(None, ge=0)
    currency: Optional[str] = Field(None, max_length=10)
    category: Optional[str] = None
    purchase_date: Optional[datetime] = None
    items: Optional[List[dict]] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    notes: Optional[str] = None


class ReceiptResponse(BaseModel):
    """Schema for receipt response."""
    id: int
    trip_id: int
    merchant_name: Optional[str] = None
    total_amount: float
    currency: str
    category: Optional[str] = None
    purchase_date: Optional[datetime] = None
    items: Optional[List[dict]] = None
    raw_text: Optional[str] = None
    image_path: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Category schemas
class CategoryCreate(BaseModel):
    """Schema for creating a category."""
    name: str = Field(..., min_length=1, max_length=100)
    icon: Optional[str] = None
    color: Optional[str] = None
    keywords: Optional[List[str]] = None


class CategoryResponse(BaseModel):
    """Schema for category response."""
    id: int
    name: str
    icon: Optional[str] = None
    color: Optional[str] = None
    keywords: Optional[List[str]] = None
    
    class Config:
        from_attributes = True


# OCR Result schema
class OCRResult(BaseModel):
    """Schema for OCR processing result."""
    raw_text: str
    merchant_name: Optional[str] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = None
    date: Optional[datetime] = None
    items: Optional[List[dict]] = None
    suggested_category: Optional[str] = None
    confidence: float = 0.0
