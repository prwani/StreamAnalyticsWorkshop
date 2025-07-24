#!/usr/bin/env python3
"""
Setup script for Azure Event Hub Python sample data generator.
Helps install dependencies and configure the environment.
"""

import subprocess
import sys
import os

def install_requirements():
    """Install required Python packages."""
    print("Installing required Python packages...")
    try:
        subprocess.check_call([
            sys.executable, "-m", "pip", "install", "-r", "requirements.txt"
        ])
        print("✓ Successfully installed all requirements")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Failed to install requirements: {e}")
        return False

def check_azure_cli():
    """Check if Azure CLI is installed and user is logged in."""
    print("Checking Azure CLI...")
    try:
        # Check if az command is available
        subprocess.check_call(
            ["az", "--version"], 
            stdout=subprocess.DEVNULL, 
            stderr=subprocess.DEVNULL
        )
        print("✓ Azure CLI is installed")
        
        # Check if user is logged in
        result = subprocess.run(
            ["az", "account", "show"],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✓ User is logged into Azure CLI")
            return True
        else:
            print("⚠️  User is not logged into Azure CLI")
            print("   Run 'az login' to authenticate")
            return False
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("⚠️  Azure CLI is not installed or not in PATH")
        print("   Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli")
        return False

def setup_environment():
    """Help user set up environment variables."""
    print("\nEnvironment Configuration:")
    print("-" * 30)
    
    conn_str = os.getenv('EVENTHUB_CONNECTION_STRING')
    if conn_str:
        print("✓ EVENTHUB_CONNECTION_STRING is set")
    else:
        print("⚠️  EVENTHUB_CONNECTION_STRING is not set")
        print("   You can set it using one of these methods:")
        print("   1. Set environment variable:")
        print("      Windows: set EVENTHUB_CONNECTION_STRING=your_connection_string")
        print("      Linux/Mac: export EVENTHUB_CONNECTION_STRING=your_connection_string")
        print("   2. Or the script will prompt you for it when running")

def main():
    """Main setup function."""
    print("Azure Event Hub Python Sample Data Generator Setup")
    print("=" * 60)
    
    success = True
    
    # Install requirements
    if not install_requirements():
        success = False
    
    print()
    
    # Check Azure CLI
    azure_cli_ok = check_azure_cli()
    if not azure_cli_ok:
        print("Note: Azure CLI is optional for the REST API version")
    
    print()
    
    # Setup environment
    setup_environment()
    
    print("\n" + "=" * 60)
    if success:
        print("✓ Setup completed!")
        print("\nNext steps:")
        print("1. If using Azure SDK version: Ensure you're logged into Azure CLI")
        print("2. If using REST API version: Set EVENTHUB_CONNECTION_STRING or provide it when prompted")
        print("3. Update the configuration in the Python scripts if needed:")
        print("   - RESOURCE_GROUP")
        print("   - NAMESPACE_NAME") 
        print("   - EVENTHUB_NAME")
        print("\nTo run:")
        print("   python generate_sample_data.py          # Azure SDK version")
        print("   python generate_sample_data_rest.py     # REST API version")
    else:
        print("⚠️  Setup completed with issues. Please resolve them before running the scripts.")

if __name__ == "__main__":
    main()
