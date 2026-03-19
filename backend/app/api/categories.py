"""
Category management API endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.database import get_db
from app.models.category import Category
from app.models.schemas import CategoryCreate, CategoryResponse
from app.services.category_service import DEFAULT_CATEGORIES

router = APIRouter()


@router.get("/", response_model=List[CategoryResponse])
async def list_categories(db: AsyncSession = Depends(get_db)):
    """List all spending categories."""
    result = await db.execute(select(Category).order_by(Category.name))
    categories = result.scalars().all()
    
    # If no custom categories, return defaults
    if not categories:
        return [
            CategoryResponse(
                id=i,
                name=cat["name"],
                icon=cat["icon"],
                color=cat["color"],
                keywords=cat["keywords"]
            )
            for i, cat in enumerate(DEFAULT_CATEGORIES, 1)
        ]
    
    return categories


@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    category: CategoryCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a custom spending category."""
    # Check if category already exists
    result = await db.execute(
        select(Category).where(Category.name == category.name)
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category already exists"
        )
    
    db_category = Category(
        name=category.name,
        icon=category.icon,
        color=category.color,
        keywords=category.keywords
    )
    db.add(db_category)
    await db.commit()
    await db.refresh(db_category)
    return db_category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(category_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a custom category."""
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    
    await db.delete(category)
    await db.commit()


@router.get("/defaults")
async def get_default_categories():
    """Get the list of default spending categories."""
    return DEFAULT_CATEGORIES
