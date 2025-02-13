# Impacket-exe Installer

$PythonVersion = '3.13.0'
$StartingDirectory = Get-Location

$PythonInstallerPath = Join-Path -Path $Env:TEMP -ChildPath "python-$PythonVersion.exe"

$RepositoryArchivePath = Join-Path -Path $Env:TEMP -ChildPath "impacket-exe.zip"

$MachinePythonKey = "HKLM:\Software\Python\PythonCore"
$UserPythonKey = "HKCU:\Software\Python\PythonCore"
$FoundPython = $False

$PythonVersionParts = $PythonVersion.Split(".")
$TruncatedPythonVersion = "$($PythonVersionParts[0]).$($PythonVersionParts[1])"

$availableScripts = @{
    'DumpNTLMInfo'    = @{requiredModules = @() }
    'Get-GPPPassword' = @{requiredModules = @() }
    'GetADComputers'  = @{requiredModules = @() }
    'GetADUsers'      = @{requiredModules = @() }
    'GetLAPSPassword' = @{requiredModules = @() }
    'GetNPUsers'      = @{requiredModules = @() }
    'GetUserSPNs'     = @{requiredModules = @() }
    'addcomputer'     = @{requiredModules = @() }
    'atexec'          = @{requiredModules = @() }
    'changepasswd'    = @{requiredModules = @() }
    'dacledit'        = @{requiredModules = @() }
    'dcomexec'        = @{requiredModules = @() }
    'describeTicket'  = @{requiredModules = @() }
    'dpapi'           = @{requiredModules = @() }
    'esentutl'        = @{requiredModules = @() }
    'exchanger'       = @{requiredModules = @() }
    'findDelegation'  = @{requiredModules = @() }
    'getArch'         = @{requiredModules = @() }
    'getPac'          = @{requiredModules = @() }
    'getST'           = @{requiredModules = @() }
    'getTGT'          = @{requiredModules = @() }
    'goldenPac'       = @{requiredModules = @() }
    'karmaSMB'        = @{requiredModules = @() }
    'keylistattack'   = @{requiredModules = @() }
    'kintercept'      = @{requiredModules = @() }
    'lookupsid'       = @{requiredModules = @() }
    'machine_role'    = @{requiredModules = @() }
    'mimikatz'        = @{requiredModules = @() }
    'mqtt_check'      = @{requiredModules = @() }
    'mssqlclient'     = @{requiredModules = @() }
    'mssqlinstance'   = @{requiredModules = @() }
    'net'             = @{requiredModules = @() }
    'netview'         = @{requiredModules = @() }
    'ntfs-read'       = @{requiredModules = @() }
    'ntlmrelayx'      = @{requiredModules = @('ntlmrelayx') }
    'owneredit'       = @{requiredModules = @() }
    'ping'            = @{requiredModules = @() }
    'ping6'           = @{requiredModules = @() }
    'psexec'          = @{requiredModules = @() }
    'raiseChild'      = @{requiredModules = @() }
    'rbcd'            = @{requiredModules = @() }
    'rdp_check'       = @{requiredModules = @() }
    'reg'             = @{requiredModules = @() }
    'registry-read'   = @{requiredModules = @() }
    'rpcdump'         = @{requiredModules = @() }
    'rpcmap'          = @{requiredModules = @() }
    'sambaPipe'       = @{requiredModules = @() }
    'samrdump'        = @{requiredModules = @() }
    'secretsdump'     = @{requiredModules = @() }
    'services'        = @{requiredModules = @() }
    'smbclient'       = @{requiredModules = @() }
    'smbexec'         = @{requiredModules = @() }
    'smbserver'       = @{requiredModules = @() }
    'sniff'           = @{requiredModules = @('Npcap') }
    'sniffer'         = @{requiredModules = @() }
    'split'           = @{requiredModules = @('Npcap') }
    'ticketConverter' = @{requiredModules = @() }
    'ticketer'        = @{requiredModules = @() }
    'tstool'          = @{requiredModules = @() }
    'wmiexec'         = @{requiredModules = @() }
    'wmipersist'      = @{requiredModules = @() }
    'wmiquery'        = @{requiredModules = @() }
}

