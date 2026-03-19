"""
Category Service for automatic spending categorization.
"""

from typing import List, Optional

# Default spending categories with keywords for auto-categorization
DEFAULT_CATEGORIES = [
    {
        "name": "Food & Dining",
        "icon": "restaurant",
        "color": "#FF6B6B",
        "keywords": [
            "restaurant", "cafe", "coffee", "food", "dining", "eat", "meal",
            "breakfast", "lunch", "dinner", "pizza", "burger", "sushi",
            "mcdonalds", "starbucks", "subway", "kfc", "bakery", "bistro",
            "餐厅", "咖啡", "食品", "レストラン", "カフェ", "음식점"
        ]
    },
    {
        "name": "Transportation",
        "icon": "directions_car",
        "color": "#4ECDC4",
        "keywords": [
            "uber", "lyft", "taxi", "cab", "transit", "metro", "bus",
            "train", "subway", "airline", "flight", "airport", "parking",
            "gas", "fuel", "petrol", "rental car", "grab", "gojek",
            "交通", "出租车", "地铁", "タクシー", "電車", "교통"
        ]
    },
    {
        "name": "Accommodation",
        "icon": "hotel",
        "color": "#45B7D1",
        "keywords": [
            "hotel", "hostel", "airbnb", "motel", "inn", "resort",
            "lodging", "accommodation", "booking", "stay", "room",
            "酒店", "住宿", "ホテル", "宿泊", "호텔", "숙박"
        ]
    },
    {
        "name": "Shopping",
        "icon": "shopping_bag",
        "color": "#96CEB4",
        "keywords": [
            "shop", "store", "mall", "market", "retail", "amazon",
            "walmart", "target", "clothing", "fashion", "apparel",
            "souvenirs", "gifts", "duty free", "outlet",
            "购物", "商店", "ショッピング", "쇼핑"
        ]
    },
    {
        "name": "Entertainment",
        "icon": "local_activity",
        "color": "#DDA0DD",
        "keywords": [
            "museum", "theater", "theatre", "cinema", "movie", "concert",
            "show", "attraction", "tour", "ticket", "park", "zoo",
            "aquarium", "entertainment", "activity", "experience",
            "娱乐", "博物馆", "エンターテイメント", "엔터테인먼트"
        ]
    },
    {
        "name": "Groceries",
        "icon": "local_grocery_store",
        "color": "#77DD77",
        "keywords": [
            "grocery", "supermarket", "market", "convenience", "7-eleven",
            "minimart", "family mart", "lawson", "whole foods", "trader joe",
            "超市", "便利店", "スーパー", "コンビニ", "마트"
        ]
    },
    {
        "name": "Health & Pharmacy",
        "icon": "local_pharmacy",
        "color": "#FF6961",
        "keywords": [
            "pharmacy", "drugstore", "medicine", "health", "hospital",
            "clinic", "doctor", "medical", "cvs", "walgreens",
            "药店", "医院", "薬局", "病院", "약국"
        ]
    },
    {
        "name": "Communication",
        "icon": "phone",
        "color": "#84B6F4",
        "keywords": [
            "sim", "phone", "mobile", "data", "internet", "wifi",
            "telecom", "carrier", "通信", "電話", "통신"
        ]
    },
    {
        "name": "Other",
        "icon": "more_horiz",
        "color": "#C0C0C0",
        "keywords": []
    }
]


class CategoryService:
    """Service for categorizing spending based on receipt content."""
    
    def __init__(self, custom_categories: List[dict] = None):
        """Initialize category service with optional custom categories."""
        self.categories = custom_categories or DEFAULT_CATEGORIES
    
    def suggest_category(
        self,
        merchant_name: str = None,
        items: List[dict] = None,
        raw_text: str = None
    ) -> str:
        """
        Suggest a category based on receipt information.
        
        Args:
            merchant_name: Name of the merchant
            items: List of line items
            raw_text: Raw OCR text
        
        Returns:
            Suggested category name
        """
        # Combine all text for matching
        search_text = ""
        
        if merchant_name:
            search_text += merchant_name.lower() + " "
        
        if items:
            for item in items:
                if isinstance(item, dict) and "name" in item:
                    search_text += item["name"].lower() + " "
        
        if raw_text:
            search_text += raw_text.lower()
        
        if not search_text.strip():
            return "Other"
        
        # Score each category based on keyword matches
        category_scores = {}
        
        for category in self.categories:
            score = 0
            keywords = category.get("keywords", [])
            
            for keyword in keywords:
                keyword_lower = keyword.lower()
                if keyword_lower in search_text:
                    # Longer keyword matches get higher scores
                    score += len(keyword_lower)
            
            if score > 0:
                category_scores[category["name"]] = score
        
        # Return category with highest score
        if category_scores:
            return max(category_scores, key=category_scores.get)
        
        return "Other"
    
    def get_category_info(self, category_name: str) -> Optional[dict]:
        """Get category information by name."""
        for category in self.categories:
            if category["name"].lower() == category_name.lower():
                return category
        return None
    
    def get_all_categories(self) -> List[dict]:
        """Get all available categories."""
        return self.categories
