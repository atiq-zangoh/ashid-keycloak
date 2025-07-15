from typing import Optional
from keycloak import KeycloakOpenID, KeycloakAdmin
from keycloak.exceptions import KeycloakError

from app.core.config import settings


class KeycloakService:
    def __init__(self):
        self._keycloak_openid = None
        self._keycloak_admin = None
    
    @property
    def keycloak_openid(self):
        if self._keycloak_openid is None:
            try:
                self._keycloak_openid = KeycloakOpenID(
                    server_url=settings.KEYCLOAK_URL,
                    client_id=settings.KEYCLOAK_CLIENT_ID,
                    realm_name=settings.KEYCLOAK_REALM,
                    client_secret_key=settings.KEYCLOAK_CLIENT_SECRET
                )
            except Exception as e:
                print(f"Warning: Could not initialize Keycloak OpenID client: {e}")
                return None
        return self._keycloak_openid
    
    @property
    def keycloak_admin(self):
        if self._keycloak_admin is None:
            try:
                self._keycloak_admin = KeycloakAdmin(
                    server_url=settings.KEYCLOAK_URL,
                    username=settings.KEYCLOAK_ADMIN_USERNAME,
                    password=settings.KEYCLOAK_ADMIN_PASSWORD,
                    realm_name=settings.KEYCLOAK_REALM,
                    verify=True
                )
            except Exception as e:
                print(f"Warning: Could not initialize Keycloak Admin client: {e}")
                return None
        return self._keycloak_admin
    
    def create_user(self, email: str, username: str, password: str, full_name: Optional[str] = None) -> Optional[str]:
        """Create user in Keycloak and return user ID"""
        if self.keycloak_admin is None:
            print("Warning: Keycloak admin client not available")
            return None
            
        try:
            payload = {
                "email": email,
                "username": username,
                "enabled": True,
                "firstName": full_name.split()[0] if full_name else "",
                "lastName": " ".join(full_name.split()[1:]) if full_name and len(full_name.split()) > 1 else "",
                "credentials": [{
                    "type": "password",
                    "value": password,
                    "temporary": False
                }]
            }
            
            user_id = self.keycloak_admin.create_user(payload, exist_ok=False)
            return user_id
        except KeycloakError as e:
            print(f"Error creating user in Keycloak: {e}")
            return None
    
    def get_user(self, user_id: str) -> Optional[dict]:
        """Get user from Keycloak"""
        if self.keycloak_admin is None:
            print("Warning: Keycloak admin client not available")
            return None
            
        try:
            return self.keycloak_admin.get_user(user_id)
        except KeycloakError as e:
            print(f"Error getting user from Keycloak: {e}")
            return None
    
    def update_user(self, user_id: str, **kwargs) -> bool:
        """Update user in Keycloak"""
        if self.keycloak_admin is None:
            print("Warning: Keycloak admin client not available")
            return False
            
        try:
            self.keycloak_admin.update_user(user_id, kwargs)
            return True
        except KeycloakError as e:
            print(f"Error updating user in Keycloak: {e}")
            return False
    
    def delete_user(self, user_id: str) -> bool:
        """Delete user from Keycloak"""
        if self.keycloak_admin is None:
            print("Warning: Keycloak admin client not available")
            return False
            
        try:
            self.keycloak_admin.delete_user(user_id)
            return True
        except KeycloakError as e:
            print(f"Error deleting user from Keycloak: {e}")
            return False
    
    def validate_token(self, token: str) -> Optional[dict]:
        """Validate token with Keycloak"""
        if self.keycloak_openid is None:
            print("Warning: Keycloak OpenID client not available")
            return None
            
        try:
            return self.keycloak_openid.introspect(token)
        except KeycloakError as e:
            print(f"Error validating token with Keycloak: {e}")
            return None
    
    def get_jwks(self) -> Optional[dict]:
        """Get JWKS from Keycloak"""
        if self.keycloak_openid is None:
            print("Warning: Keycloak OpenID client not available")
            return None
            
        try:
            return self.keycloak_openid.certs()
        except KeycloakError as e:
            print(f"Error getting JWKS from Keycloak: {e}")
            return None


keycloak_service = KeycloakService()