$SelectedScripts = New-Object System.Collections.Generic.HashSet[string]

$Options = New-object System.Collections.Hashtable
$Options['OutputDir'] = @{
    Name     = 'Output Directory'
    Desc     = 'Set the output directory for the built executable'
    Keywords = @('-o', '--output-dir')
    Value    = $StartingDirectory
    Type     = 'Path'
}
$Options['Branch'] = @{
    Name     = 'Repository Branch'
    Desc     = 'Set the branch of the repository to download from'
    Keywords = @('-b', '--branch')
    Value    = 'master'
    Type     = 'String'
}
$Options['Repository'] = @{
    Name     = 'Repository'
    Desc     = 'The Github repository to download from'
    Keywords = @('-r', '--repository')
    Value    = 'p0rtl6/impacket-exe'
    Type     = 'String'
}

$Flags = New-object System.Collections.Hashtable
$Flags['InstallAll'] = @{
    Name     = 'Install All Scripts'
    Desc     = 'Installs every script in the available scripts list'
    Keywords = @('-A', '--all')
    Value    = $False
}
$Flags['OverridePython'] = @{
    Name     = 'Override Installed Python'
    Desc     = "Install Python $PythonVersion even if an existing python version is installed"
    Keywords = @('-P', '--override-python')
    Value    = $False
}
$Flags['LeavePython'] = @{
    Name     = 'Leave Installed Python'
    Desc     = "If installed, do not uninstall Python $PythonVersion from the system"
    Keywords = @('-L', '--leave-python')
    Value    = $False
}
$Flags['InstallSystemWide'] = @{
    Name     = 'Install Scripts System-Wide'
    Desc     = 'Install scripts to C:\Program Files\ and add them to the PATH (Ignores Output Directory)'
    Keywords = @('-I', '--install-systemwide')
    Value    = $False
}
$Flags['InstallFromCurrentDir'] = @{
    Name     = 'Install From Current Directory'
    Desc     = 'Install scripts from the current directory instead of downloading from a URL'
    Keywords = @('-C', '--install-current-dir')
    Value    = $False
}

function GetKeyByKeyword {
    param (
        [hashtable]$HashTable,
        [string]$Keyword
    )
        
    foreach ($Key in $HashTable.Keys) {
        $Item = $HashTable[$Key]
        if ($Item.Keywords -contains $Keyword) {
            return $Key
        }
    }
    return $Null
}

$HelpMenuPadding = 25

function Show-HelpMenu {
    Write-Host '=== Impacket-exe Installer ==='
    Write-Host 'Downloads, builds, and installs scripts from the Impacket-exe repository'
    Write-Host ''
    Write-Host 'Usage: impacket-exe-installer.ps1 [FLAGS] [OPTIONS] [<scripts>]'
    Write-Host ''
    Write-Host 'Positional Arguments:'
    Write-Host "  $('<scripts>'.PadRight($HelpMenuPadding)) A space seperated list of scripts you want to install"
    Write-Host ''
    Write-Host 'Flags:'
    foreach ($Flag in $Flags.Values) {
        $FormattedKeywords = $Flag['Keywords'] -join '  '
        Write-Host "  $($FormattedKeywords.PadRight($HelpMenuPadding)) $($Flag['Desc']) (default: $($Flag['Value']))"
    }
    Write-Host ''
    Write-Host 'Options:'
    Write-Host "  $('-h  --help'.PadRight($HelpMenuPadding)) Display this menu"
    Write-Host "  $('-s  --list-scripts'.PadRight($HelpMenuPadding)) List available scripts"
    foreach ($Option in $Options.Values) {
        $FormattedKeywords = $Option['Keywords'] -join '  '
        Write-Host "  $($FormattedKeywords.PadRight($HelpMenuPadding)) $($Option['Desc']) (default: $($Option['Value']))"
    }
    Write-Host ''
}

