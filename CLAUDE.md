# Glasscast Weather App

## Project Overview
Glasscast is a minimal weather app built with iOS 26's Liquid Glass design language, featuring Supabase authentication and OpenWeatherMap for weather data.

## Architecture
- **Pattern**: MVVM + Clean Architecture
- **UI Framework**: SwiftUI with iOS 26 features
- **Backend**: Supabase (Auth + Database)
- **Weather API**: OpenWeatherMap

## Project Structure
```
Glasscast/
├── App/
│   └── GlasscastApp.swift          # App entry point
├── Core/
│   ├── Config/
│   │   └── AppConfig.swift         # Reads credentials from Info.plist/xcconfig
│   ├── Extensions/
│   │   └── View+GlassEffect.swift  # Glass effect modifiers
│   ├── Theme/
│   │   └── AppTheme.swift          # Colors and theme
│   └── Network/
│       └── NetworkManager.swift    # Generic network layer
├── Features/
│   ├── Auth/                       # Authentication (OTP/Magic Link)
│   ├── Home/                       # Weather detail view
│   ├── Search/                     # City search → adds to Cities
│   ├── Cities/                     # My Cities list → can mark as Favorite
│   ├── Favorites/                  # Favorites only (isFavorite = true)
│   ├── Settings/                   # App preferences
│   └── MainTabView.swift           # 5-tab navigation with center search
├── Models/
│   ├── Weather.swift               # Weather data models
│   ├── City.swift                  # City search models
│   └── FavoriteCity.swift          # Saved cities with isFavorite flag
├── Services/
│   ├── AuthService.swift           # Supabase auth wrapper
│   ├── WeatherService.swift        # OpenWeatherMap API
│   └── FavoritesService.swift      # Supabase CRUD for cities/favorites
└── GlasscastWidgets/               # iOS Widget Extension
    ├── GlasscastWidgetsBundle.swift
    └── GlasscastWidget.swift
```

## Configuration Setup

### 1. Configure API Keys
Edit `Config.xcconfig` in the project root and fill in your credentials:
```
SUPABASE_URL = https://your-project-id.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
OPENWEATHERMAP_API_KEY = your_api_key_here
```

**Note:** `Config.xcconfig` is gitignored. Use `Config.xcconfig.example` as a template.

### 2. Supabase Package (Already Configured)
The Supabase Swift package is already added to the project. Xcode will fetch it automatically when you open the project.

## Supabase Database Setup

### Initial Setup (New Projects)
Run this SQL in Supabase SQL Editor:
```sql
CREATE TABLE favorite_cities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  city_name TEXT NOT NULL,
  country TEXT,
  lat DECIMAL(10, 7) NOT NULL,
  lon DECIMAL(10, 7) NOT NULL,
  is_favorite BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE favorite_cities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cities" ON favorite_cities
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cities" ON favorite_cities
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cities" ON favorite_cities
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cities" ON favorite_cities
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_favorite_cities_user_id ON favorite_cities(user_id);
CREATE INDEX idx_favorite_cities_is_favorite ON favorite_cities(is_favorite);
```

### Migration (Existing Projects)
If you already have the `favorite_cities` table without the `is_favorite` column, run this migration:
```sql
-- Add is_favorite column
ALTER TABLE favorite_cities
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE NOT NULL;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_favorite_cities_is_favorite ON favorite_cities(is_favorite);

-- Add UPDATE policy if not exists
CREATE POLICY "Users can update own cities" ON favorite_cities
  FOR UPDATE USING (auth.uid() = user_id);
```

## Key Features
- **OTP Authentication**: Email-based magic link sign-in via Supabase
- **Weather Dashboard**: Current conditions + 5-day forecast
- **City Search**: Geocoding API integration with 500ms debounced search
- **My Cities**: Save cities from search, view weather for all saved cities
- **Favorites**: Mark cities as favorites for quick access
- **Data Flow**: Search → Add to Cities → Mark as Favorite
- **Cloud Sync**: Real-time sync with Supabase
- **iOS 26 Glass Effects**: `.glassEffect()` modifier for Liquid Glass UI
- **iOS Widgets**: Home screen widgets (small, medium, large sizes)

## Development Notes

### View Modifiers
- `glassCard(cornerRadius:)` - Glass effect with rounded corners
- `glassPill()` - Capsule-shaped glass effect
- `GradientBackground` - Dynamic background based on color scheme
- `WeatherGradientBackground` - Weather-condition-based gradients

### Services
All services are singletons accessed via `.shared`:
- `AuthService.shared` - Authentication state & methods
- `WeatherService.shared` - Weather API calls
- `FavoritesService.shared` - Supabase CRUD operations

### State Management
- Uses `@Observable` macro (iOS 17+)
- ViewModels are `@MainActor` isolated
- Services use `actor` for thread safety

## iOS Widgets Setup

To add the widget extension to your project:

### Method 1: Add as New Target (Recommended)
1. In Xcode, go to **File → New → Target**
2. Select **Widget Extension**
3. Name it `GlasscastWidgets`
4. Uncheck "Include Configuration App Intent"
5. Click Finish
6. Replace the generated files with the files in `GlasscastWidgets/` folder:
   - `GlasscastWidgetsBundle.swift`
   - `GlasscastWidget.swift`
7. Delete the auto-generated widget files

### Method 2: Use Existing Files
1. Create widget target as above
2. Remove auto-generated files
3. Add existing files from `GlasscastWidgets/` to the widget target
4. Ensure files are assigned to the widget target in File Inspector

### Widget Features
- **Small Widget**: Shows temperature and condition icon
- **Medium Widget**: Temperature, high/low, and location
- **Large Widget**: Full weather details with last update time

## Testing Checklist
- [ ] Build compiles without errors
- [ ] Auth flow: Sign up, OTP verification, sign in
- [ ] Weather displays for searched cities
- [ ] Can add/remove cities from favorites
- [ ] Favorites sync to Supabase
- [ ] Settings: Unit toggle, appearance, sign out
- [ ] Dark/Light mode transitions
- [ ] Pull-to-refresh on favorites/home
- [ ] Widgets display correctly on home screen

## API Endpoints Used

### OpenWeatherMap
- Current Weather: `GET /data/2.5/weather`
- 5-Day Forecast: `GET /data/2.5/forecast`
- Geocoding: `GET /geo/1.0/direct`

### Supabase
- Auth: `supabase.auth.signInWithOTP()`
- Auth: `supabase.auth.verifyOTP()`
- Database: `supabase.from("favorite_cities")`
