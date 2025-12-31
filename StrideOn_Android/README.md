# StrideOn Android App

## 📱 Overview

The StrideOn Android application is a Kotlin-based mobile app that provides the core gaming experience for the StrideOn Move-to-Earn platform. Built with modern Android development practices using Jetpack Compose, it offers real-time GPS tracking, H3 hexagonal grid visualization, and seamless blockchain integration.

## 🏗 Architecture

### Tech Stack
- **Language**: Kotlin 1.9.0+
- **UI Framework**: Jetpack Compose
- **Architecture**: MVVM with Clean Architecture
- **Dependency Injection**: Hilt
- **Networking**: Retrofit + OkHttp + WebSocket
- **Database**: Room (local caching)
- **Maps**: Google Maps SDK with custom H3 overlay
- **Location**: Foreground Service with GPS tracking
- **Build System**: Gradle 8.0+

### Project Structure
```
StrideonApp/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/strideon/app/
│   │   │   │   ├── data/           # Data layer (API, Database, Repositories)
│   │   │   │   ├── domain/         # Business logic and use cases
│   │   │   │   ├── presentation/   # UI components and ViewModels
│   │   │   │   ├── di/             # Dependency injection modules
│   │   │   │   ├── utils/          # Utility classes and extensions
│   │   │   │   └── services/       # Background services
│   │   │   ├── res/                # Resources (layouts, drawables, etc.)
│   │   │   └── AndroidManifest.xml
│   │   └── test/                   # Unit tests
│   ├── build.gradle
│   └── proguard-rules.pro
├── build.gradle
├── gradle.properties
└── settings.gradle
```

## 🚀 Installation & Setup

### Prerequisites
- Android Studio Hedgehog+ (2023.1.1 or later)
- Kotlin 1.9.0+
- Java 17+
- Android SDK 34
- Google Maps API Key
- Physical device or emulator with GPS capabilities

### Quick Start

1. **Clone and Open Project**
```bash
cd StrideonApp
# Open in Android Studio: File -> Open -> Select StrideonApp folder
```

2. **Configure Environment**
```bash
# Create local.properties
echo "sdk.dir=$ANDROID_HOME" > local.properties
echo "MAPS_API_KEY=your-google-maps-api-key" >> local.properties
```

3. **Install Dependencies**
```bash
./gradlew build
```

4. **Run on Device**
```bash
./gradlew installDebug
```

### Configuration

#### Google Maps API Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Maps SDK for Android
4. Create API key with restrictions
5. Add to `local.properties`:
```properties
MAPS_API_KEY=your-api-key-here
```

#### Backend Configuration
Update `app/src/main/java/com/strideon/app/data/remote/ApiConfig.kt`:
```kotlin
object ApiConfig {
    const val BASE_URL = "https://your-backend-url.com"
    const val WEBSOCKET_URL = "wss://your-backend-url.com/ws"
    const val API_VERSION = "v1"
}
```

## 🎮 Core Features

### GPS Tracking Service
- **Foreground Service**: Continuous location updates
- **Multi-provider**: GPS + Network + Passive
- **Battery Optimization**: Efficient location sampling
- **Accuracy Filtering**: Kalman filter for smooth trails

### H3 Grid Visualization
- **Custom Overlay**: Hexagonal grid on Google Maps
- **Real-time Updates**: Live trail drawing
- **Territory Display**: Claimed areas visualization
- **Performance Optimized**: Efficient rendering for large areas

### Real-time Multiplayer
- **WebSocket Connection**: Live player presence
- **Nearby Players**: Real-time proximity detection
- **Trail Intersection**: Collision detection system
- **Cut Mechanics**: Territory interception logic

### Blockchain Integration
- **Wepin Wallet**: Secure key management
- **VERY Token**: In-app token display and transactions
- **Smart Contract**: Territory settlement verification
- **Off-chain Gaming**: Fast gameplay with on-chain settlement

## 🧪 Testing

### Unit Tests
```bash
# Run all unit tests
./gradlew test

# Run specific test class
./gradlew test --tests "com.strideon.app.domain.usecase.TrailUseCaseTest"
```

