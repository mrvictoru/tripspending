# TripSpending

A cross-platform mobile application for tracking travel expenses by scanning receipts with OCR technology. Built with Flutter for the frontend and FastAPI for the backend, with all data stored and processed locally on device.

## Features

### 📸 Receipt Scanning
- Take photos of receipts using your device camera
- Multilingual OCR support (English, Chinese, Japanese, Korean, Spanish, French, German, and more)
- Automatic extraction of merchant name, total amount, date, and line items
- Smart category suggestion based on receipt content

### 📊 Expense Tracking
- Create and manage multiple trips
- Track spending with detailed receipt information
- Set budgets and monitor spending progress
- Automatic categorization of expenses

### 🗺️ Location Tracking
- Capture GPS location when adding receipts
- View all spending locations on Google Maps
- Reverse geocoding to get address from coordinates

### 📈 Analytics Dashboard
- Visual spending breakdown by category (pie charts)
- Daily spending trends (bar charts)
- Budget vs actual spending comparison
- Trip statistics and summaries

### 📤 Export & Share
- Export trip data to Excel (.xlsx) with formatted sheets
- Export to CSV for compatibility with other apps
- Export to JSON for data portability
- Share exported files via system share sheet

### 🎨 Modern UI
- Material Design 3 with dynamic theming
- Light and dark mode support
- Responsive layout for various screen sizes
- Intuitive navigation and user experience

## Project Structure

```
tripspending/
├── frontend/                   # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── models/            # Data models
│   │   │   ├── trip.dart
│   │   │   ├── receipt.dart
│   │   │   └── category.dart
│   │   ├── services/          # Business logic services
│   │   │   ├── database_service.dart
│   │   │   ├── ocr_service.dart
│   │   │   ├── location_service.dart
│   │   │   └── export_service.dart
│   │   ├── providers/         # State management
│   │   │   ├── trip_provider.dart
│   │   │   ├── receipt_provider.dart
│   │   │   └── settings_provider.dart
│   │   ├── screens/           # UI screens
│   │   │   ├── home_screen.dart
│   │   │   ├── trip_detail_screen.dart
│   │   │   ├── add_receipt_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── map_screen.dart
│   │   │   ├── export_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── widgets/           # Reusable widgets
│   │   └── utils/             # Utilities and theme
│   ├── pubspec.yaml           # Flutter dependencies
│   └── android/               # Android platform files
│
├── backend/                    # FastAPI backend (optional, for advanced features)
│   ├── app/
│   │   ├── main.py            # FastAPI app entry
│   │   ├── database.py        # SQLite database config
│   │   ├── api/               # API endpoints
│   │   │   ├── trips.py
│   │   │   ├── receipts.py
│   │   │   ├── categories.py
│   │   │   └── exports.py
│   │   ├── models/            # Database models & schemas
│   │   └── services/          # Business services
│   │       ├── ocr_service.py
│   │       ├── category_service.py
│   │       └── export_service.py
│   ├── tests/                 # API tests
│   └── requirements.txt       # Python dependencies
│
└── README.md
```

## Getting Started

### Prerequisites

- **Flutter SDK** >= 3.10.0
- **Dart** >= 3.0.0
- **Python** >= 3.10 (for backend)
- **Android Studio** or **VS Code** with Flutter extensions
- **Google Maps API Key** (for map features)

### Flutter App Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/tripspending.git
   cd tripspending/frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Maps API**
   - Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Add your API key to `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_API_KEY_HERE"/>
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Backend Setup (Optional)

The app works fully offline with local storage. The backend is optional and can be used for additional features or web access.

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Install Tesseract OCR** (required for EasyOCR)
   - **Ubuntu/Debian**: `sudo apt install tesseract-ocr`
   - **macOS**: `brew install tesseract`
   - **Windows**: Download from [GitHub releases](https://github.com/UB-Mannheim/tesseract/wiki)

5. **Run the server**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Access API documentation**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

### Running Tests

**Flutter tests:**
```bash
cd frontend
flutter test
```

**Backend tests:**
```bash
cd backend
pytest
```

## Technology Stack

### Frontend (Flutter)
- **State Management**: Provider
- **Local Database**: sqflite (SQLite)
- **OCR**: Google ML Kit Text Recognition
- **Maps**: google_maps_flutter
- **Location**: Geolocator, Geocoding
- **Charts**: fl_chart
- **Export**: excel, share_plus

### Backend (FastAPI)
- **Framework**: FastAPI
- **Database**: SQLite with SQLAlchemy (async)
- **OCR**: EasyOCR (multilingual support)
- **Export**: openpyxl, pandas
- **Validation**: Pydantic

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/trips` | List all trips |
| POST | `/api/trips` | Create a new trip |
| GET | `/api/trips/{id}` | Get trip details with stats |
| PUT | `/api/trips/{id}` | Update a trip |
| DELETE | `/api/trips/{id}` | Delete a trip |
| GET | `/api/trips/{id}/summary` | Get trip spending summary |
| POST | `/api/receipts/scan` | OCR scan a receipt image |
| POST | `/api/receipts` | Create a receipt |
| GET | `/api/receipts` | List receipts |
| GET | `/api/categories` | List categories |
| GET | `/api/exports/trip/{id}/excel` | Export trip to Excel |
| GET | `/api/exports/trip/{id}/csv` | Export trip to CSV |

## Supported Languages for OCR

- English (en)
- Chinese Simplified (zh)
- Chinese Traditional (zh-tw)
- Japanese (ja)
- Korean (ko)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Russian (ru)
- Arabic (ar)
- Thai (th)
- Vietnamese (vi)

## Spending Categories

- 🍽️ Food & Dining
- 🚗 Transportation
- 🏨 Accommodation
- 🛍️ Shopping
- 🎭 Entertainment
- 🛒 Groceries
- 💊 Health & Pharmacy
- 📱 Communication
- 📦 Other

## Privacy & Data Storage

- **All data is stored locally** on your device
- No account required
- No data sent to external servers
- Full offline functionality
- Export your data anytime

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [FastAPI](https://fastapi.tiangolo.com/) - Python web framework
- [Google ML Kit](https://developers.google.com/ml-kit) - On-device machine learning
- [EasyOCR](https://github.com/JaidedAI/EasyOCR) - Multilingual OCR
- [fl_chart](https://pub.dev/packages/fl_chart) - Beautiful charts for Flutter