function Show-Scripts {
    Write-Host 'Available Scripts:'
    foreach ($AvailableScript in $AvailableScripts.GetEnumerator()) {
        Write-Host "  $($AvailableScript.Key)"
    }
    Write-Host ''
}

if ($Args.Count -eq 0) {
    Show-HelpMenu
    exit 0
}

for ($I = 0; $I -lt $Args.Count; $I++) {
    if ($Args[$I] -eq '-h' -or $Args[$I] -eq '--help') {
        Show-HelpMenu
        exit 0
    }
    if ($Args[$I] -eq '-s' -or $Args[$I] -eq '--list-scripts') {
        Show-Scripts
        exit 0
    }
    elseif ($Args[$I].startsWith('-')) {
        $ArgParts = $Args[$I] -split '='
        $Keyword = $ArgParts[0]
        $Value = $Null

        $FlagsKey = GetKeyByKeyword -HashTable $Flags -Keyword $Keyword
        $OptionsKey = GetKeyByKeyword -HashTable $Options -Keyword $Keyword

        if ($ArgParts.Count -eq 2) {
            $Value = $ArgParts[1]
        }
        elseif ($ArgParts.Count -gt 1) {
            throw "Error in $($Options[$OptionsKey]['Name']): Multiple equals signs (Use -h or --help for help)"
        }

        if ($FlagsKey) {
            $Flags[$FlagsKey]['Value'] = $True
        }
        elseif ($OptionsKey) {
            if (-not $Value) {
                $I++
                $Value = $Args[$I]
            }
            if (-not $Value) {
                throw "Error in $($Options[$OptionsKey]['Name']): No value recieved (Use -h or --help for help)"
            }
            if ($Options[$OptionsKey]['type'] -eq 'Path' -and -not (Test-Path $Value)) {
                throw "Error in $($Options[$OptionsKey]['Name']): Path does not exist (Use -h or --help for help)"
            }
            $Options[$OptionsKey]['Value'] = $Value
        }
        else {
            throw "Error: Unrecognized argument (Use -h or --help for help)"
        }
    }
    elseif ($AvailableScripts.ContainsKey($Args[$I])) {
        $SelectedScripts.Add($Args[$I]) | Out-Null
    }
    else {
        throw "Error: Invalid script selected. (use -s or --list-scripts for a list of available scripts)"
    }
}

if ($Flags['InstallAll']['Value']) {
    foreach ($key in $AvailableScripts.Keys) {
        $SelectedScripts.Add($key) | Out-Null
    }
}

if ($SelectedScripts.Count -eq 0) {
    throw "Error: Must select at least one script to install (Use -h or --help for help)"
}

$ProgressPreference = 'SilentlyContinue'

# Check Local Machine Registry
if (Test-Path $MachinePythonKey) {
    Get-ChildItem $MachinePythonKey | ForEach-Object {
        if ($_.PSChildName -eq $TruncatedPythonVersion) {
            $FoundPython = $True
            Write-Host "Python $($_.PSChildName) found in Local Machine"
        }
    }
}

# Check Current User Registry
if (Test-Path $UserPythonKey) {
    Get-ChildItem $UserPythonKey | ForEach-Object {
        if ($_.PSChildName -eq $TruncatedPythonVersion) {
            $FoundPython = $True
            Write-Host "Python $($_.PSChildName) found in Current User"
        }
    }
}

# Download and install Python
if (-not $FoundPython -or $Flags['OverridePython']['Value']) {
    Write-Host "Python $PythonVersion is not installed, installing now..."
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-amd64.exe" -OutFile $PythonInstallerPath
    Start-Process $PythonInstallerPath -ArgumentList "/quiet PrependPath=1 Include_launcher=0" -Wait

    # Refresh PATH
    $Env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 
}

