from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import schemas
from app.api import deps
from app.db.database import get_db
from app.crud import crud_user

router = APIRouter()


@router.get("/me", response_model=schemas.User)
async def read_user_me(
    current_user: schemas.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get current user
    """
    return current_user


@router.put("/me", response_model=schemas.User)
async def update_user_me(
    user_update: schemas.UserUpdate,
    current_user: schemas.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Update current user
    """
    user = crud_user.update_user(db, db_user=current_user, user_update=user_update)
    return user


@router.post("/change-password", response_model=schemas.Message)
async def change_password(
    password_change: schemas.PasswordChange,
    current_user: schemas.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db),
) -> Any:
    """
    Change current user password
    """
    user = crud_user.authenticate_user(
        db, username=current_user.username, password=password_change.current_password
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect password"
        )
    
    # Update password
    crud_user.update_password(db, user=user, new_password=password_change.new_password)
    
    return {"message": "Password updated successfully"}
