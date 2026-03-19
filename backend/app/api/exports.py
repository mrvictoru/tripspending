"""
Export API endpoints for generating reports.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional
import os

from app.database import get_db
from app.models.trip import Trip
from app.models.receipt import Receipt
from app.services.export_service import ExportService

router = APIRouter()
export_service = ExportService()


@router.get("/trip/{trip_id}/excel")
async def export_trip_to_excel(
    trip_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Export trip data to Excel format.
    Returns a downloadable .xlsx file with trip summary and receipt details.
    """
    # Get trip
    trip_result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = trip_result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Get receipts
    receipts_result = await db.execute(
        select(Receipt).where(Receipt.trip_id == trip_id).order_by(Receipt.purchase_date)
    )
    receipts = receipts_result.scalars().all()
    
    # Generate Excel file
    file_path = await export_service.export_trip_to_excel(trip, receipts)
    
    return FileResponse(
        path=file_path,
        filename=f"trip_{trip.name.replace(' ', '_')}_export.xlsx",
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )


@router.get("/trip/{trip_id}/csv")
async def export_trip_to_csv(
    trip_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Export trip data to CSV format.
    Returns a downloadable .csv file with receipt details.
    """
    # Get trip
    trip_result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = trip_result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Get receipts
    receipts_result = await db.execute(
        select(Receipt).where(Receipt.trip_id == trip_id).order_by(Receipt.purchase_date)
    )
    receipts = receipts_result.scalars().all()
    
    # Generate CSV file
    file_path = await export_service.export_trip_to_csv(trip, receipts)
    
    return FileResponse(
        path=file_path,
        filename=f"trip_{trip.name.replace(' ', '_')}_export.csv",
        media_type="text/csv"
    )


@router.get("/trip/{trip_id}/json")
async def export_trip_to_json(
    trip_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Export trip data to JSON format.
    Returns JSON data with full trip details and receipts.
    """
    # Get trip
    trip_result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = trip_result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Get receipts
    receipts_result = await db.execute(
        select(Receipt).where(Receipt.trip_id == trip_id).order_by(Receipt.purchase_date)
    )
    receipts = receipts_result.scalars().all()
    
    return await export_service.export_trip_to_json(trip, receipts)
