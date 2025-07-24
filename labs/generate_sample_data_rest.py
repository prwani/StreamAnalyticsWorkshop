#!/usr/bin/env python3
"""
Azure Event Hub Sample Data Generator (REST API Version)
Sends simulated telemetry data to Azure Event Hub using REST API calls.
Alternative approach that doesn't require Azure SDK.
"""

import json
import time
import random
import logging
import hashlib
import hmac
import base64
import urllib.parse
import requests
from datetime import datetime, timezone
from typing import Dict, Any
import sys
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class EventHubRestClient:
    """Event Hub client using REST API calls."""
    
    def __init__(self, connection_string: str, eventhub_name: str):
        self.eventhub_name = eventhub_name
        self.connection_string = connection_string
        self.endpoint = None
        self.namespace = None
        self.key_name = None
        self.key = None
        self._parse_connection_string()
    
    def _parse_connection_string(self):
        """Parse the Event Hub connection string."""
        try:
            parts = {}
            for part in self.connection_string.split(';'):
                if '=' in part and part.strip():
                    key, value = part.split('=', 1)
                    parts[key.strip()] = value.strip()
            
            required_parts = ['Endpoint', 'SharedAccessKeyName', 'SharedAccessKey']
            for part in required_parts:
                if part not in parts:
                    raise ValueError(f"Connection string missing {part}")
            
            self.endpoint = parts['Endpoint'].rstrip('/')
            self.namespace = self.endpoint.replace('sb://', '').replace('https://', '')
            self.key_name = parts['SharedAccessKeyName']
            self.key = parts['SharedAccessKey']
            
            logger.info(f"Parsed connection string for namespace: {self.namespace}")
            
        except Exception as e:
            logger.error(f"Failed to parse connection string: {e}")
            raise
    
    def _generate_sas_token(self) -> str:
        """Generate SAS token for authentication."""
        try:
            # Resource URI for SAS token (use sb:// format)
            resource_uri = f"{self.endpoint}/{self.eventhub_name}"
            
            # Token expiry (1 hour from now)
            expiry = int(time.time()) + 3600
            
            # String to sign
            string_to_sign = f"{urllib.parse.quote(resource_uri, safe='')}\n{expiry}"
            
            # Generate signature
            key_bytes = self.key.encode('utf-8')
            string_bytes = string_to_sign.encode('utf-8')
            signature = base64.b64encode(
                hmac.new(key_bytes, string_bytes, hashlib.sha256).digest()
            ).decode('utf-8')
            
            # Construct SAS token
            token = (
                f"SharedAccessSignature sr={urllib.parse.quote(resource_uri, safe='')}"
                f"&sig={urllib.parse.quote(signature, safe='')}"
                f"&se={expiry}"
                f"&skn={self.key_name}"
            )
            
            return token
            
        except Exception as e:
            logger.error(f"Failed to generate SAS token: {e}")
            raise
    
    def send_message(self, message_data: Dict[str, Any]) -> bool:
        """Send a message to Event Hub using REST API."""
        try:
            # Generate SAS token
            token = self._generate_sas_token()
            
            # Prepare the request
            url = f"https://{self.namespace}/{self.eventhub_name}/messages"
            headers = {
                'Authorization': token,
                'Content-Type': 'application/json; charset=utf-8'
            }
            
            # Convert message to JSON
            message_json = json.dumps(message_data)
            
            logger.debug(f"Sending to URL: {url}")
            
            # Send the request
            response = requests.post(
                url=url,
                headers=headers,
                data=message_json.encode('utf-8'),
                timeout=30
            )
            
            if response.status_code == 201:
                logger.info(f"✓ Message sent successfully at {datetime.now()}")
                return True
            else:
                logger.error(f"✗ Failed to send message. Status: {response.status_code}")
                logger.error(f"Response: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.error(f"✗ Network error sending message: {e}")
            return False
        except Exception as e:
            logger.error(f"✗ Failed to send message: {e}")
            return False

class EventHubDataGeneratorRest:
    """Class to handle Event Hub data generation using REST API."""
    
    def __init__(self, connection_string: str, eventhub_name: str):
        self.eventhub_name = eventhub_name
        self.client = EventHubRestClient(connection_string, eventhub_name)
    
    def generate_telemetry_data(self) -> Dict[str, Any]:
        """Generate random telemetry data."""
        device_id = f"device-{random.randint(1, 100):03d}"
        timestamp = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
        
        data = {
            "deviceId": device_id,
            "timestamp": timestamp,
            "temperature": round(random.uniform(20, 40), 2),
            "humidity": round(random.uniform(30, 80), 2),
            "pressure": round(random.uniform(1000, 1100), 2),
            "location": {
                "lat": 47.6062,
                "lon": -122.3321
            }
        }
        
        return data
    
    def test_connectivity(self) -> bool:
        """Test Event Hub connectivity by sending a test message."""
        logger.info("Testing Event Hub connectivity...")
        
        test_data = {
            "deviceId": "test-device",
            "timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
            "temperature": 25.0,
            "humidity": 50.0,
            "pressure": 1013.25,
            "location": {
                "lat": 47.6062,
                "lon": -122.3321
            }
        }
        
        success = self.client.send_message(test_data)
        if success:
            logger.info("✓ Test message sent successfully! Event Hub is reachable.")
        else:
            logger.error("✗ Test message failed!")
            
        return success
    
    def run_continuous_generation(self, interval_seconds: int = 5):
        """Run continuous data generation and sending."""
        logger.info(f"Starting continuous data generation (every {interval_seconds} seconds)")
        logger.info("Press Ctrl+C to stop...")
        
        try:
            while True:
                # Generate sample data
                sample_data = self.generate_telemetry_data()
                
                # Print the data
                print("\nSample telemetry data:")
                print(json.dumps(sample_data, indent=2))
                
                # Send to Event Hub
                self.client.send_message(sample_data)
                
                # Wait for next iteration
                time.sleep(interval_seconds)
                
        except KeyboardInterrupt:
            logger.info("\n⏹️  Stopping data generation...")
        except Exception as e:
            logger.error(f"Error in continuous generation: {e}")
            raise

def get_connection_string() -> str:
    """Get connection string from environment or user input."""
    
    # Try environment variable first
    conn_str = os.getenv('EVENTHUB_CONNECTION_STRING')
    if conn_str:
        logger.info("Using connection string from environment variable")
        return conn_str
    
    # If not found, prompt user
    print("\nEvent Hub connection string not found in environment variable.")
    print("Please provide your Event Hub connection string.")
    print("You can get it from Azure portal > Event Hubs > Shared access policies")
    print("\nConnection string format:")
    print("Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=your-key")
    
    while True:
        conn_str = input("\nEnter connection string: ").strip()
        if conn_str:
            return conn_str
        print("Connection string cannot be empty. Please try again.")

def main():
    """Main function to run the Event Hub data generator."""
    
    # Configuration
    EVENTHUB_NAME = "telemetry-data"
    SEND_INTERVAL = 5  # seconds
    
    print("Azure Event Hub Sample Data Generator (REST API)")
    print("=" * 60)
    
    try:
        # Get connection string
        connection_string = get_connection_string()
        
        # Initialize the generator
        generator = EventHubDataGeneratorRest(
            connection_string=connection_string,
            eventhub_name=EVENTHUB_NAME
        )
        
        # Test connectivity
        if not generator.test_connectivity():
            print("\n❌ Connectivity test failed. Please check:")
            print("1. Your connection string is correct")
            print("2. Your Event Hub exists and is accessible")
            print("3. Your network connection is working")
            sys.exit(1)
        
        # Start continuous generation
        generator.run_continuous_generation(SEND_INTERVAL)
        
    except Exception as e:
        logger.error(f"Application error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