if (-not $Flags['InstallFromCurrentDir']['Value']) {
    # Set the source
    $RepositoryUrl = "https://github.com/$($Options['Repository']['Value'])/archive/refs/heads/$($Options['Branch']['Value']).zip"
    $RepositoryFolderPath = Join-Path -Path $Env:TEMP -ChildPath "impacket-exe-$($Options['Branch']['Value'])"

    # Download and unzip repository
    Write-Host 'Downloading repository...'
    Invoke-WebRequest -Uri $RepositoryUrl -OutFile $RepositoryArchivePath
    Expand-Archive -Path $RepositoryArchivePath -DestinationPath $Env:TEMP -Force
    Remove-Item $RepositoryArchivePath

    # Begin build process
    Write-Host 'Beginning build process...'
    Set-Location -Path $RepositoryFolderPath
} else {
    $RepositoryFolderPath = Get-Location
}

# Create and activate virtual environment
python -m venv .venv
.venv\Scripts\Activate.ps1

# Setup
pip install -r requirements.txt
python setup.py install

foreach ($Script in $SelectedScripts) {
    Write-Host "Building $Script..."
    
    # Run required modules Main
    $Arguments = @('--onefile')
    foreach ($ModuleName in $AvailableScripts[$Script]['RequiredModules']) {
        Write-Host "Running module $ModuleName"
        . "installer-modules\$ModuleName.ps1"

        $Argument = Main
        $Arguments += ($Argument)
    }

    if (Test-Path "example-requirements\$Script-requirements.txt") {
        pip install -r "example-requirements\$Script-requirements.txt"
    }
    
    pyinstaller $Arguments "examples\$Script.py"

    $BuiltScriptPath = Join-Path -Path $RepositoryFolderPath -ChildPath "dist\$Script.exe"

    if ($Flags['InstallSystemWide']['Value']) {
        # Prepare destination folder
        Write-Host 'Copying executable to Program Files...'
        New-Item -ItemType Directory -Path 'C:\Program Files\Impacket-exe' -Force

        # Copy built executable into program files
        Copy-Item -Path $BuiltScriptPath -Destination 'C:\Program Files\Impacket-exe' -Force
    }
    else {
        Copy-Item -Path $BuiltScriptPath -Destination $Options['OutputDir']['Value'] -Force
    }
}

if ($Flags['InstallSystemWide']['Value']) {
    # Get the current PATH environment variable
    Write-Host "Updating PATH..."
    $CurrentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    # Check if the path already exists in PATH
    if ($CurrentPath -notlike "*C:\Program Files\Impacket-exe*") {
        # Append the new path to the existing PATH variable
        $NewPath = $CurrentPath + ';' + 'C:\Program Files\Impacket-exe'
    
        # Set the new PATH variable
        [System.Environment]::SetEnvironmentVariable('Path', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    
        Write-Host 'Successfully added C:\Program Files\Impacket-exe to PATH.'
    }
    else {
        Write-Host 'C:\Program Files\Impacket-exe is already in PATH.'
    }
}

Write-Host 'Cleaning up...'

# Run required modules Cleanup
foreach ($Script in $SelectedScripts) {
    foreach ($ModuleName in $AvailableScripts[$Script]['RequiredModules']) {
        Write-Host "Cleaning up module $ModuleName..."
        . "installer-modules\$ModuleName.ps1"

        Cleanup
    }
}

deactivate
Set-Location -Path $StartingDirectory

if (-not $Flags['InstallFromCurrentDir']['Value']) {
    Remove-Item -Recurse -Force $RepositoryFolderPath
}

if (-not $Flags['LeavePython']['Value'] -and (-not $FoundPython -or $Flags['OverridePython']['Value'])) {
    Write-Host 'Uninstalling Python...'
    Start-Process $PythonInstallerPath -ArgumentList "/uninstall /quiet PrependPath=1" -Wait
}

Write-Host 'Done!'
