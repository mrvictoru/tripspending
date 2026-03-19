"""
Tests for the TripSpending API.
"""

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.database import init_db, engine, Base


@pytest_asyncio.fixture(scope="function")
async def async_client():
    """Create async test client."""
    # Initialize test database
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.mark.asyncio
async def test_root_endpoint(async_client):
    """Test root endpoint."""
    response = await async_client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "TripSpending API"
    assert "version" in data


@pytest.mark.asyncio
async def test_health_check(async_client):
    """Test health check endpoint."""
    response = await async_client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


@pytest.mark.asyncio
async def test_create_trip(async_client):
    """Test creating a trip."""
    trip_data = {
        "name": "Japan Trip 2024",
        "description": "Summer vacation to Japan",
        "start_date": "2024-07-01",
        "end_date": "2024-07-14",
        "budget": 5000,
        "currency": "USD"
    }
    
    response = await async_client.post("/api/trips/", json=trip_data)
    assert response.status_code == 201
    
    data = response.json()
    assert data["name"] == trip_data["name"]
    assert data["budget"] == trip_data["budget"]
    assert "id" in data


@pytest.mark.asyncio
async def test_list_trips(async_client):
    """Test listing trips."""
    # Create a trip first
    trip_data = {"name": "Test Trip", "currency": "EUR"}
    await async_client.post("/api/trips/", json=trip_data)
    
    response = await async_client.get("/api/trips/")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


@pytest.mark.asyncio
async def test_get_trip(async_client):
    """Test getting a specific trip."""
    # Create a trip first
    trip_data = {"name": "Get Test Trip", "currency": "USD"}
    create_response = await async_client.post("/api/trips/", json=trip_data)
    trip_id = create_response.json()["id"]
    
    response = await async_client.get(f"/api/trips/{trip_id}")
    assert response.status_code == 200
    
    data = response.json()
    assert data["name"] == trip_data["name"]
    assert "total_spent" in data


@pytest.mark.asyncio
async def test_update_trip(async_client):
    """Test updating a trip."""
    # Create a trip first
    trip_data = {"name": "Original Name", "currency": "USD"}
    create_response = await async_client.post("/api/trips/", json=trip_data)
    trip_id = create_response.json()["id"]
    
    # Update the trip
    update_data = {"name": "Updated Name", "budget": 1000}
    response = await async_client.put(f"/api/trips/{trip_id}", json=update_data)
    assert response.status_code == 200
    
    data = response.json()
    assert data["name"] == update_data["name"]
    assert data["budget"] == update_data["budget"]


@pytest.mark.asyncio
async def test_delete_trip(async_client):
    """Test deleting a trip."""
    # Create a trip first
    trip_data = {"name": "To Be Deleted", "currency": "USD"}
    create_response = await async_client.post("/api/trips/", json=trip_data)
    trip_id = create_response.json()["id"]
    
    # Delete the trip
    response = await async_client.delete(f"/api/trips/{trip_id}")
    assert response.status_code == 204
    
    # Verify it's deleted
    get_response = await async_client.get(f"/api/trips/{trip_id}")
    assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_create_receipt(async_client):
    """Test creating a receipt."""
    # Create a trip first
    trip_data = {"name": "Receipt Test Trip", "currency": "USD"}
    trip_response = await async_client.post("/api/trips/", json=trip_data)
    trip_id = trip_response.json()["id"]
    
    # Create a receipt
    receipt_data = {
        "trip_id": trip_id,
        "merchant_name": "Test Restaurant",
        "total_amount": 45.50,
        "currency": "USD",
        "category": "Food & Dining"
    }
    
    response = await async_client.post("/api/receipts/", json=receipt_data)
    assert response.status_code == 201
    
    data = response.json()
    assert data["merchant_name"] == receipt_data["merchant_name"]
    assert data["total_amount"] == receipt_data["total_amount"]


@pytest.mark.asyncio
async def test_list_receipts(async_client):
    """Test listing receipts."""
    # Create a trip and receipt
    trip_data = {"name": "List Receipt Trip", "currency": "USD"}
    trip_response = await async_client.post("/api/trips/", json=trip_data)
    trip_id = trip_response.json()["id"]
    
    receipt_data = {
        "trip_id": trip_id,
        "merchant_name": "Test Store",
        "total_amount": 25.00,
        "currency": "USD"
    }
    await async_client.post("/api/receipts/", json=receipt_data)
    
    response = await async_client.get(f"/api/receipts/?trip_id={trip_id}")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


@pytest.mark.asyncio
async def test_trip_summary(async_client):
    """Test getting trip summary."""
    # Create a trip with receipts
    trip_data = {"name": "Summary Trip", "currency": "USD", "budget": 1000}
    trip_response = await async_client.post("/api/trips/", json=trip_data)
    trip_id = trip_response.json()["id"]
    
    # Add receipts
    for i in range(3):
        receipt_data = {
            "trip_id": trip_id,
            "merchant_name": f"Store {i}",
            "total_amount": 100 + i * 50,
            "currency": "USD",
            "category": "Shopping" if i % 2 == 0 else "Food & Dining"
        }
        await async_client.post("/api/receipts/", json=receipt_data)
    
    response = await async_client.get(f"/api/trips/{trip_id}/summary")
    assert response.status_code == 200
    
    data = response.json()
    assert data["trip_id"] == trip_id
    assert "total_spent" in data
    assert "category_breakdown" in data
    assert data["receipt_count"] == 3


@pytest.mark.asyncio
async def test_get_categories(async_client):
    """Test getting categories."""
    response = await async_client.get("/api/categories/")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    
    # Check category structure
    assert "name" in data[0]
    assert "icon" in data[0]


@pytest.mark.asyncio
async def test_get_default_categories(async_client):
    """Test getting default categories."""
    response = await async_client.get("/api/categories/defaults")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)
    
    # Check for expected categories
    category_names = [cat["name"] for cat in data]
    assert "Food & Dining" in category_names
    assert "Transportation" in category_names
