#!/usr/bin/env python3
"""
Azure Event Hub Sample Data Generator
Sends simulated telemetry data to Azure Event Hub on a periodic basis.
"""

import json
import time
import random
import logging
from datetime import datetime, timezone
from typing import Dict, Any
import sys
import os

# Try to import Azure libraries
try:
    from azure.eventhub import EventHubProducerClient, EventData
    from azure.identity import DefaultAzureCredential, AzureCliCredential
    from azure.mgmt.eventhub import EventHubManagementClient
    AZURE_LIBRARIES_AVAILABLE = True
except ImportError:
    print("Azure libraries not found. Installing required packages...")
    import subprocess
    
    packages = [
        "azure-eventhub",
        "azure-identity", 
        "azure-mgmt-eventhub"
    ]
    
    for package in packages:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        except subprocess.CalledProcessError as e:
            print(f"Failed to install {package}: {e}")
            sys.exit(1)
    
    # Try importing again after installation
    try:
        from azure.eventhub import EventHubProducerClient, EventData
        from azure.identity import DefaultAzureCredential, AzureCliCredential
        from azure.mgmt.eventhub import EventHubManagementClient
        AZURE_LIBRARIES_AVAILABLE = True
    except ImportError as e:
        print(f"Still unable to import Azure libraries after installation: {e}")
        AZURE_LIBRARIES_AVAILABLE = False

# Configure logging - suppress verbose Azure SDK messages
logging.basicConfig(
    level=logging.ERROR,
    format='%(message)s'
)
logger = logging.getLogger(__name__)

# Suppress Azure SDK internal logging
logging.getLogger('azure').setLevel(logging.ERROR)
logging.getLogger('azure.eventhub').setLevel(logging.ERROR)
logging.getLogger('azure.core').setLevel(logging.ERROR)
logging.getLogger('uamqp').setLevel(logging.ERROR)

class EventHubDataGenerator:
    """Class to handle Event Hub data generation and sending."""
    
    def __init__(self, resource_group: str, namespace_name: str, eventhub_name: str):
        self.resource_group = resource_group
        self.namespace_name = namespace_name
        self.eventhub_name = eventhub_name
        self.connection_string = None
        self.producer_client = None
        
    def get_connection_string_from_azure(self) -> str:
        """Get Event Hub connection string using Azure credentials."""
        try:
            # Try different credential types
            credential = None
            
            # First try Azure CLI credentials (most common in development)
            try:
                credential = AzureCliCredential()
                # logger.info("Using Azure CLI credentials")
            except Exception:
                # Fall back to default credential chain
                credential = DefaultAzureCredential()
                # logger.info("Using default Azure credentials")
            
            # Get subscription ID from Azure CLI
            import subprocess
            result = subprocess.run(
                ["az", "account", "show", "--query", "id", "-o", "tsv"],
                capture_output=True,
                text=True,
                check=True
            )
            subscription_id = result.stdout.strip()
            # logger.info(f"Using subscription: {subscription_id}")
            
            # Create Event Hub management client
            mgmt_client = EventHubManagementClient(credential, subscription_id)
            
            # Get authorization rules (connection strings)
            auth_rules = mgmt_client.namespaces.list_authorization_rules(
                self.resource_group, 
                self.namespace_name
            )
            
            # Find RootManageSharedAccessKey or first available rule
            rule_name = None
            for rule in auth_rules:
                if rule.name == "RootManageSharedAccessKey":
                    rule_name = rule.name
                    break
                elif rule_name is None:  # Use first rule as fallback
                    rule_name = rule.name
            
            if not rule_name:
                raise Exception("No authorization rules found")
            
            # Get the connection string
            keys = mgmt_client.namespaces.list_keys(
                self.resource_group,
                self.namespace_name, 
                rule_name
            )
            
            connection_string = keys.primary_connection_string
            # logger.info("Successfully retrieved connection string from Azure")
            return connection_string
            
        except Exception as e:
            logger.error(f"Failed to get connection string from Azure: {e}")
            raise
    
    def get_connection_string_from_env(self) -> str:
        """Get connection string from environment variable."""
        conn_str = os.getenv('EVENTHUB_CONNECTION_STRING')
        if conn_str:
            # logger.info("Using connection string from environment variable")
            return conn_str
        raise Exception("EVENTHUB_CONNECTION_STRING environment variable not set")
    
    def initialize_producer(self):
        """Initialize the Event Hub producer client."""
        try:
            # Try to get connection string from Azure first
            try:
                self.connection_string = self.get_connection_string_from_azure()
            except Exception as e:
                # logger.warning(f"Failed to get connection string from Azure: {e}")
                # logger.info("Trying environment variable...")
                self.connection_string = self.get_connection_string_from_env()
            
            # Create producer client
            self.producer_client = EventHubProducerClient.from_connection_string(
                conn_str=self.connection_string,
                eventhub_name=self.eventhub_name
            )
            
            # logger.info("Event Hub producer client initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize producer client: {e}")
            raise
    
    def generate_telemetry_data(self) -> Dict[str, Any]:
        """Generate random telemetry data."""
        device_id = f"device-{random.randint(1, 100):03d}"
        timestamp = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
        
        # List of sensor types to randomly choose from
        sensor_types = ["DHT22", "BME280", "SHT30", "AM2302", "DS18B20"]
        
        # List of firmware versions to randomly choose from
        firmware_versions = ["v1.2.3", "v1.3.0", "v1.2.5", "v1.4.1", "v1.1.9"]
        
        data = {
            "deviceId": device_id,
            "timestamp": timestamp,
            "temperature": round(random.uniform(20, 40), 1),
            "humidity": round(random.uniform(30, 80), 1),
            "pressure": round(random.uniform(1000, 1100), 2),
            "location": {
                "lat": 47.6062,
                "lon": -122.3321
            },
            "metadata": {
                "sensorType": random.choice(sensor_types),
                "firmware": random.choice(firmware_versions)
            }
        }
        
        return data
    
    def send_message(self, message_data: Dict[str, Any]) -> bool:
        """Send a message to Event Hub."""
        try:
            message_json = json.dumps(message_data)
            event_data = EventData(message_json)
            
            # Send the event
            with self.producer_client:
                event_data_batch = self.producer_client.create_batch()
                event_data_batch.add(event_data)
                self.producer_client.send_batch(event_data_batch)
            
            print(f"✓ Message sent successfully at {datetime.now()}")
            return True
            
        except Exception as e:
            logger.error(f"✗ Failed to send message: {e}")
            return False
    
    def test_connectivity(self) -> bool:
        """Test Event Hub connectivity by sending a test message."""
        # logger.info("Testing Event Hub connectivity...")
        
        test_data = {
            "deviceId": "test-device",
            "timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
            "temperature": 25.5,
            "humidity": 60.2,
            "pressure": 1013.25,
            "location": {
                "lat": 47.6062,
                "lon": -122.3321
            },
            "metadata": {
                "sensorType": "DHT22",
                "firmware": "v1.2.3"
            }
        }
        
        success = self.send_message(test_data)
        if success:
            print("✓ Test message sent successfully! Event Hub is reachable.")
        else:
            print("✗ Test message failed!")
            
        return success
    
    def run_continuous_generation(self, interval_seconds: int = 5):
        """Run continuous data generation and sending."""
        # logger.info(f"Starting continuous data generation (every {interval_seconds} seconds)")
        # logger.info("Press Ctrl+C to stop...")
        
        try:
            while True:
                # Generate sample data
                sample_data = self.generate_telemetry_data()
                
                # Print the data
                print("\nSample telemetry data:")
                print(json.dumps(sample_data, indent=2))
                
                # Send to Event Hub
                self.send_message(sample_data)
                
                # Wait for next iteration
                time.sleep(interval_seconds)
                
        except KeyboardInterrupt:
            print("\n⏹️  Stopping data generation...")
        except Exception as e:
            logger.error(f"Error in continuous generation: {e}")
            raise

