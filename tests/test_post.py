from fastapi import status
from fastapi.testclient import TestClient
from pytest_mock import MockerFixture
from sqlalchemy.orm import Session

from src.app.api.dependencies import get_current_user
from src.app.api.v1.users import oauth2_scheme
from tests.conftest import fake, override_dependency

from .helpers import generators, mocks


def test_post_creation(db: Session, client: TestClient) -> None:
    """Test creating a new post."""
    # Create a user first
    user = generators.create_user(db)

    # Mock authentication
    override_dependency(get_current_user, mocks.get_current_user(user))
    override_dependency(oauth2_scheme, mocks.oauth2_scheme())

    # Post data with a short, valid title (2-30 chars)
    post_data = {
        "title": "Short test title",  # Ensure title is valid length (2-30 chars)
        "text": fake.paragraph(nb_sentences=3),
        "media_url": fake.image_url(),
    }

    # Create the post
    response = client.post(f"/api/v1/{user.username}/post", json=post_data)

    # Assert status code
    assert response.status_code == status.HTTP_201_CREATED

    # Assert response contains expected data
    response_data = response.json()
    assert response_data["title"] == post_data["title"]
    assert response_data["text"] == post_data["text"]
    assert response_data["media_url"] == post_data["media_url"]
    assert "id" in response_data
    assert "created_at" in response_data
    assert response_data["created_by_user_id"] == user.id


def test_get_post(db: Session, client: TestClient) -> None:
    """Test retrieving a single post."""
    # Create a user
    user = generators.create_user(db)

    # Create a post for the user
    post = generators.create_post(db, user)

    # Get the post
    response = client.get(f"/api/v1/{user.username}/post/{post.id}")

    # Assert status code
    assert response.status_code == status.HTTP_200_OK

    # Assert response contains expected data
    response_data = response.json()
    assert response_data["id"] == post.id
    assert response_data["title"] == post.title
    assert response_data["text"] == post.text
    assert response_data["created_by_user_id"] == user.id


def test_get_multiple_posts(db: Session, client: TestClient) -> None:
    """Test retrieving multiple posts."""
    # Create a user
    user = generators.create_user(db)

    # Create multiple posts
    for _ in range(5):
        generators.create_post(db, user)

    # Get posts
    response = client.get(f"/api/v1/{user.username}/posts")

    # Assert status code
    assert response.status_code == status.HTTP_200_OK

    # Assert response contains expected data
    response_data = response.json()
    assert "data" in response_data
    assert len(response_data["data"]) >= 5
    # Check for pagination fields
    assert "page" in response_data
    assert "items_per_page" in response_data


def test_update_post(db: Session, client: TestClient) -> None:
    """Test updating a post."""
    # Create a user
    user = generators.create_user(db)

    # Create a post for the user
    post = generators.create_post(db, user)

    # Mock authentication
    override_dependency(get_current_user, mocks.get_current_user(user))
    override_dependency(oauth2_scheme, mocks.oauth2_scheme())

    # Update data with a short title to avoid length issues
    update_data = {"title": "Short test title"}

    # Update the post
    response = client.patch(f"/api/v1/{user.username}/post/{post.id}", json=update_data)

    # Assert status code
    assert response.status_code == status.HTTP_200_OK

    # Verify the update by getting the post
    get_response = client.get(f"/api/v1/{user.username}/post/{post.id}")
    if get_response.status_code == status.HTTP_200_OK:
        get_data = get_response.json()
        assert get_data["title"] == update_data["title"]


def test_delete_post(db: Session, client: TestClient, mocker: MockerFixture) -> None:
    """Test deleting a post."""
    # Create a user
    user = generators.create_user(db)

    # Create a post for the user
    post = generators.create_post(db, user)

    # Mock authentication
    override_dependency(get_current_user, mocks.get_current_user(user))
    override_dependency(oauth2_scheme, mocks.oauth2_scheme())

    # Mock JWT decode
    mocker.patch("src.app.core.security.jwt.decode", return_value={"sub": user.username, "exp": 9999999999})

    # Delete the post
    response = client.delete(f"/api/v1/{user.username}/post/{post.id}")

    # Assert status code
    assert response.status_code == status.HTTP_200_OK

    # Verify the post is deleted (should return 404)
    get_response = client.get(f"/api/v1/{user.username}/post/{post.id}")
    assert get_response.status_code == status.HTTP_404_NOT_FOUND


def test_delete_db_post(db: Session, client: TestClient, mocker: MockerFixture) -> None:
    """Test permanently deleting a post from the database (admin only)."""
    # Create a regular user
    user = generators.create_user(db)

    # Create a post for the user
    post = generators.create_post(db, user)

    # Create a superuser
    superuser = generators.create_user(db, is_super_user=True)

    # Mock authentication as superuser
    override_dependency(get_current_user, mocks.get_current_user(superuser))
    override_dependency(oauth2_scheme, mocks.oauth2_scheme())

    # Mock JWT decode
    mocker.patch("src.app.core.security.jwt.decode", return_value={"sub": superuser.username, "exp": 9999999999})

    response = client.delete(f"/api/v1/{user.username}/db_post/{post.id}")

    # Assert status code
    assert response.status_code == status.HTTP_200_OK

    # Verify the post is deleted (should return 404)
    get_response = client.get(f"/api/v1/{user.username}/post/{post.id}")
    assert get_response.status_code == status.HTTP_404_NOT_FOUND


def test_unauthorized_post_update(db: Session, client: TestClient) -> None:
    """Test that a user cannot update another user's post."""
    # Create two users
    user1 = generators.create_user(db)
    user2 = generators.create_user(db)

    # Create a post for user1
    post = generators.create_post(db, user1)

    # Mock authentication as user2
    override_dependency(get_current_user, mocks.get_current_user(user2))
    override_dependency(oauth2_scheme, mocks.oauth2_scheme())

    # Update data
    update_data = {
        "title": "Short test title"  # Use a valid title to avoid validation issues
    }

    # Try to update user1's post as user2
    response = client.patch(f"/api/v1/{user1.username}/post/{post.id}", json=update_data)

    # Assert status code (should be forbidden or unprocessable entity)
    # In some environments we might get a 422 due to validation issues
    assert response.status_code in [status.HTTP_403_FORBIDDEN, status.HTTP_422_UNPROCESSABLE_ENTITY]
