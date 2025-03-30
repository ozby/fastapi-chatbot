import uuid as uuid_pkg
from datetime import datetime

from sqlalchemy.orm import Session

from src.app import models
from src.app.core.security import get_password_hash
from tests.conftest import fake


def create_user(db: Session, is_super_user: bool = False) -> models.User:
    _user = models.User(
        name=fake.name(),
        username=fake.user_name(),
        email=fake.email(),
        hashed_password=get_password_hash(fake.password()),
        profile_image_url=fake.image_url(),
        uuid=uuid_pkg.uuid4(),
        is_superuser=is_super_user,
    )

    db.add(_user)
    db.commit()
    db.refresh(_user)

    return _user


def create_post(db: Session, user: models.User) -> models.Post:
    """Create a test post for a given user."""
    # Generate a short title that doesn't exceed 30 characters
    title = fake.text(max_nb_chars=25)

    _post = models.Post(
        title=title,
        text=fake.paragraph(nb_sentences=3),
        media_url=fake.image_url(),
        created_by_user_id=user.id,
        uuid=uuid_pkg.uuid4(),
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
        is_deleted=False,
    )

    db.add(_post)
    db.commit()
    db.refresh(_post)

    return _post
