# TideParty 🌊

TideParty is an iOS application designed to enhance the tide pooling experience through AI-powered creature identification, gamified discovery, and safety education.

## ✨ Key Features

### 🔍 AI Scanner & Discovery

- **Real-time Identification**: Uses CoreML (`TidePoolIdentifier.mlpackage`) to identify sea creatures in real-time.
- **Discovery Results**: Shows detailed information about captured creatures.
- **"Let's Learn"**: Educational fact sheets powered by Generative AI (Cerebras/Gemini).
- **Interactive Quizzes**: Test your knowledge about the creatures you find to earn XP.

### 🏠 Landing & Dashboard

- **Dynamic Dashboard**: Displays current weather conditions and forecast.
- **AI Insights**: "Otto's Insights" provides daily tide pooling tips and fun facts.
- **Donate Card**: Direct links to ocean conservation charities (Ocean Conservancy, Surfrider, etc.).

### 🤝 Party Mode

- **Group Experience**: Join parties with friends to explore together.
- **Gamification**: Earn XP, level up, and compete on leaderboards.

### 👤 User Account & Badges

- **Profile**: Track your exploration stats.
- **Badge System**: Unlock badges for milestones (e.g., finding 5 starfish, visiting 10 spots).
- **Customization**: Set unlocked badges as your profile icon.

### 📍 Spots & Navigation

- **Tide Pool Map**: Locate nearby tide pools.
- **Conditions**: View tide charts and weather for specific spots.

### 🛡️ Safety & Education

- **T.I.D.E. Code**: Onboarding pledge to ensure respectful interaction with marine life.
- **Safety First**: Mandatory safety pledge confirmation on every app launch.

## 📂 Project Structure

The project is organized into the following main directories:

### `Features/`

Contains the UI and specific logic for each feature area:

- **Landing/**: Main home screen (`LandingView.swift`), AI Insights (`AIInsightView.swift`).
- **Scanner/**: Camera logic (`ScannerView.swift`), ML model (`TidePoolIdentifier.mlpackage`), and result pages (`DiscoveryResultView.swift`).
- **Account/**: User profile, badge grid, and settings (`AccountView.swift`).
- **Onboarding/**: Login/Signup flow (`OnboardingViews.swift`) and T.I.D.E. code education.
- **Safety/**: App launch safety pledge (`SafetyPledgeView.swift`).
- **Party/**: Group session logic and views.
- **Spots/**: Map and location-based features (`SpotsListView.swift`, `SpotsMapView.swift`).

### `Services/`

Core application services managed as singletons:

- `AuthManager.swift`: Firebase authentication.
- `UserStatsService.swift`: Manages user progress, badges, and XP.
- `PartyService.swift`: Handles realtime coordination for party mode.
- `LocationManager.swift`: CoreLocation wrapper.
- `CameraManager.swift`: AVFoundation setup.

### `Data/`

Data models and external data services:

- **Models/**: Swift structs for `Badge`, `TideSpot`, `Weather`, etc.
- **Services/**:
  - `CerebrasService.swift` / `GenAIService.swift`: Interfaces for AI text generation.
  - `WeatherService.swift`: Fetches weather data.
  - `TideService.swift`: Fetches tide data.

### `Components/`

Reusable UI components used across multiple features.

- `DonateCard.swift`: Conservation donation promotion card.

### `Assets.xcassets/`

Contains all images, icons, and color sets (e.g., `MainBlue`, `OttoBook`, `OttoMonacle`, Badge icons).

## 🛠️ Tech Stack

- **SwiftUI**: Main UI framework.
- **CoreML**: On-device machine learning for image recognition.
- **Firebase**: Backend for Authentication and Firestore (database).
- **AVFoundation**: Camera handling.
- **MapKit**: Location and mapping.

## 🚀 Getting Started

1. Open `TideParty.xcodeproj` in Xcode.
2. Ensure you have a valid development team selected.
3. Build and run on a simulator or device (requires iOS 16+).
