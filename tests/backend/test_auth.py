# ============================================================================
# LEGALMETRY Hour 2 Auth & RBAC Tests (Person 1 - Data/Infra)
# ============================================================================

import os
import sys
import unittest
from datetime import timedelta
import uuid

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from jose import ExpiredSignatureError
from fastapi import FastAPI, Depends
from fastapi.testclient import TestClient

from backend.db.postgres import Base, engine, SessionLocal
from backend.auth.models_user import UserRole
from backend.auth.jwt_handler import (
    get_password_hash, verify_password, create_access_token, decode_access_token
)
from backend.auth.rbac import (
    require_inspector, require_director, enforce_regional_scope, sanitize_director_view
)
from backend.auth.router import auth_router

# Test FastAPI app with protected test endpoints
test_app = FastAPI()
test_app.include_router(auth_router)

@test_app.get("/test/inspector-only")
def inspector_endpoint(user = Depends(require_inspector)):
    return {"message": "Inspector access granted", "username": user.username}

@test_app.get("/test/director-only")
def director_endpoint(user = Depends(require_director)):
    return {"message": "Director access granted", "username": user.username}

class TestAuthAndRBAC(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(test_app)

    def test_01_password_hashing(self):
        plain_pwd = "SecretInspectorPassword!2026"
        hashed = get_password_hash(plain_pwd)
        self.assertNotEqual(plain_pwd, hashed)
        self.assertTrue(verify_password(plain_pwd, hashed))
        self.assertFalse(verify_password("WrongPassword!", hashed))

    def test_02_jwt_token_generation_and_decoding(self):
        claims = {
            "sub": "user_42",
            "username": "inspector_arun",
            "role": "inspector",
            "region_scope": "WEST_ZONE"
        }
        token = create_access_token(claims, expires_delta=timedelta(hours=2))
        decoded = decode_access_token(token)
        self.assertEqual(decoded.get("username"), "inspector_arun")
        self.assertEqual(decoded.get("role"), "inspector")
        self.assertEqual(decoded.get("region_scope"), "WEST_ZONE")

    def test_03_expired_jwt_token_rejection(self):
        claims = {"sub": "user_expired", "username": "expired_user", "role": "inspector", "region_scope": "NATIONAL"}
        # Create token that expired 10 minutes ago
        token = create_access_token(claims, expires_delta=timedelta(minutes=-10))
        with self.assertRaises(ExpiredSignatureError):
            decode_access_token(token)

    def test_04_full_register_and_login_flow(self):
        uid = uuid.uuid4().hex[:6]
        username = f"insp_{uid}"
        email = f"insp_{uid}@gov.in"
        password = "ValidPassword123!"

        # 1. Register User
        reg_payload = {
            "username": username,
            "email": email,
            "password": password,
            "role": "inspector",
            "region_scope": "WEST_ZONE",
            "badge_number": f"INSP-{uid}"
        }
        res_reg = self.client.post("/auth/register", json=reg_payload)
        self.assertEqual(res_reg.status_code, 201)
        self.assertEqual(res_reg.json()["username"], username)

        # 2. Login with correct password
        login_payload = {
            "username_or_email": username,
            "password": password
        }
        res_login = self.client.post("/auth/login", json=login_payload)
        self.assertEqual(res_login.status_code, 200)
        token_data = res_login.json()
        self.assertIn("access_token", token_data)
        self.assertEqual(token_data["role"], "inspector")

        # 3. Login with incorrect password
        bad_login_payload = {
            "username_or_email": username,
            "password": "WrongPassword123!"
        }
        res_bad = self.client.post("/auth/login", json=bad_login_payload)
        self.assertEqual(res_bad.status_code, 401)

        # 4. Access /auth/me with Bearer token
        headers = {"Authorization": f"Bearer {token_data['access_token']}"}
        res_me = self.client.get("/auth/me", headers=headers)
        self.assertEqual(res_me.status_code, 200)
        self.assertEqual(res_me.json()["email"], email)

    def test_05_rbac_role_enforcement(self):
        uid = uuid.uuid4().hex[:6]
        # Register inspector
        self.client.post("/auth/register", json={
            "username": f"insp_rbac_{uid}",
            "email": f"insp_rbac_{uid}@gov.in",
            "password": "Password123!",
            "role": "inspector",
            "region_scope": "WEST_ZONE"
        })
        # Register director
        self.client.post("/auth/register", json={
            "username": f"dir_rbac_{uid}",
            "email": f"dir_rbac_{uid}@gov.in",
            "password": "Password123!",
            "role": "director",
            "region_scope": "NATIONAL"
        })

        # Login inspector
        res_insp_login = self.client.post("/auth/login", json={
            "username_or_email": f"insp_rbac_{uid}",
            "password": "Password123!"
        })
        insp_headers = {"Authorization": f"Bearer {res_insp_login.json()['access_token']}"}

        # Login director
        res_dir_login = self.client.post("/auth/login", json={
            "username_or_email": f"dir_rbac_{uid}",
            "password": "Password123!"
        })
        dir_headers = {"Authorization": f"Bearer {res_dir_login.json()['access_token']}"}

        # Inspector can access inspector endpoint
        res1 = self.client.get("/test/inspector-only", headers=insp_headers)
        self.assertEqual(res1.status_code, 200)

        # Inspector attempting to access director-only endpoint -> 403 Forbidden!
        res2 = self.client.get("/test/director-only", headers=insp_headers)
        self.assertEqual(res2.status_code, 403)

        # Director CAN access director endpoint
        res3 = self.client.get("/test/director-only", headers=dir_headers)
        self.assertEqual(res3.status_code, 200)

    def test_06_director_privacy_sanitization(self):
        raw_scan_data = {
            "scan_id": 101,
            "overall_severity": "CRITICAL",
            "photo_url": "http://minio:9000/legalmetry-evidence/photo_secret.jpg",
            "photo_minio_key": "evidence/101.jpg",
            "consumer_name": "Ramesh Gupta",
            "consumer_email": "ramesh@example.com",
            "mhi_score": 72.5
        }
        sanitized = sanitize_director_view(raw_scan_data)
        self.assertNotIn("photo_url", sanitized)
        self.assertNotIn("photo_minio_key", sanitized)
        self.assertNotIn("consumer_name", sanitized)
        self.assertNotIn("consumer_email", sanitized)
        self.assertEqual(sanitized["scan_id"], 101)
        self.assertEqual(sanitized["mhi_score"], 72.5)

if __name__ == "__main__":
    unittest.main()