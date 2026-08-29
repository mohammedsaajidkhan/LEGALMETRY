# ============================================================================
# LEGALMETRY Authentication Router (Person 1 - Data/Infra)
# ============================================================================

from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from backend.db.postgres import get_db
from backend.db.models import User
from backend.auth.models_user import (
    UserCreate, UserLogin, UserResponse, TokenResponse, UserRole
)
from backend.auth.jwt_handler import (
    verify_password, get_password_hash, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
)
from backend.auth.rbac import get_current_user

auth_router = APIRouter(prefix="/auth", tags=["Authentication & RBAC"])

@auth_router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    Registers a new government officer, inspector, or consumer.
    """
    existing_user = db.query(User).filter(
        or_(User.username == user_in.username, User.email == user_in.email)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )

    db_user = User(
        username=user_in.username,
        email=user_in.email,
        password_hash=get_password_hash(user_in.password),
        role=user_in.role.value if isinstance(user_in.role, UserRole) else str(user_in.role),
        region_scope=user_in.region_scope,
        badge_number=user_in.badge_number,
        is_active=True
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@auth_router.post("/login", response_model=TokenResponse)
def login_user(login_data: UserLogin, db: Session = Depends(get_db)):
    """
    Authenticates user and returns a signed JWT access token.
    """
    user = db.query(User).filter(
        or_(
            User.username == login_data.username_or_email,
            User.email == login_data.username_or_email
        )
    ).first()

    if not user or not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username/email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated"
        )

    token_data = {
        "sub": str(user.id),
        "username": user.username,
        "role": user.role,
        "region_scope": user.region_scope
    }
    
    token = create_access_token(data=token_data)
    
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        role=user.role,
        username=user.username,
        region_scope=user.region_scope,
        badge_number=user.badge_number
    )

@auth_router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """
    Returns profile information and active statutory role of the authenticated user.
    """
    return current_user

@auth_router.post("/seed-demo-users")
def seed_demo_users(db: Session = Depends(get_db)):
    """
    Utility endpoint to seed the 5 standard demo roles for rapid parallel testing.
    """
    demo_accounts = [
        ("inspector_rajesh", "rajesh@legalmetry.gov.in", "Inspector123!", "inspector", "WEST_ZONE", "LM-INSP-101"),
        ("supervisor_sharma", "sharma@legalmetry.gov.in", "Supervisor123!", "officer", "WEST_ZONE", "LM-OFF-202"),
        ("controller_deshmukh", "deshmukh@legalmetry.gov.in", "Controller123!", "controller", "MAHARASHTRA", "LM-CTRL-303"),
        ("director_verma", "verma@legalmetry.gov.in", "Director123!", "director", "NATIONAL", "LM-DIR-001"),
        ("consumer_priya", "priya@gmail.com", "Consumer123!", "consumer", "NATIONAL", None),
    ]

    created = []
    for username, email, pwd, role, region, badge in demo_accounts:
        existing = db.query(User).filter(User.username == username).first()
        if not existing:
            u = User(
                username=username,
                email=email,
                password_hash=get_password_hash(pwd),
                role=role,
                region_scope=region,
                badge_number=badge,
                is_active=True
            )
            db.add(u)
            created.append(username)
    db.commit()
    return {"status": "seeded", "created_users": created}