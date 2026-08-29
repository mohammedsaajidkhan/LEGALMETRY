# ============================================================================
# LEGALMETRY Role-Based Access Control (RBAC) (Person 1 - Data/Infra)
# Enforcing 4 Statutory Roles + Consumer and Regional Data Isolation
# ============================================================================

from typing import List, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, ExpiredSignatureError

from backend.db.postgres import get_db
from backend.db.models import User
from backend.auth.models_user import UserRole
from backend.auth.jwt_handler import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)

def get_current_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Validates the bearer token and returns the authenticated User ORM model.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    if not token:
        raise credentials_exception

    try:
        payload = decode_access_token(token)
        username: str = payload.get("username")
        if username is None:
            raise credentials_exception
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
        
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user account"
        )
        
    return user

class RoleChecker:
    """
    Dependency factory to check if the authenticated user has one of the allowed roles.
    """
    def __init__(self, allowed_roles: List[UserRole]):
        self.allowed_roles = [r.value if isinstance(r, UserRole) else r for r in allowed_roles]

    def __call__(self, current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation not permitted. Required role: {self.allowed_roles}. Your role: {current_user.role}"
            )
        return current_user

# Predefined role dependencies
require_inspector = RoleChecker([UserRole.INSPECTOR, UserRole.OFFICER, UserRole.CONTROLLER, UserRole.DIRECTOR])
require_supervisor_or_higher = RoleChecker([UserRole.OFFICER, UserRole.CONTROLLER, UserRole.DIRECTOR])
require_controller_or_higher = RoleChecker([UserRole.CONTROLLER, UserRole.DIRECTOR])
require_director = RoleChecker([UserRole.DIRECTOR])
require_consumer = RoleChecker([UserRole.CONSUMER])

def enforce_regional_scope(current_user: User, target_region: Optional[str]) -> bool:
    """
    Verifies if a user has permission to view/modify data for a target geographical region.
    NATIONAL scope grants access across all regions.
    """
    if not target_region or current_user.region_scope == "NATIONAL":
        return True
    if current_user.region_scope == target_region:
        return True
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=f"Access denied. User scope '{current_user.region_scope}' does not cover target region '{target_region}'"
    )

def sanitize_director_view(data: dict) -> dict:
    """
    Director Privacy Rule:
    Central Director sees national trends and aggregate MHI data,
    but NEVER individual scan photos or consumer report identities.
    """
    sanitized = data.copy()
    sanitized.pop("photo_url", None)
    sanitized.pop("photo_minio_key", None)
    sanitized.pop("consumer_name", None)
    sanitized.pop("consumer_email", None)
    sanitized.pop("consumer_phone", None)
    return sanitized