"""
Main FastAPI application entry point.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import trips, receipts, categories, exports
from app.database import init_db

app = FastAPI(
    title="TripSpending API",
    description="API for tracking trip expenses with receipt OCR",
    version="1.0.0"
)

# Configure CORS for local Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(trips.router, prefix="/api/trips", tags=["trips"])
app.include_router(receipts.router, prefix="/api/receipts", tags=["receipts"])
app.include_router(categories.router, prefix="/api/categories", tags=["categories"])
app.include_router(exports.router, prefix="/api/exports", tags=["exports"])


@app.on_event("startup")
async def startup():
    """Initialize database on startup."""
    await init_db()


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "TripSpending API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
