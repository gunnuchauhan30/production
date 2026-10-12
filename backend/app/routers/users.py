"""User management (admin only) + change-own-password.

There is deliberately NO public sign-up anywhere in this app: accounts are
created only here, by an admin. Everything under /users needs the 'admin'
role; /account/change-password works for any logged-in user (own password).
"""
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..database import get_db
from ..auth import get_current_user, require_role, hash_password, verify_password
from ..models import PpeUser, PpeRole

router = APIRouter(prefix="/users", tags=["users"])
account_router = APIRouter(prefix="/account", tags=["account"])

MIN_PASSWORD_LEN = 8
MAX_PASSWORD_BYTES = 72  # bcrypt only looks at the first 72 bytes


class UserRow(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    username: str
    full_name: Optional[str] = None
    role: PpeRole
    is_active: bool
    created_at: Optional[datetime] = None


class NewUser(BaseModel):
    username: str
    full_name: str
    password: str
    role: PpeRole


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    role: Optional[PpeRole] = None
    is_active: Optional[bool] = None


class PasswordReset(BaseModel):
    new_password: str


class ChangePassword(BaseModel):
    current_password: str
    new_password: str


def _check_password(pw: str) -> None:
    if len(pw) < MIN_PASSWORD_LEN:
        raise HTTPException(400, f"Password must be at least {MIN_PASSWORD_LEN} characters")
    if len(pw.encode("utf-8")) > MAX_PASSWORD_BYTES:
        raise HTTPException(400, f"Password is too long (max {MAX_PASSWORD_BYTES} bytes)")


def _get_user(db: Session, user_id: int) -> PpeUser:
    user = db.query(PpeUser).filter(PpeUser.id == user_id).first()
    if not user:
        raise HTTPException(404, "User not found")
    return user


def _other_active_admins(db: Session, exclude_id: int) -> int:
    return (
        db.query(PpeUser)
        .filter(PpeUser.role == PpeRole.admin, PpeUser.is_active.is_(True), PpeUser.id != exclude_id)
        .count()
    )


@router.get("/roles", response_model=List[str])
def list_roles(admin=Depends(require_role("admin"))):
    return [r.value for r in PpeRole]


@router.get("", response_model=List[UserRow])
def list_users(db: Session = Depends(get_db), admin=Depends(require_role("admin"))):
    return db.query(PpeUser).order_by(PpeUser.id).all()


@router.post("", response_model=UserRow, status_code=201)
def create_user(payload: NewUser, db: Session = Depends(get_db), admin=Depends(require_role("admin"))):
    username = payload.username.strip()
    full_name = payload.full_name.strip()
    if len(username) < 3 or any(ch.isspace() for ch in username):
        raise HTTPException(400, "Username must be at least 3 characters with no spaces")
    if not full_name:
        raise HTTPException(400, "Full name is required")
    _check_password(payload.password)

    if db.query(PpeUser).filter(func.lower(PpeUser.username) == username.lower()).first():
        raise HTTPException(409, f"Username '{username}' already exists")

    user = PpeUser(
        username=username,
        full_name=full_name,
        password_hash=hash_password(payload.password),
        role=payload.role,
        is_active=True,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, f"Username '{username}' already exists")
    db.refresh(user)
    return user


@router.patch("/{user_id}", response_model=UserRow)
def update_user(user_id: int, payload: UserUpdate, db: Session = Depends(get_db), admin=Depends(require_role("admin"))):
    user = _get_user(db, user_id)
    data = {k: v for k, v in payload.model_dump(exclude_unset=True).items() if v is not None}

    if "full_name" in data:
        data["full_name"] = data["full_name"].strip()
        if not data["full_name"]:
            raise HTTPException(400, "Full name cannot be empty")

    loses_admin = user.role == PpeRole.admin and user.is_active and (
        ("role" in data and data["role"] != PpeRole.admin) or data.get("is_active") is False
    )
    if loses_admin:
        if user.id == admin.id:
            raise HTTPException(400, "You cannot disable or demote your own account")
        if _other_active_admins(db, user.id) == 0:
            raise HTTPException(400, "At least one active admin must remain")
    if user.id == admin.id and data.get("is_active") is False:
        raise HTTPException(400, "You cannot disable your own account")

    for key, value in data.items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user


@router.post("/{user_id}/reset-password")
def reset_password(user_id: int, payload: PasswordReset, db: Session = Depends(get_db), admin=Depends(require_role("admin"))):
    user = _get_user(db, user_id)
    _check_password(payload.new_password)
    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"ok": True}


@router.delete("/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db), admin=Depends(require_role("admin"))):
    user = _get_user(db, user_id)
    if user.id == admin.id:
        raise HTTPException(400, "You cannot delete your own account")
    if user.role == PpeRole.admin and user.is_active and _other_active_admins(db, user.id) == 0:
        raise HTTPException(400, "At least one active admin must remain")
    try:
        db.delete(user)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409,
            "This user has entries recorded under their name, so it cannot be deleted. Disable the account instead.",
        )
    return None


@account_router.post("/change-password")
def change_password(payload: ChangePassword, db: Session = Depends(get_db), user: PpeUser = Depends(get_current_user)):
    if not verify_password(payload.current_password, user.password_hash):
        raise HTTPException(400, "Current password is incorrect")
    _check_password(payload.new_password)
    if payload.new_password == payload.current_password:
        raise HTTPException(400, "New password must be different from the current one")
    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"ok": True}
