# HPE ProLiant Servers Disk and Storage Report Generation Tool

This PowerShell script facilitates the interaction with HPE ProLiant Servers' Integrated Lights-Out (ILO) API to generate reports on disk and storage units. It's designed to provide a straightforward method for collecting vital storage information, making it invaluable for administrators and IT professionals working with HPE ProLiant Servers.

## Prerequisites

- **PowerShell 5.1 or later**: Ensure you have the correct version of PowerShell installed.
- **Access to HPE ProLiant Servers ILO's API**: You must have network access to the server's ILO interface.
- **Valid ILO Credentials**: Credentials for accessing the HPE ILO interface are required.

## Features

- **Automated Logging**: Generates detailed logs for each script execution, aiding in troubleshooting and monitoring.
- **Credential Management**: Securely prompts for and stores credentials, simplifying repeated script executions.
- **Comprehensive Reporting**: Automatically generates detailed reports on disk and storage units, including health status and other critical metrics.

## Usage

1. **Administrator Privileges**: Start PowerShell as an administrator to ensure the script can execute all its commands without restrictions.

2. **Prepare `iLOInput.csv`**: Create a CSV file named `iLOInput.csv` in the same directory as the script. This file should contain columns for `IP`, with row representing a different HPE ProLiant Server ILO.

3. **Run the Script**: With PowerShell in the script's directory, execute the script. The script performs the following operations automatically:
   - Imports server details from `iLOInput.csv`.
   - Prompts for and stores credentials if they are not already saved.
   - Gathers and reports on disk and storage unit information from each server in the CSV.
   - Outputs detailed logs and generates reports in CSV format, storing them in `logs` and `report` directories within the script's root folder.

## Outputs

The script outputs its findings into two main types of files located in the `logs` and `report` directories:

- **Logs**: Detailed execution logs, including errors or warnings.
- **Reports**: CSV files with comprehensive data on the health and status of each disk and storage unit.

## Additional Information

- **Ensure Compatibility**: Make sure the script and the `iLOInput.csv` file are in the same directory. Also, ensure that the `logs` and `report` directories are present or the script will create them.

## Version Information

- **Company**: Hewlett Packard Enterprise
- **Author**: Emre Baykal, HPE Services
- **Version**: 1.0.0.0
- **Date**: 14/03/2024