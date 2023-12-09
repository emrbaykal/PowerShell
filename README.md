# PowerShell Script for Simplivity Cluster Analysis in VMware vCenter Environment

## Overview

This PowerShell script is designed to analyze the status and health of Simplivity Cluster within a VMware environment for before upgrade process. It retrieves information about the hosts, checks various metrics, and generates a comprehensive report for administrators.

AUTHOR  : Emre Baykal HPE Services

## Features

- **Host Information:** Retrieves details about ESXi hosts, including connection state, power state, overall status, and resource usage.

- **Omnistack Host Information:** Gathers information specific to Omnistack hosts, such as model, version, upgrade state, disk state, and more.

- **Health Checks:** Performs checks for various factors, including host connectivity, upgrade status, disk health, software version compatibility, and hardware status.

- **Update Manager System Requirements Check:** Evaluates the operating system that Simplivity Update Manager run, installed Java version, and Microsoft .NET Framework version on the machine.

- **Detailed Reporting:** Generates a detailed report in both console output and a text file for further analysis.

## How to Use

1. **Prerequisites:**
   - Ensure you have PowerShell installed on the machine where the script will run.
   - PowerShell v5.1 or later
   - VMware PowerCLI module
   - HPESimpliVity module
   - Permissions to connect to the vCenter Server

2. **Execution:**
   - Run the script using a PowerShell console or script execution environment.
     ```powershell
     .\simplivity-pre-upgrade-check.ps1
     ```
   - If prompted, provide necessary authentication details for the vCenter Server.

4. **Output:**
   - The script will provide real-time console output.
   - A detailed report file (`SVT_HCluster.txt` by default) will be generated in the Reports directory.

## Script Sections

- **Host Analysis:** Analyzes the status and resource usage of ESXi hosts within the specified vCenter cluster.

- **Omnistack Host Analysis:** Gathers detailed information about each Omnistack host, including software, disk and etc status.

- **Update Manager System Requirements:** Checks the system requirements on the machine running the script, such as OS version, Java version, and .NET Framework version.

## Notes

- This script assumes connectivity to a VMware vCenter Server and proper authentication.
- Review the script output and generated report for actionable insights and potential issues.
- For more details and troubleshooting information, refer to the [full script documentation](https://github.com/emrbaykal/PowerShell/blob/main/README.md).

## Issues and Contributions

- If you encounter any issues or have suggestions for improvements, please [open an issue](https://github.com/emrbaykal/PowerShell/issues).
- Contributions are welcome! Feel free to fork the repository and submit pull requests.

## License

This script is licensed under the [Apache 2.0](LICENSE).
