# StrideOn Backend (Python FastAPI)

## 🐍 Overview

The StrideOn Backend is a high-performance Python FastAPI server that powers the real-time gaming experience. Built with modern async programming, it provides sub-150ms latency for real-time gameplay, advanced H3 spatial indexing, and seamless blockchain integration.

## 🏗 Architecture

### Tech Stack
- **Framework**: FastAPI 0.104.0+
- **Language**: Python 3.11+
- **Database**: PostgreSQL 15+ with Supabase
- **Cache**: Redis 7.0+
- **Async Runtime**: asyncio + uvicorn
- **Spatial Engine**: H3 (Uber's hexagonal grid)
- **Blockchain**: Web3.py for Signify Mainnet
- **Real-time**: WebSocket with Redis pub/sub
- **Testing**: pytest + pytest-asyncio

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile Apps   │    │   WebSocket     │    │   Redis Cache   │
│   (Android/iOS) │◄──►│   Gateway       │◄──►│   (Hot Data)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │◄──►│   FastAPI       │◄──►│   Signify       │
│   (Cold Data)   │    │   Server        │    │   Mainnet       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Project Structure
```
StrideonBackend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── config.py               # Configuration management
│   ├── dependencies.py         # Dependency injection
│   ├── api/
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py         # Authentication endpoints
│   │   │   ├── game.py         # Game state endpoints
│   │   │   ├── territory.py    # Territory management
│   │   │   └── blockchain.py   # Blockchain integration
│   │   └── websocket.py        # WebSocket handlers
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py         # JWT and encryption
│   │   ├── database.py         # Database connection
│   │   └── redis_client.py     # Redis connection
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py             # User data models
│   │   ├── game.py             # Game state models
│   │   └── territory.py        # Territory models
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── user.py             # Pydantic schemas
│   │   ├── game.py             # Game schemas
│   │   └── territory.py        # Territory schemas
│   ├── services/
│   │   ├── __init__.py
│   │   ├── game_service.py     # Game logic
│   │   ├── h3_service.py       # H3 spatial operations
│   │   ├── blockchain_service.py # Blockchain operations
│   │   └── websocket_service.py # WebSocket management
│   └── utils/
│       ├── __init__.py
│       ├── h3_utils.py         # H3 utility functions
│       └── validators.py       # Data validation
├── tests/
│   ├── __init__.py
│   ├── conftest.py             # Test configuration
│   ├── test_api/               # API tests
│   ├── test_services/          # Service tests
│   └── test_utils/             # Utility tests
├── scripts/
│   ├── setup_database.py       # Database setup
│   ├── migrate_database.py     # Database migrations
│   └── test_connections.py     # Connection testing
├── requirements.txt
├── requirements-dev.txt
├── .env.example
├── docker-compose.yml
└── Dockerfile
```

## 🚀 Installation & Setup

### Prerequisites
- Python 3.11+
- PostgreSQL 15+
- Redis 7.0+
- Node.js 18+ (for Very Network integration)

### Quick Start

1. **Clone and Setup Environment**
```bash
cd StrideonBackend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

2. **Configure Environment**
```bash
cp .env.example .env
# Edit .env with your configuration
nano .env
```

3. **Setup Database**
```bash
python scripts/setup_database.py
```

4. **Start Server**
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Environment Configuration

#### Required Environment Variables
```env
# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/strideon_db
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# Redis Configuration
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=your-redis-password

# Blockchain Configuration
SIGNIFY_RPC_URL=https://rpc.signify.network
SIGNIFY_CHAIN_ID=1337
VERY_TOKEN_CONTRACT=0x1234567890123456789012345678901234567890
SIGNIFY_PRIVATE_KEY=your-private-key

# Security
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# External Services
WEPIN_APP_ID=your-wepin-app-id
WEPIN_PROJECT_ID=your-wepin-project-id
VERYCHAT_API_KEY=your-verychat-api-key
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# Performance
WORKERS=4
MAX_CONNECTIONS=100
```

## 🎮 Core Features

### Real-time Game Engine
- **Sub-150ms Latency**: Optimized for real-time gameplay
- **WebSocket Gateway**: Live player presence and updates
- **H3 Spatial Indexing**: Efficient hexagonal grid operations
- **Trail Management**: Real-time GPS trail processing
- **Collision Detection**: Player trail intersection logic

### H3 Spatial System
```python
from app.services.h3_service import H3Service
from app.utils.h3_utils import snap_gps_to_h3, detect_loop_closure

class H3Service:
    def __init__(self, resolution: int = 9):
        self.resolution = resolution
    
    async def process_gps_update(self, lat: float, lng: float) -> str:
        """Convert GPS coordinates to H3 hex cell"""
        return snap_gps_to_h3(lat, lng, self.resolution)
    
    async def check_loop_closure(self, trail: List[str], owned_territory: Set[str]) -> bool:
        """Check if trail intersects owned territory"""
        return detect_loop_closure(trail, owned_territory)
    
    async def calculate_area(self, h3_cells: List[str]) -> float:
        """Calculate area of H3 cells in square meters"""
        total_area = 0
        for cell in h3_cells:
            area = h3.cell_area(cell, unit='m^2')
            total_area += area
        return total_area
```

### Territory Management
```python
from app.services.game_service import GameService
from app.models.territory import TerritoryClaim

class GameService:
    async def process_territory_claim(
        self, 
        user_id: str, 
        trail: List[str], 
        session_id: str
    ) -> TerritoryClaim:
        """Process territory claim from trail"""
        
        # Validate trail
        if not self._validate_trail(trail):
            raise ValueError("Invalid trail")
        
        # Check for loop closure
        owned_territory = await self._get_owned_territory(user_id)
        if not detect_loop_closure(trail, owned_territory):
            raise ValueError("No loop closure detected")
        
        # Calculate claimed area
        claimed_cells = self._calculate_claimed_cells(trail, owned_territory)
        area_m2 = await self.h3_service.calculate_area(claimed_cells)
        
        # Create territory claim
        claim = TerritoryClaim(
            user_id=user_id,
            session_id=session_id,
            area_m2=area_m2,
            h3_cells=claimed_cells,
            claimed_at=datetime.utcnow()
        )
        
        # Save to database
        await self._save_territory_claim(claim)
        
        return claim
```

### Blockchain Integration
```python
from app.services.blockchain_service import BlockchainService
from web3 import Web3

class BlockchainService:
    def __init__(self):
        self.w3 = Web3(Web3.HTTPProvider(os.getenv("SIGNIFY_RPC_URL")))
        self.contract = self.w3.eth.contract(
            address=os.getenv("VERY_TOKEN_CONTRACT"),
            abi=VERY_TOKEN_ABI
        )
    
    async def settle_daily_rewards(self, claims: List[TerritoryClaim]) -> str:
        """Settle daily rewards on blockchain"""
        
        # Prepare batch data
        players = [claim.user_id for claim in claims]
        amounts = [claim.very_tokens_earned for claim in claims]
        
        # Create Merkle root
        merkle_root = self._create_merkle_root(players, amounts)
        
        # Submit transaction
        tx_hash = await self._submit_settlement_transaction(merkle_root, players, amounts)
        
        return tx_hash
    
    async def verify_territory_claim(self, claim: TerritoryClaim) -> bool:
        """Verify territory claim on blockchain"""
        # Implementation for claim verification
        pass
```

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_services/test_game_service.py

# Run with verbose output
pytest -v
```

### Integration Tests
```bash
# Run integration tests
pytest tests/integration/ -v

# Test with real database
pytest tests/integration/ --use-real-db
```

### Load Testing
```bash
# Install locust
pip install locust

# Run load test
locust -f tests/load/locustfile.py --host=http://localhost:8000
```

### Test Examples
```python
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_gps_update():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.post("/api/v1/gps/update", json={
            "lat": 30.7333,
            "lng": 76.7794,
            "session_id": "test-session"
        })
        assert response.status_code == 200
        assert "h3_cell" in response.json()

@pytest.mark.asyncio
async def test_territory_claim():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.post("/api/v1/territory/claim", json={
            "trail": ["892830829bfffff", "892830829afffff"],
            "session_id": "test-session"
        })
        assert response.status_code == 200
        assert "area_m2" in response.json()
```

## 📊 Performance & Monitoring

### Performance Metrics
- **API Response Time**: < 150ms average
- **WebSocket Latency**: < 50ms
- **Database Queries**: < 10ms
- **Redis Operations**: < 5ms
- **Concurrent Users**: 1000+ per region

### Monitoring Setup
```python
from prometheus_client import Counter, Histogram, generate_latest
from fastapi import FastAPI

# Metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests')
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')
GPS_UPDATES = Counter('gps_updates_total', 'Total GPS updates processed')
TERRITORY_CLAIMS = Counter('territory_claims_total', 'Total territory claims')

@app.middleware("http")
async def monitor_requests(request, call_next):
    REQUEST_COUNT.inc()
    start_time = time.time()
    response = await call_next(request)
    REQUEST_LATENCY.observe(time.time() - start_time)
    return response

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

### Logging Configuration
```python
import logging
from app.config import settings

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/app.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
```

## 🔒 Security

### Authentication & Authorization
```python
from app.core.security import create_access_token, verify_token
from app.dependencies import get_current_user

@app.post("/api/v1/auth/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/v1/users/me")
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
```

### Data Validation
```python
from pydantic import BaseModel, validator
from typing import List

class GPSUpdate(BaseModel):
    lat: float
    lng: float
    session_id: str
    
    @validator('lat')
    def validate_lat(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('lng')
    def validate_lng(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v
```

## 🚀 Deployment

### Docker Deployment
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose
```yaml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/strideon_db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=strideon_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    command: redis-server --requirepass password
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Production Deployment
```bash
# Install dependencies
pip install gunicorn

# Start with Gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000

# With systemd service
sudo systemctl enable strideon-backend
sudo systemctl start strideon-backend
```

## 🔮 Future Scope

### Planned Features
- **Microservices**: Split into domain-specific services
- **GraphQL**: Add GraphQL API alongside REST
- **Event Sourcing**: Implement event-driven architecture
- **Machine Learning**: AI-powered anti-cheat system
- **Real-time Analytics**: Live game analytics dashboard

### Technical Improvements
- **Performance**: Further optimization for 10k+ concurrent users
- **Scalability**: Horizontal scaling with load balancers
- **Monitoring**: Enhanced observability with distributed tracing
- **Testing**: Comprehensive E2E testing suite
- **Documentation**: Auto-generated API documentation

## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/amazing-feature`
3. **Install** dev dependencies: `pip install -r requirements-dev.txt`
4. **Write** tests for new features
5. **Run** tests: `pytest`
6. **Commit** changes: `git commit -m 'Add amazing feature'`
7. **Push** to branch: `git push origin feature/amazing-feature`
8. **Open** Pull Request

### Code Standards
- **Type Hints**: All functions must have type annotations
- **Docstrings**: Comprehensive docstrings for all functions
- **Testing**: Minimum 80% code coverage
- **Formatting**: Black code formatter
- **Linting**: Flake8 and mypy compliance

## 📚 Resources

### Documentation
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [H3 Documentation](https://h3geo.org/docs/)

### Community
- [StrideOn Discord](https://discord.gg/strideon)
- [FastAPI Community](https://github.com/tiangolo/fastapi)
- [Python Discord](https://discord.gg/python)

---

**Built with ❤ by the StrideOn Backend Team**