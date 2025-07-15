import hvac
from typing import Optional, Dict, Any
import json
from datetime import datetime

from app.core.config import settings


class VaultService:
    def __init__(self):
        self.client = hvac.Client(
            url=settings.VAULT_URL,
            token=settings.VAULT_TOKEN
        )
        self._ensure_mount_point()
    
    def _ensure_mount_point(self):
        """Ensure the mount point exists in Vault"""
        try:
            if not self.client.sys.is_mounted(settings.VAULT_MOUNT_POINT):
                self.client.sys.enable_secrets_engine(
                    backend_type='kv',
                    path=settings.VAULT_MOUNT_POINT,
                    options={'version': '2'}
                )
        except Exception as e:
            print(f"Error ensuring mount point: {e}")
    
    def store_token(self, user_id: int, token_data: Dict[str, Any]) -> bool:
        """Store token data in Vault"""
        try:
            path = f"{settings.VAULT_PATH_PREFIX}/{user_id}/{token_data['jti']}"
            
            # Add metadata
            token_data['stored_at'] = datetime.utcnow().isoformat()
            token_data['user_id'] = user_id
            
            self.client.secrets.kv.v2.create_or_update_secret(
                mount_point=settings.VAULT_MOUNT_POINT,
                path=path,
                secret=token_data
            )
            return True
        except Exception as e:
            print(f"Error storing token in Vault: {e}")
            return False
    
    def get_token(self, user_id: int, jti: str) -> Optional[Dict[str, Any]]:
        """Retrieve token data from Vault"""
        try:
            path = f"{settings.VAULT_PATH_PREFIX}/{user_id}/{jti}"
            response = self.client.secrets.kv.v2.read_secret_version(
                mount_point=settings.VAULT_MOUNT_POINT,
                path=path
            )
            return response['data']['data']
        except Exception as e:
            print(f"Error retrieving token from Vault: {e}")
            return None
    
    def revoke_token(self, user_id: int, jti: str) -> bool:
        """Mark token as revoked in Vault"""
        try:
            token_data = self.get_token(user_id, jti)
            if token_data:
                token_data['revoked'] = True
                token_data['revoked_at'] = datetime.utcnow().isoformat()
                
                path = f"{settings.VAULT_PATH_PREFIX}/{user_id}/{jti}"
                self.client.secrets.kv.v2.create_or_update_secret(
                    mount_point=settings.VAULT_MOUNT_POINT,
                    path=path,
                    secret=token_data
                )
                return True
            return False
        except Exception as e:
            print(f"Error revoking token in Vault: {e}")
            return False
    
    def list_user_tokens(self, user_id: int) -> list:
        """List all tokens for a user"""
        try:
            path = f"{settings.VAULT_PATH_PREFIX}/{user_id}"
            response = self.client.secrets.kv.v2.list_secrets(
                mount_point=settings.VAULT_MOUNT_POINT,
                path=path
            )
            return response.get('data', {}).get('keys', [])
        except Exception as e:
            print(f"Error listing tokens from Vault: {e}")
            return []
    
    def cleanup_expired_tokens(self):
        """Remove expired tokens from Vault (to be run periodically)"""
        # This would be implemented as a background task
        pass


vault_service = VaultService()