### Instrumented Tests
```bash
# Run on connected device
./gradlew connectedAndroidTest
```

### Test Coverage
```bash
# Generate coverage report
./gradlew jacocoTestReport
```

## 🔧 Development

### Code Style
- **Kotlin Style**: Follow official Kotlin coding conventions
- **Compose Guidelines**: Follow Material Design 3 principles
- **Architecture**: Clean Architecture with MVVM pattern
- **Testing**: Minimum 80% code coverage

### Key Components

#### Trail Manager
```kotlin
@Singleton
class TrailManager @Inject constructor(
    private val locationProvider: LocationProvider,
    private val h3Service: H3Service,
    private val gameStateRepository: GameStateRepository
) {
    private val _currentTrail = MutableStateFlow<List<H3Cell>>(emptyList())
    val currentTrail = _currentTrail.asStateFlow()
    
    suspend fun startTrailRecording(sessionId: String) {
        locationProvider.locationUpdates
            .map { location -> h3Service.latLngToCell(location.lat, location.lng) }
            .distinctUntilChanged()
            .collect { h3Cell ->
                updateTrail(sessionId, h3Cell)
                checkLoopClosure(h3Cell)
            }
    }
}
```

#### Game ViewModel
```kotlin
@HiltViewModel
class GameViewModel @Inject constructor(
    private val gameRepository: GameRepository,
    private val trailManager: TrailManager,
    private val webSocketService: WebSocketService
) : ViewModel() {
    
    private val _gameState = MutableStateFlow(GameState.IDLE)
    val gameState = _gameState.asStateFlow()
    
    fun startGameSession(city: String) {
        viewModelScope.launch {
            try {
                val session = gameRepository.startSession(city)
                _gameState.value = GameState.ACTIVE
                webSocketService.connect(session.userId, city)
                trailManager.startTrailRecording(session.id)
            } catch (e: Exception) {
                _gameState.value = GameState.ERROR
            }
        }
    }
}
```

## 📊 Performance

### Optimization Strategies
- **Memory Management**: Efficient bitmap handling for maps
- **Battery Optimization**: Smart location sampling
- **Network Efficiency**: Compressed WebSocket messages
- **UI Performance**: Lazy loading and pagination

### Performance Metrics
- **App Launch Time**: < 2 seconds
- **Map Rendering**: 60 FPS
- **GPS Accuracy**: ±3 meters
- **Battery Usage**: < 5% additional per hour
- **Memory Usage**: < 200MB

## 🔒 Security

### Anti-cheat Measures
- **Motion Sensor Validation**: Accelerometer + gyroscope correlation
- **Speed Limit Enforcement**: Maximum velocity thresholds
- **GPS Consistency**: Impossibility detection for teleportation
- **Device Fingerprinting**: Hardware-based identification
- **Behavioral Analysis**: ML-based bot detection

### Data Protection
- **Encrypted Storage**: Sensitive data encryption
- **Secure Communication**: TLS 1.3 for all network calls
- **Key Management**: Secure wallet key storage
- **Privacy Compliance**: GDPR and local privacy laws

## 🚀 Deployment

### Release Build
```bash
# Generate release APK
./gradlew assembleRelease

# Generate signed APK
./gradlew assembleRelease -PkeystoreFile=release.keystore -PkeystorePassword=password
```

### Google Play Store
1. **Version Update**: Increment `versionCode` and `versionName`
2. **Release Notes**: Update changelog
3. **Screenshots**: Update store screenshots
4. **Upload**: Upload signed APK to Play Console
5. **Rollout**: Staged rollout to users

### CI/CD Pipeline
```yaml
# .github/workflows/android.yml
name: Android CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
      - name: Build with Gradle
        run: ./gradlew build
      - name: Run tests
        run: ./gradlew test
```

## 🔮 Future Scope

### Planned Features
- **iOS Version**: Cross-platform development with Kotlin Multiplatform
- **AR Integration**: Augmented reality trail visualization
- **Offline Mode**: Cached gameplay with sync when online
- **Social Features**: Enhanced guild and friend system
- **Analytics**: Advanced player behavior tracking

