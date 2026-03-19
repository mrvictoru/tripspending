"""
Receipt management API endpoints with OCR processing.
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
from datetime import datetime
import os
import uuid

from app.database import get_db
from app.models.receipt import Receipt
from app.models.trip import Trip
from app.models.schemas import ReceiptCreate, ReceiptUpdate, ReceiptResponse
from app.services.ocr_service import OCRService
from app.services.category_service import CategoryService

router = APIRouter()
ocr_service = OCRService()
category_service = CategoryService()

# Directory for storing receipt images
UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "./uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("/scan", response_model=dict)
async def scan_receipt(
    image: UploadFile = File(...),
    languages: str = Form(default="en,zh,ja,ko,es,fr,de")
):
    """
    Scan a receipt image and extract information using OCR.
    Supports multiple languages for multilingual receipt recognition.
    """
    # Save uploaded image temporarily
    file_extension = os.path.splitext(image.filename)[1] or ".jpg"
    temp_filename = f"temp_{uuid.uuid4()}{file_extension}"
    temp_path = os.path.join(UPLOAD_DIR, temp_filename)
    
    try:
        # Save the uploaded file
        contents = await image.read()
        with open(temp_path, "wb") as f:
            f.write(contents)
        
        # Process with OCR
        language_list = [lang.strip() for lang in languages.split(",")]
        ocr_result = await ocr_service.process_receipt(temp_path, language_list)
        
        # Suggest category based on OCR results
        suggested_category = category_service.suggest_category(
            merchant_name=ocr_result.get("merchant_name", ""),
            items=ocr_result.get("items", [])
        )
        ocr_result["suggested_category"] = suggested_category
        
        return ocr_result
    finally:
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)


@router.post("/", response_model=ReceiptResponse, status_code=status.HTTP_201_CREATED)
async def create_receipt(
    receipt: ReceiptCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new receipt entry."""
    # Verify trip exists
    trip_result = await db.execute(select(Trip).where(Trip.id == receipt.trip_id))
    if not trip_result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    db_receipt = Receipt(
        trip_id=receipt.trip_id,
        merchant_name=receipt.merchant_name,
        total_amount=receipt.total_amount,
        currency=receipt.currency,
        category=receipt.category,
        purchase_date=receipt.purchase_date,
        items=receipt.items,
        raw_text=receipt.raw_text,
        image_path=receipt.image_path,
        latitude=receipt.latitude,
        longitude=receipt.longitude,
        address=receipt.address,
        notes=receipt.notes
    )
    db.add(db_receipt)
    await db.commit()
    await db.refresh(db_receipt)
    return db_receipt


@router.post("/with-image", response_model=ReceiptResponse, status_code=status.HTTP_201_CREATED)
async def create_receipt_with_image(
    trip_id: int = Form(...),
    image: UploadFile = File(...),
    languages: str = Form(default="en,zh,ja,ko,es,fr,de"),
    latitude: Optional[float] = Form(default=None),
    longitude: Optional[float] = Form(default=None),
    address: Optional[str] = Form(default=None),
    notes: Optional[str] = Form(default=None),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload a receipt image, process with OCR, and create a receipt entry.
    This is the main endpoint for adding receipts via the mobile app.
    """
    # Verify trip exists
    trip_result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = trip_result.scalar_one_or_none()
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Save the image permanently
    file_extension = os.path.splitext(image.filename)[1] or ".jpg"
    filename = f"receipt_{trip_id}_{uuid.uuid4()}{file_extension}"
    image_path = os.path.join(UPLOAD_DIR, filename)
    
    contents = await image.read()
    with open(image_path, "wb") as f:
        f.write(contents)
    
    # Process with OCR
    language_list = [lang.strip() for lang in languages.split(",")]
    ocr_result = await ocr_service.process_receipt(image_path, language_list)
    
    # Suggest category
    suggested_category = category_service.suggest_category(
        merchant_name=ocr_result.get("merchant_name", ""),
        items=ocr_result.get("items", [])
    )
    
    # Create receipt entry
    db_receipt = Receipt(
        trip_id=trip_id,
        merchant_name=ocr_result.get("merchant_name"),
        total_amount=ocr_result.get("total_amount", 0),
        currency=ocr_result.get("currency") or trip.currency,
        category=suggested_category,
        purchase_date=ocr_result.get("date") or datetime.utcnow(),
        items=ocr_result.get("items"),
        raw_text=ocr_result.get("raw_text"),
        image_path=image_path,
        latitude=latitude,
        longitude=longitude,
        address=address,
        notes=notes
    )
    db.add(db_receipt)
    await db.commit()
    await db.refresh(db_receipt)
    return db_receipt


@router.get("/", response_model=List[ReceiptResponse])
async def list_receipts(
    trip_id: Optional[int] = None,
    category: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """List receipts with optional filtering."""
    query = select(Receipt)
    
    if trip_id:
        query = query.where(Receipt.trip_id == trip_id)
    if category:
        query = query.where(Receipt.category == category)
    
    query = query.order_by(Receipt.purchase_date.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{receipt_id}", response_model=ReceiptResponse)
async def get_receipt(receipt_id: int, db: AsyncSession = Depends(get_db)):
    """Get a specific receipt."""
    result = await db.execute(select(Receipt).where(Receipt.id == receipt_id))
    receipt = result.scalar_one_or_none()
    
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )
    return receipt


@router.put("/{receipt_id}", response_model=ReceiptResponse)
async def update_receipt(
    receipt_id: int,
    receipt_update: ReceiptUpdate,
    db: AsyncSession = Depends(get_db)
):
    """Update a receipt."""
    result = await db.execute(select(Receipt).where(Receipt.id == receipt_id))
    receipt = result.scalar_one_or_none()
    
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )
    
    update_data = receipt_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(receipt, field, value)
    
    receipt.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(receipt)
    return receipt


@router.delete("/{receipt_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_receipt(receipt_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a receipt."""
    result = await db.execute(select(Receipt).where(Receipt.id == receipt_id))
    receipt = result.scalar_one_or_none()
    
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )
    
    # Delete the image file if it exists
    if receipt.image_path and os.path.exists(receipt.image_path):
        os.remove(receipt.image_path)
    
    await db.delete(receipt)
    await db.commit()