def main():
    """Main function to run the Event Hub data generator."""
    
    # Configuration (replace with your values)
    RESOURCE_GROUP = "rg-streamanalytics-workshop"
    NAMESPACE_NAME = "eventhub-sa-workshop-1234"
    EVENTHUB_NAME = "telemetry-data"
    SEND_INTERVAL = 5  # seconds
    
    print("Azure Event Hub Sample Data Generator")
    print("=" * 50)
    
    if not AZURE_LIBRARIES_AVAILABLE:
        print("❌ Azure libraries are not available. Please install them manually:")
        print("pip install azure-eventhub azure-identity azure-mgmt-eventhub")
        sys.exit(1)
    
    try:
        # Initialize the generator
        generator = EventHubDataGenerator(
            resource_group=RESOURCE_GROUP,
            namespace_name=NAMESPACE_NAME,
            eventhub_name=EVENTHUB_NAME
        )
        
        # Initialize producer
        generator.initialize_producer()
        
        # Test connectivity
        if not generator.test_connectivity():
            print("\n❌ Connectivity test failed. Please check your configuration:")
            print("1. Ensure your Azure credentials are set up (az login)")
            print(f"2. Verify resource group '{RESOURCE_GROUP}' exists")
            print(f"3. Verify Event Hub namespace '{NAMESPACE_NAME}' exists")
            print(f"4. Verify Event Hub '{EVENTHUB_NAME}' exists")
            print("5. Ensure you have proper permissions")
            print("\nAlternatively, set EVENTHUB_CONNECTION_STRING environment variable")
            sys.exit(1)
        
        print(f"\nStarting continuous data generation (every {SEND_INTERVAL} seconds)")
        print("Press Ctrl+C to stop...")
        
        # Start continuous generation
        generator.run_continuous_generation(SEND_INTERVAL)
        
    except Exception as e:
        logger.error(f"Application error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
