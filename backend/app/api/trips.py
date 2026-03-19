"""
Trip management API endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List, Optional
from datetime import datetime

from app.database import get_db
from app.models.trip import Trip
from app.models.receipt import Receipt
from app.models.schemas import (
    TripCreate, TripUpdate, TripResponse, TripWithStats
)

router = APIRouter()


@router.post("/", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
async def create_trip(trip: TripCreate, db: AsyncSession = Depends(get_db)):
    """Create a new trip."""
    db_trip = Trip(
        name=trip.name,
        description=trip.description,
        start_date=trip.start_date,
        end_date=trip.end_date,
        budget=trip.budget,
        currency=trip.currency
    )
    db.add(db_trip)
    await db.commit()
    await db.refresh(db_trip)
    return db_trip


@router.get("/", response_model=List[TripResponse])
async def list_trips(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """List all trips with pagination."""
    result = await db.execute(
        select(Trip).order_by(Trip.created_at.desc()).offset(skip).limit(limit)
    )
    return result.scalars().all()


@router.get("/{trip_id}", response_model=TripWithStats)
async def get_trip(trip_id: int, db: AsyncSession = Depends(get_db)):
    """Get a specific trip with spending statistics."""
    result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Calculate statistics
    stats_result = await db.execute(
        select(
            func.count(Receipt.id).label("receipt_count"),
            func.coalesce(func.sum(Receipt.total_amount), 0).label("total_spent")
        ).where(Receipt.trip_id == trip_id)
    )
    stats = stats_result.one()
    
    return TripWithStats(
        id=trip.id,
        name=trip.name,
        description=trip.description,
        start_date=trip.start_date,
        end_date=trip.end_date,
        budget=trip.budget,
        currency=trip.currency,
        created_at=trip.created_at,
        updated_at=trip.updated_at,
        receipt_count=stats.receipt_count,
        total_spent=float(stats.total_spent)
    )


@router.put("/{trip_id}", response_model=TripResponse)
async def update_trip(
    trip_id: int,
    trip_update: TripUpdate,
    db: AsyncSession = Depends(get_db)
):
    """Update a trip."""
    result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    update_data = trip_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(trip, field, value)
    
    trip.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(trip)
    return trip


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(trip_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a trip and all associated receipts."""
    result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    await db.delete(trip)
    await db.commit()


@router.get("/{trip_id}/summary")
async def get_trip_summary(trip_id: int, db: AsyncSession = Depends(get_db)):
    """Get detailed spending summary for a trip."""
    result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Get all receipts for the trip
    receipts_result = await db.execute(
        select(Receipt).where(Receipt.trip_id == trip_id)
    )
    receipts = receipts_result.scalars().all()
    
    # Calculate statistics
    total_spent = sum(r.total_amount for r in receipts)
    
    # Group by category
    category_spending = {}
    for receipt in receipts:
        cat = receipt.category or "Uncategorized"
        category_spending[cat] = category_spending.get(cat, 0) + receipt.total_amount
    
    # Group by date
    daily_spending = {}
    for receipt in receipts:
        if receipt.purchase_date:
            date_key = receipt.purchase_date.strftime("%Y-%m-%d")
            daily_spending[date_key] = daily_spending.get(date_key, 0) + receipt.total_amount
    
    return {
        "trip_id": trip_id,
        "trip_name": trip.name,
        "currency": trip.currency,
        "budget": trip.budget,
        "total_spent": total_spent,
        "remaining_budget": (trip.budget or 0) - total_spent,
        "receipt_count": len(receipts),
        "category_breakdown": category_spending,
        "daily_spending": daily_spending,
        "locations": [
            {
                "name": r.merchant_name,
                "latitude": r.latitude,
                "longitude": r.longitude,
                "amount": r.total_amount
            }
            for r in receipts if r.latitude and r.longitude
        ]
    }
