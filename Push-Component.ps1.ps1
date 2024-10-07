# Push-Component.ps1

# Check if the DattoRMM module is installed, and if not, install it
if (-not (Get-Module -ListAvailable -Name "DattoRMM")) {
    Write-Output "DattoRMM module not found. Installing..."
    try {
        Install-Module -Name DattoRMM -Force -Scope CurrentUser
        Write-Output "DattoRMM module installed successfully."
    }
    catch {
        Write-Output "Failed to install DattoRMM module: $_"
        return
    }
}

# Import the DattoRMM module
try {
    Import-Module -Name DattoRMM
    Write-Output "DattoRMM module imported successfully."
}
catch {
    Write-Output "Failed to import DattoRMM module: $_"
    return
}

Use your Datto RMM platform-specific URL:

# Datto RMM Platform:	Swagger URL
# Pinotage: https://pinotage-api.centrastage.net/api/swagger-ui/index.html
# Merlot: https://merlot-api.centrastage.net/api/swagger-ui/index.html
# Concord: https://concord-api.centrastage.net/api/swagger-ui/index.html
# Vidal: https://vidal-api.centrastage.net/api/swagger-ui/index.html
# Zinfandel: https://zinfandel-api.centrastage.net/api/swagger-ui/index.html
# Syrah: https://syrah-api.centrastage.net/api/swagger-ui/index.html

Set-DrmmApiParameters -Url "https://zinfandel-api.centrastage.net" -Key "" -SecretKey ""

# Function to run the script
function Run-DrmmQuickJob {

    # Step 1: Get all sites and sort them alphabetically
    $sites = Get-DrmmAccountSites | Sort-Object -Property name

    if ($sites.Count -eq 0) {
        Write-Output "No sites found."
        return
    }

    # Step 2: Display sites to the user for selection
    Write-Output "Please select a site to continue:"
    for ($i = 0; $i -lt $sites.Count; $i++) {
        Write-Output "$($i + 1). $($sites[$i].name)"
    }

    # Step 3: Get user input for site selection
    $selectedSiteIndex = Read-Host "Enter the number of the site you want to select"
    if ([int]::TryParse($selectedSiteIndex, [ref]$null) -and $selectedSiteIndex -gt 0 -and $selectedSiteIndex -le $sites.Count) {
        $selectedSite = $sites[$selectedSiteIndex - 1]
    } else {
        Write-Output "Invalid selection. Please run the script again and select a valid number."
        return
    }

    # Step 4: Get all devices for the selected site and sort them alphabetically by hostname
    $siteDevices = Get-DrmmSiteDevices -siteUid $selectedSite.uid | Sort-Object -Property hostname

    if ($siteDevices.Count -eq 0) {
        Write-Output "No devices found for the selected site."
        return
    }

    # Step 5: Display devices to the user for selection
    Write-Output "Please select a device to continue:"
    for ($i = 0; $i -lt $siteDevices.Count; $i++) {
        $lastSeenDate = [datetime]::FromFileTimeUtc($siteDevices[$i].lastSeen).ToString("yyyy-MM-dd HH:mm:ss")
        Write-Output "$($i + 1). Hostname: $($siteDevices[$i].hostname), Last Logged In User: $($siteDevices[$i].lastLoggedInUser), Last Seen: $lastSeenDate"
    }

    # Step 6: Get user input for device selection
    $selectedDeviceIndex = Read-Host "Enter the number of the device you want to select"
    if ([int]::TryParse($selectedDeviceIndex, [ref]$null) -and $selectedDeviceIndex -gt 0 -and $selectedDeviceIndex -le $siteDevices.Count) {
        $selectedDevice = $siteDevices[$selectedDeviceIndex - 1]
    } else {
        Write-Output "Invalid selection. Please run the script again and select a valid number."
        return
    }

    # Step 7: Display the selected device details
    Write-Output "You have selected device: Hostname - $($selectedDevice.hostname), Last Logged In User - $($selectedDevice.lastLoggedInUser)"

    # Step 8: Get all components and sort them alphabetically
    $components = Get-DrmmAccountComponents | Sort-Object -Property name

    if ($components.Count -eq 0) {
        Write-Output "No components found."
        return
    }

    # Step 9: Display all components to the user for selection
    Write-Output "Please select a component to continue:"
    for ($i = 0; $i -lt $components.Count; $i++) {
        Write-Output "$($i + 1). $($components[$i].name)"
    }

    # Step 10: Get user input for component selection
    while ($true) {
        $selectedComponentIndex = Read-Host "Enter the number of the component you want to select"

        # Initialize a variable for parsing
        $parsedIndex = 0

        # Attempt to parse the input as an integer
        if ([int]::TryParse($selectedComponentIndex, [ref]$parsedIndex)) {
            # Ensure the selection is within the valid range
            if ($parsedIndex -gt 0 -and $parsedIndex -le $components.Count) {
                $selectedComponent = $components[$parsedIndex - 1]
                break
            } else {
                Write-Output "Invalid selection. Please enter a number between 1 and $($components.Count)."
            }
        } else {
            Write-Output "Invalid input. Please enter a valid number."
        }
    }

    # Step 11: Auto-generate Job Name based on the selected device and component
    $jobName = "$($selectedDevice.hostname) - $($selectedComponent.name)"
    Write-Output "Auto-generated Job Name: $jobName"

    # Step 12: Get any required variables from the selected component
    $variables = @()
    foreach ($variable in $selectedComponent.variables) {
        $value = Read-Host "$($variable.name) ($($variable.description)) [Default: $($variable.defaultVal)]"
        if (-not [string]::IsNullOrEmpty($value)) {
            $variables += @{ name = $variable.name; value = $value }
        } else {
            $variables += @{ name = $variable.name; value = $variable.defaultVal }
        }
    }

    # Step 13: Run Set-DrmmDeviceQuickJob
    try {
        $jobResult = Set-DrmmDeviceQuickJob -DeviceUid $selectedDevice.uid -JobName $jobName -ComponentName $selectedComponent.name -Variables $variables

        # Attempt to extract jobUid from the nested response
        if ($jobResult -and $jobResult.job -and $jobResult.job.uid) {
            $jobUid = $jobResult.job.uid
            Write-Output "Quick Job Created Successfully. Job UID: $jobUid"
        } else {
            Write-Output "Warning: Job created successfully, but no job UID was returned. Please check the details and try again."
            return
        }
    }
    catch {
        Write-Output "Failed to create Quick Job: $_"
        return
    }

    # Step 14: Monitor the job status until it is done
    Write-Output "Monitoring job status..."
    while ($true) {
        try {
            $jobStatus = Get-DrmmJobStatus -jobUid $jobUid
            Write-Output "Current job status: $($jobStatus.status)"
        
            if ($jobStatus.status -eq 'Completed' -or $jobStatus.status -eq 'Failed') {
                Write-Output "Job has completed with status: $($jobStatus.status)"
                break
            }

            Start-Sleep -Seconds 30
        }
        catch {
            Write-Output "Failed to get job status: $_"
            break
        }
    }
}

# Run the function
Run-DrmmQuickJob