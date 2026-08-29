# ============================================================================
# LEGALMETRY User & Auth Schemas (Person 1 - Data/Infra)
# Pydantic Schemas for 5 Statutory Roles and JWT Tokens
# ============================================================================

from enum import Enum
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field

class UserRole(str, Enum):
    INSPECTOR = "inspector"     # Field Inspector: capture, scan, physical inspection
    OFFICER = "officer"         # Regional Officer / Supervisor: spot checks, review queues
    CONTROLLER = "controller"   # State Controller: state-wide compliance & trends
    DIRECTOR = "director"       # Central Director: national aggregated data only (no individual photos)
    CONSUMER = "consumer"       # Consumer: restricted read-only portal & report status

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, description="Unique username")
    email: str = Field(..., description="Government or verified email address")
    role: UserRole = Field(default=UserRole.INSPECTOR, description="Statutory role")
    region_scope: str = Field(default="NATIONAL", description="Assigned geographical district/state/zone")
    badge_number: Optional[str] = Field(None, description="Official government badge / ID identifier")

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, description="Plaintext password")

class UserLogin(BaseModel):
    username_or_email: str = Field(..., description="Username or registered email")
    password: str = Field(..., description="User password")

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    role: str
    username: str
    region_scope: str
    badge_number: Optional[str] = None

class TokenPayload(BaseModel):
    sub: str                    # user_id or username
    username: str
    role: UserRole
    region_scope: str
    exp: int
    iat: int