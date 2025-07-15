from datetime import datetime, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from slowapi import Limiter
from slowapi.util import get_remote_address

from app import schemas
from app.core import security
from app.core.config import settings
from app.core.security import limiter
from app.db.database import get_db
from app.db import models
from app.services.vault import vault_service
from app.services.keycloak import keycloak_service
from app.crud import crud_user

router = APIRouter()


@router.post("/register", response_model=schemas.User)
@limiter.limit("5/minute")
async def register(
    request: Request,
    user_in: schemas.UserCreate,
    db: Session = Depends(get_db)
) -> Any:
    """
    Register new user
    """
    # Check if user exists
    user = crud_user.get_user_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    user = crud_user.get_user_by_username(db, username=user_in.username)
    if user:
        raise HTTPException(
            status_code=400,
            detail="Username already taken"
        )
    
    # Create user in Keycloak
    keycloak_id = keycloak_service.create_user(
        email=user_in.email,
        username=user_in.username,
        password=user_in.password,
        full_name=user_in.full_name
    )
    
    # Create user in database
    user = crud_user.create_user(db, user_in, keycloak_id)
    
    # Log the registration
    audit_log = models.AuditLog(
        user_id=user.id,
        action="register",
        ip_address=get_remote_address(request),
        user_agent=request.headers.get("user-agent"),
        status="success"
    )
    db.add(audit_log)
    db.commit()
    
    return user


@router.post("/token", response_model=schemas.Token)
@limiter.limit("10/minute")
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    user = crud_user.authenticate_user(
        db, username=form_data.username, password=form_data.password
    )
    if not user:
        # Log failed attempt
        audit_log = models.AuditLog(
            action="login",
            ip_address=get_remote_address(request),
            user_agent=request.headers.get("user-agent"),
            status="failure",
            details=f"Invalid credentials for username: {form_data.username}"
        )
        db.add(audit_log)
        db.commit()
        
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    elif not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # Create tokens
    access_token = security.create_access_token(user.id)
    refresh_token = security.create_refresh_token(user.id)
    
    # Decode tokens to get JTI
    access_payload = security.decode_token(access_token)
    refresh_payload = security.decode_token(refresh_token)
    
    # Store tokens in Vault
    vault_service.store_token(user.id, {
        "jti": access_payload["jti"],
        "type": "access",
        "exp": access_payload["exp"],
        "token": access_token
    })
    
    vault_service.store_token(user.id, {
        "jti": refresh_payload["jti"],
        "type": "refresh",
        "exp": refresh_payload["exp"],
        "token": refresh_token
    })
    
    # Log successful login
    audit_log = models.AuditLog(
        user_id=user.id,
        action="login",
        ip_address=get_remote_address(request),
        user_agent=request.headers.get("user-agent"),
        status="success"
    )
    db.add(audit_log)
    db.commit()
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }


@router.post("/refresh", response_model=schemas.Token)
async def refresh_token(
    request: Request,
    refresh_token: str,
    db: Session = Depends(get_db)
) -> Any:
    """
    Refresh access token
    """
    payload = security.decode_token(refresh_token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type"
        )
    
    user_id = payload.get("sub")
    jti = payload.get("jti")
    
    # Check if token exists in Vault
    token_data = vault_service.get_token(user_id, jti)
    if not token_data or token_data.get("revoked"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked"
        )
    
    # Check if user exists and is active
    user = crud_user.get_user(db, user_id=int(user_id))
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    # Create new tokens
    new_access_token = security.create_access_token(user.id)
    new_refresh_token = security.create_refresh_token(user.id)
    
    # Decode new tokens to get JTI
    access_payload = security.decode_token(new_access_token)
    refresh_payload = security.decode_token(new_refresh_token)
    
    # Store new tokens in Vault
    vault_service.store_token(user.id, {
        "jti": access_payload["jti"],
        "type": "access",
        "exp": access_payload["exp"],
        "token": new_access_token
    })
    
    vault_service.store_token(user.id, {
        "jti": refresh_payload["jti"],
        "type": "refresh",
        "exp": refresh_payload["exp"],
        "token": new_refresh_token
    })
    
    # Revoke old refresh token
    vault_service.revoke_token(user_id, jti)
    
    # Log token refresh
    audit_log = models.AuditLog(
        user_id=user.id,
        action="token_refresh",
        ip_address=get_remote_address(request),
        user_agent=request.headers.get("user-agent"),
        status="success"
    )
    db.add(audit_log)
    db.commit()
    
    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }


@router.post("/revoke", response_model=schemas.Message)
async def revoke_token(
    request: Request,
    token_revoke: schemas.TokenRevoke,
    db: Session = Depends(get_db)
) -> Any:
    """
    Revoke a token
    """
    payload = security.decode_token(token_revoke.token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid token"
        )
    
    user_id = payload.get("sub")
    jti = payload.get("jti")
    
    # Revoke token in Vault
    success = vault_service.revoke_token(user_id, jti)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to revoke token"
        )
    
    # Add to blacklist in database
    blacklist_entry = models.TokenBlacklist(
        jti=jti,
        token_type=payload.get("type", "unknown"),
        user_id=int(user_id),
        expires_at=datetime.fromtimestamp(payload.get("exp")),
        reason=token_revoke.reason
    )
    db.add(blacklist_entry)
    
    # Log token revocation
    audit_log = models.AuditLog(
        user_id=int(user_id),
        action="token_revoke",
        ip_address=get_remote_address(request),
        user_agent=request.headers.get("user-agent"),
        status="success",
        details=f"Reason: {token_revoke.reason}"
    )
    db.add(audit_log)
    db.commit()
    
    return {"message": "Token revoked successfully"}


@router.get("/validate", response_model=schemas.ValidationResponse)
async def validate_token(
    token: str,
    db: Session = Depends(get_db)
) -> Any:
    """
    Validate a token
    """
    payload = security.decode_token(token)
    if not payload:
        return {"valid": False}
    
    user_id = payload.get("sub")
    jti = payload.get("jti")
    
    # Check if token is blacklisted
    blacklisted = db.query(models.TokenBlacklist).filter(
        models.TokenBlacklist.jti == jti
    ).first()
    if blacklisted:
        return {"valid": False}
    
    # Check token in Vault
    token_data = vault_service.get_token(user_id, jti)
    if not token_data or token_data.get("revoked"):
        return {"valid": False}
    
    # Check if user exists and is active
    user = crud_user.get_user(db, user_id=int(user_id))
    if not user or not user.is_active:
        return {"valid": False}
    
    # Optionally validate with Keycloak
    # keycloak_valid = keycloak_service.validate_token(token)
    
    return {
        "valid": True,
        "user_id": user.id,
        "username": user.username,
        "exp": payload.get("exp")
    }
