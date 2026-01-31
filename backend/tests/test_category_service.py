"""
Tests for the category service.
"""

import pytest
from app.services.category_service import CategoryService, DEFAULT_CATEGORIES


class TestCategoryService:
    """Tests for CategoryService."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.service = CategoryService()
    
    def test_suggest_category_food(self):
        """Test categorization of food-related merchants."""
        assert self.service.suggest_category(merchant_name="McDonalds") == "Food & Dining"
        assert self.service.suggest_category(merchant_name="Starbucks Coffee") == "Food & Dining"
        assert self.service.suggest_category(merchant_name="Pizza Hut") == "Food & Dining"
    
    def test_suggest_category_transportation(self):
        """Test categorization of transportation."""
        assert self.service.suggest_category(merchant_name="Uber Technologies") == "Transportation"
        assert self.service.suggest_category(merchant_name="City Taxi Service") == "Transportation"
        assert self.service.suggest_category(merchant_name="Airport Parking") == "Transportation"
    
    def test_suggest_category_accommodation(self):
        """Test categorization of accommodation."""
        assert self.service.suggest_category(merchant_name="Hilton Hotel") == "Accommodation"
        assert self.service.suggest_category(merchant_name="Airbnb") == "Accommodation"
    
    def test_suggest_category_shopping(self):
        """Test categorization of shopping."""
        assert self.service.suggest_category(merchant_name="Shopping Mall") == "Shopping"
        assert self.service.suggest_category(merchant_name="Duty Free Store") == "Shopping"
    
    def test_suggest_category_entertainment(self):
        """Test categorization of entertainment."""
        assert self.service.suggest_category(merchant_name="National Museum") == "Entertainment"
        assert self.service.suggest_category(merchant_name="Movie Theater") == "Entertainment"
    
    def test_suggest_category_from_items(self):
        """Test categorization from line items."""
        items = [
            {"name": "Coffee Latte", "amount": 5.50},
            {"name": "Croissant", "amount": 3.00}
        ]
        assert self.service.suggest_category(items=items) == "Food & Dining"
    
    def test_suggest_category_unknown(self):
        """Test categorization of unknown merchants."""
        assert self.service.suggest_category(merchant_name="XYZ123 Services") == "Other"
    
    def test_suggest_category_empty(self):
        """Test categorization with no input."""
        assert self.service.suggest_category() == "Other"
    
    def test_get_category_info(self):
        """Test getting category info."""
        info = self.service.get_category_info("Food & Dining")
        assert info is not None
        assert info["name"] == "Food & Dining"
        assert "icon" in info
        assert "color" in info
    
    def test_get_category_info_not_found(self):
        """Test getting info for non-existent category."""
        info = self.service.get_category_info("Non Existent Category")
        assert info is None
    
    def test_get_all_categories(self):
        """Test getting all categories."""
        categories = self.service.get_all_categories()
        assert len(categories) == len(DEFAULT_CATEGORIES)
    
    def test_multilingual_keywords(self):
        """Test that multilingual keywords work."""
        # Chinese restaurant
        assert self.service.suggest_category(merchant_name="餐厅") == "Food & Dining"
        # Japanese convenience store
        assert self.service.suggest_category(merchant_name="コンビニ") == "Groceries"
