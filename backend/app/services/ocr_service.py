"""
OCR Service for processing receipt images.
Supports multiple languages and uses EasyOCR for text extraction.
"""

import re
from typing import List, Dict, Any, Optional
from datetime import datetime
import asyncio
from concurrent.futures import ThreadPoolExecutor

# Try to import EasyOCR, fallback to basic processing if not available
try:
    import easyocr
    EASYOCR_AVAILABLE = True
except ImportError:
    EASYOCR_AVAILABLE = False


class OCRService:
    """Service for OCR processing of receipt images."""
    
    # Language mapping for EasyOCR
    LANGUAGE_MAP = {
        "en": "en",
        "zh": "ch_sim",
        "zh-tw": "ch_tra",
        "ja": "ja",
        "ko": "ko",
        "es": "es",
        "fr": "fr",
        "de": "de",
        "it": "it",
        "pt": "pt",
        "ru": "ru",
        "ar": "ar",
        "th": "th",
        "vi": "vi",
    }
    
    # Common currency symbols and codes
    CURRENCY_PATTERNS = {
        "$": ["USD", "AUD", "CAD", "SGD", "HKD"],
        "€": ["EUR"],
        "£": ["GBP"],
        "¥": ["JPY", "CNY"],
        "₩": ["KRW"],
        "₹": ["INR"],
        "฿": ["THB"],
        "₫": ["VND"],
    }
    
    def __init__(self):
        """Initialize OCR service."""
        self.reader = None
        self.executor = ThreadPoolExecutor(max_workers=2)
    
    def _get_reader(self, languages: List[str]) -> Any:
        """Get or create EasyOCR reader with specified languages."""
        if not EASYOCR_AVAILABLE:
            return None
        
        # Map language codes to EasyOCR format
        ocr_langs = []
        for lang in languages:
            if lang in self.LANGUAGE_MAP:
                ocr_langs.append(self.LANGUAGE_MAP[lang])
            elif lang in self.LANGUAGE_MAP.values():
                ocr_langs.append(lang)
        
        if not ocr_langs:
            ocr_langs = ["en"]
        
        return easyocr.Reader(ocr_langs, gpu=False)
    
    async def process_receipt(
        self,
        image_path: str,
        languages: List[str] = None
    ) -> Dict[str, Any]:
        """
        Process a receipt image and extract relevant information.
        
        Args:
            image_path: Path to the receipt image
            languages: List of language codes for OCR
        
        Returns:
            Dictionary containing extracted receipt information
        """
        if languages is None:
            languages = ["en"]
        
        # Run OCR in thread pool to avoid blocking
        loop = asyncio.get_event_loop()
        raw_text = await loop.run_in_executor(
            self.executor,
            self._perform_ocr,
            image_path,
            languages
        )
        
        # Parse the extracted text
        result = self._parse_receipt_text(raw_text)
        result["raw_text"] = raw_text
        
        return result
    
    def _perform_ocr(self, image_path: str, languages: List[str]) -> str:
        """Perform OCR on image (runs in thread pool)."""
        if not EASYOCR_AVAILABLE:
            # Return placeholder if EasyOCR not installed
            return "[OCR not available - EasyOCR not installed]"
        
        try:
            reader = self._get_reader(languages)
            results = reader.readtext(image_path)
            
            # Combine all text results
            text_lines = []
            for detection in results:
                text = detection[1]
                confidence = detection[2]
                if confidence > 0.3:  # Filter low confidence results
                    text_lines.append(text)
            
            return "\n".join(text_lines)
        except Exception as e:
            return f"[OCR Error: {str(e)}]"
    
    def _parse_receipt_text(self, text: str) -> Dict[str, Any]:
        """Parse OCR text to extract structured data."""
        result = {
            "merchant_name": None,
            "total_amount": None,
            "currency": None,
            "date": None,
            "items": [],
            "confidence": 0.0
        }
        
        if not text or text.startswith("["):
            return result
        
        lines = text.split("\n")
        
        # Extract merchant name (usually first non-empty line)
        for line in lines[:5]:
            cleaned = line.strip()
            if cleaned and len(cleaned) > 2 and not self._is_date_line(cleaned):
                result["merchant_name"] = cleaned
                break
        
        # Extract total amount
        total_amount, currency = self._extract_total_amount(text)
        result["total_amount"] = total_amount
        result["currency"] = currency
        
        # Extract date
        result["date"] = self._extract_date(text)
        
        # Extract line items
        result["items"] = self._extract_items(lines)
        
        # Calculate confidence based on extracted data
        confidence = 0.0
        if result["merchant_name"]:
            confidence += 0.25
        if result["total_amount"]:
            confidence += 0.35
        if result["date"]:
            confidence += 0.2
        if result["items"]:
            confidence += 0.2
        result["confidence"] = confidence
        
        return result
    
    def _extract_total_amount(self, text: str) -> tuple:
        """Extract total amount and currency from text."""
        # Common total patterns
        total_patterns = [
            r"(?:total|grand total|amount due|balance due|sum|合計|合计|総額|总额)\s*[:\s]*([€$£¥₩₹฿₫]?)\s*([\d,]+\.?\d*)",
            r"(?:total|subtotal)\s*[:\s]*([€$£¥₩₹฿₫]?)\s*([\d,]+\.?\d*)",
            r"([€$£¥₩₹฿₫])\s*([\d,]+\.?\d*)\s*(?:total)?",
            r"([\d,]+\.?\d*)\s*([€$£¥₩₹฿₫])",
        ]
        
        text_lower = text.lower()
        
        for pattern in total_patterns:
            matches = re.findall(pattern, text_lower, re.IGNORECASE)
            if matches:
                for match in matches:
                    try:
                        # Handle different match formats
                        if len(match) >= 2:
                            symbol = match[0].strip() if match[0] else ""
                            amount_str = match[1].strip() if match[1] else match[0].strip()
                            
                            # Clean amount string
                            amount_str = re.sub(r"[^\d.,]", "", amount_str)
                            amount_str = amount_str.replace(",", "")
                            
                            if amount_str:
                                amount = float(amount_str)
                                currency = self._symbol_to_currency(symbol)
                                return amount, currency
                    except (ValueError, IndexError):
                        continue
        
        # Fallback: find largest number
        numbers = re.findall(r"[\d,]+\.?\d*", text)
        amounts = []
        for num in numbers:
            try:
                clean_num = num.replace(",", "")
                if clean_num and "." in clean_num or len(clean_num) <= 6:
                    amounts.append(float(clean_num))
            except ValueError:
                continue
        
        if amounts:
            return max(amounts), None
        
        return None, None
    
    def _symbol_to_currency(self, symbol: str) -> Optional[str]:
        """Convert currency symbol to currency code."""
        symbol = symbol.strip()
        for sym, codes in self.CURRENCY_PATTERNS.items():
            if symbol == sym:
                return codes[0]
        return None
    
    def _extract_date(self, text: str) -> Optional[datetime]:
        """Extract date from receipt text."""
        date_patterns = [
            r"(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})",
            r"(\d{4}[/\-\.]\d{1,2}[/\-\.]\d{1,2})",
            r"(\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{2,4})",
            r"((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2},?\s+\d{2,4})",
        ]
        
        text_lower = text.lower()
        
        for pattern in date_patterns:
            match = re.search(pattern, text_lower)
            if match:
                date_str = match.group(1)
                try:
                    # Try various date formats
                    for fmt in [
                        "%m/%d/%Y", "%d/%m/%Y", "%Y/%m/%d",
                        "%m-%d-%Y", "%d-%m-%Y", "%Y-%m-%d",
                        "%m.%d.%Y", "%d.%m.%Y", "%Y.%m.%d",
                        "%m/%d/%y", "%d/%m/%y",
                        "%d %b %Y", "%d %B %Y",
                        "%b %d, %Y", "%B %d, %Y",
                        "%b %d %Y", "%B %d %Y",
                    ]:
                        try:
                            return datetime.strptime(date_str, fmt)
                        except ValueError:
                            continue
                except Exception:
                    continue
        
        return None
    
    def _is_date_line(self, line: str) -> bool:
        """Check if a line contains a date."""
        date_pattern = r"\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}"
        return bool(re.search(date_pattern, line))
    
    def _extract_items(self, lines: List[str]) -> List[Dict[str, Any]]:
        """Extract line items from receipt."""
        items = []
        item_pattern = r"^(.+?)\s+([\d,]+\.?\d*)$"
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Skip total/subtotal lines
            lower_line = line.lower()
            if any(kw in lower_line for kw in ["total", "subtotal", "tax", "change", "cash", "card"]):
                continue
            
            match = re.match(item_pattern, line)
            if match:
                name = match.group(1).strip()
                try:
                    amount = float(match.group(2).replace(",", ""))
                    if name and amount > 0:
                        items.append({
                            "name": name,
                            "amount": amount
                        })
                except ValueError:
                    continue
        
        return items
