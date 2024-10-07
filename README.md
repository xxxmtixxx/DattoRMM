# Push-Component.ps1

## Overview
**Push-Component.ps1** is a PowerShell script designed to automate the process of deploying components using Datto RMM. The script is interactive, enabling users to select the desired site, device, and component for creating and running a quick job. 

## Features
- **Automatic Installation of DattoRMM Module**: The script checks if the DattoRMM PowerShell module is installed and installs it if needed.
- **Interactive Site, Device, and Component Selection**: Guides users through choosing the appropriate site, device, and component for the job.
- **Quick Job Creation and Monitoring**: Automatically creates a quick job based on the user selections and monitors its status until completion.

## Prerequisites
- **DattoRMM PowerShell Module**: The script checks for this module and installs it if it is not available.
- **PowerShell 5.1+**: Ensure PowerShell version 5.1 or newer is installed.

## Setup Instructions

1. **Install DattoRMM Module (if required)**:
    The script will check if the DattoRMM PowerShell module is installed. If not, it will install it automatically using:
    ```powershell
    Install-Module -Name DattoRMM -Force -Scope CurrentUser
    ```

2. **Import the DattoRMM Module**:
    After installation, the script imports the module to ensure that all Datto RMM cmdlets are available.

3. **API Setup**:
    Update the following line with your platform-specific Datto RMM API URL, API Key, and Secret Key for authentication:
    ```powershell
    Set-DrmmApiParameters -Url "<Platform Specific URL>" -Key "<Your API Key>" -SecretKey "<Your Secret Key>"
    ```
    Platform-specific URLs include:
    - **Pinotage**: `https://pinotage-api.centrastage.net/api/swagger-ui/index.html`
    - **Merlot**: `https://merlot-api.centrastage.net/api/swagger-ui/index.html`
    - **Concord**: `https://concord-api.centrastage.net/api/swagger-ui/index.html`
    - **Vidal**: `https://vidal-api.centrastage.net/api/swagger-ui/index.html`
    - **Zinfandel**: `https://zinfandel-api.centrastage.net/api/swagger-ui/index.html`
    - **Syrah**: `https://syrah-api.centrastage.net/api/swagger-ui/index.html`

## Script Workflow

### 1. **Site Selection**
- Retrieves a list of all available sites from Datto RMM and sorts them alphabetically.
- Prompts the user to select a site by entering the corresponding number.

### 2. **Device Selection**
- Fetches all devices under the selected site and sorts them alphabetically by hostname.
- Displays each device with details such as hostname, last logged-in user, and last seen timestamp.
- Prompts the user to select the device.

### 3. **Component Selection**
- Retrieves all available components and sorts them alphabetically.
- Prompts the user to select a component for the job by entering the corresponding number.

### 4. **Auto-Generate Job Name**
- Generates a job name using the selected device and component, e.g., "`<DeviceHostname> - <ComponentName>`".

### 5. **Variable Handling**
- Prompts the user to enter values for any required variables associated with the selected component.
- If no value is provided, the default value is used.

### 6. **Create the Quick Job**
- Creates the quick job using the Datto RMM API, and extracts the job UID if the job is successfully created.
- If successful, it displays the job UID and proceeds to monitor the status of the job.

### 7. **Monitor Job Status**
- Continuously polls the status of the created job every 30 seconds.
- Updates the user with the current job status until the job is either marked as **Completed** or **Failed**.

## Usage
To run the script, execute it in PowerShell. The interactive nature of the script will guide you through selecting the site, device, and component for deployment:

```powershell
.\Push-Component.ps1
```

This command will:
1. Install and import the **DattoRMM** module.
2. Set API parameters based on your platform and credentials.
3. Guide you through the interactive site, device, and component selection process.
4. Create the quick job and monitor it until completion.

## Example Output
- **Site Selection**: A list of all sites will be displayed, and the user will be prompted to choose.
- **Device and Component Selection**: Similarly, the script will guide the user through device and component selection.
- **Job Creation and Monitoring**: Once the job is created, the user will see status updates on the job every 30 seconds until completion.

## Notes
- **Job URL**: This script does **not** currently generate a URL for viewing the job in the Datto RMM web interface.
- The next iteration of this script aims to improve by capturing more job details, including a link to access the job results.

## Contributing
Feel free to fork and contribute to this script to extend its functionality or improve user interaction.