### Technical Improvements
- **Performance**: Further optimization for low-end devices
- **Accessibility**: Enhanced support for users with disabilities
- **Internationalization**: Multi-language support
- **Modularization**: Feature-based module structure
- **Testing**: Enhanced automated testing suite

## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** changes: `git commit -m 'Add amazing feature'`
4. **Push** to branch: `git push origin feature/amazing-feature`
5. **Open** Pull Request

### Code Review Process
- **Automated Checks**: CI/CD pipeline validation
- **Manual Review**: At least one maintainer approval
- **Testing**: All tests must pass
- **Documentation**: Update relevant documentation

## 📚 Resources

### Documentation
- [Android Developer Guide](https://developer.android.com/guide)
- [Jetpack Compose Documentation](https://developer.android.com/jetpack/compose)
- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
- [Google Maps Android API](https://developers.google.com/maps/documentation/android-sdk)

### Community
- [StrideOn Discord](https://discord.gg/strideon)
- [Android Developers Blog](https://android-developers.googleblog.com/)
- [Kotlin Weekly](https://kotlinweekly.net/)

---

**Built with ❤ by the StrideOn Android Team**




## Current Implementation & How To Run (MVP)

This repository currently ships an XML-based Android app (not Compose) that connects to the included FastAPI backend and, through it, to an EVM chain (Very Network demo via local Hardhat). Key points:

- UI: Activities with XML layouts (Splash, Welcome, Login, Home, MainActivity with Google Maps, LeaderboardActivity).
- Networking: Minimal OkHttp-based ApiClient (no Retrofit/Hilt yet) using BuildConfig.API_BASE_URL.
- Web3: The Android app calls backend endpoints that use web3.py to read from the contract. The Home screen integrates Wepin SDK for wallet login/UI.

### Prerequisites
- Android Studio Hedgehog+ and an emulator/device
- Python 3.10+
- Node.js (for local Hardhat Very RPC in `very-network-integration`)

### 1) Start the Very Network local chain (Hardhat)
```
cd very-network-integration
npm install
npx hardhat node
```
This exposes an RPC on http://127.0.0.1:8545 and deploys demo contracts. Note the contract address in the logs if different from default.

### 2) Start the backend (FastAPI)
```
cd StrideonBackend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
# Optionally configure env vars if your contract or RPC differ
export VERY_RPC_URL="http://127.0.0.1:8545"
export VERY_CHAIN_ID=31337
export VERY_CONTRACT_ADDR="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
uvicorn main:app --reload --port 8000
```
Backend health:
- http://localhost:8000/health
- http://localhost:8000/verynet/health
- http://localhost:8000/verynet/leaderboard?count=10
- http://localhost:8000/verynet/score/<address>

### 3) Configure Android app base URL
The Android app points to the backend via BuildConfig:
- File: `StrideonApp/app/build.gradle.kts`
- Field: `buildConfigField("String", "API_BASE_URL", "\"http://10.0.2.2:8000\"")`

Notes:
- `10.0.2.2` is the Android emulator loopback to your host’s `localhost`. If you run on a physical device, replace with your machine IP and ensure the port is reachable.

### 4) Run the Android app
- Build/install from Android Studio or:
```
cd StrideonApp
./gradlew installDebug
```

### 5) What to expect in the app
- Splash screen pings `/health` and shows a Toast whether the backend is reachable.
- Home screen: tap the StrideOn favicon (top-right) to open the Leaderboard.
- Leaderboard screen:
  - Loads live data from `/verynet/leaderboard` and fills the 1–8 ranks.
  - Includes a "Check Demo Score" button that calls `/verynet/score` for a sample address and shows the result in a Toast.
- MainActivity: GPS + Map screen with a simplified hex grid for demo purposes.
- Wepin: Home integrates Wepin SDK for wallet login/widget (requires valid appId/appKey and providers).

### 6) Google Maps API Key
Currently the key is specified in `AndroidManifest.xml` under the meta-data tag. Replace the value with your key if needed. For production, consider moving it to `local.properties`/manifest placeholders.

### Roadmap (from original README)
- Migrate UI to Jetpack Compose and add Hilt/Retrofit/Room per original architecture.
- Expand on-chain interactions and secure auth flows.
- Add tests and CI.
