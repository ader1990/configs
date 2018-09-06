param([string]$RefChange="refs/changes/19/597319/25")

$ErrorActionPreference = "Stop"

$homePath = Join-Path $env:HOMEDRIVE $env:HOMEPATH
$GitURL = "https://github.com/git-for-windows/git/releases/download/v2.18.0.windows.1/Git-2.18.0-64-bit.exe"
$CurlPath = "$homePath\Desktop\curl.exe"
$GitPath = "C:\Program Files\Git\bin\git.exe"

$NotepadURL = "https://notepad-plus-plus.org/repository/7.x/7.5.8/npp.7.5.8.Installer.exe"

$CloudbaseInitRepo = "https://github.com/openstack/cloudbase-init"
$CloudbaseInitRepoBranch = "master"
$CloudbaseInitPath = "$homePath\Desktop\cloudbase-init"
$CloudbaseInitInstallPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init"
$CloudbaseInitInstallPythonPath = "${CloudbaseInitInstallPath}\Python"
$CloudbaseInitInstallPythonPathCBS = "${CloudbaseInitInstallPythonPath}\Lib\site-packages\cloudbase*"

function Set-TLS12 {
    $basepath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2"
    $basepathClient = "$basepath\Client"
    $basepathServer = "$basepath\Server"

    New-Item -ItemType Directory -Path $basepath
    New-Item -ItemType Directory -Path $basepathClient
    New-Item -ItemType Directory -Path $basepathServer

    New-ItemProperty -Path $basepathServer -Name DisabledByDefault -Value 0 -PropertyType DWORD
    New-ItemProperty -Path $basepathServer -Name Enabled -Value 1 -PropertyType DWORD

    New-ItemProperty -Path $basepathClient -Name DisabledByDefault -Value 0 -PropertyType DWORD
    New-ItemProperty -Path $basepathClient -Name Enabled -Value 1 -PropertyType DWORD
}

function Install-Git {
    $gitDir =  Test-Path 'C:\Program Files\Git\'
    if ($gitDir -eq $False) {
        Write-Host "Downloading GIT..."
        $gitDownloadPath = "C:\Windows\Temp\git.exe"
        & $CurlPath -L $GitURL -o $gitDownloadPath
        Write-Host "Installing GIT"
        & $gitDownloadPath /VERYSILENT
        Start-Sleep -Seconds 20
        $env:Path += ";C:\Program Files\Git\bin\"
        Write-Host "Git Path: $env:Path"
    } else {
        Write-Host "Git is already installed"
    }

    $gitDir = Test-Path 'C:\Program Files\Git\'
    if ($gitDir -ne $True) { 
        Write-Error "Git could not be installed"
    } else {
        Write-Host "Git installed with success"
    }
}


function Install-NotepadPlusPlus {
    $notepadDir =  Test-Path 'C:\Program Files (x86)\Notepad++'
    if ($notepadDir -eq $False) {
        Write-Host "Downloading notepad..."
        $notepadDownloadPath = "C:\Windows\Temp\notepad.exe"
        & $CurlPath -L $NotepadURL -o $notepadDownloadPath
        Write-Host "Installing notepad"
        & "$notepadDownloadPath" /S
        Start-Sleep -Seconds 20
    } else {
        Write-Host "Notepad is already installed"
    }
}

function Install-CloudbaseInit {
    Stop-Service -Force cloudbase-init
    if (!(Test-Path $CloudbaseInitPath)) {
        Write-Host "Cloning cloudbase-init to $CloudbaseInitPath"
        & $GitPath clone -b $CloudbaseInitRepoBranch $CloudbaseInitRepo $CloudbaseInitPath
    } else {
        Write-Host "Folder $CloudbaseInitPath already exists"
    }

    pushd $CloudbaseInitPath
        git reset --hard
        git fetch
        git checkout $CloudbaseInitRepoBranch
        git reset --hard HEAD~20
        git pull origin $CloudbaseInitRepoBranch
        git fetch https://git.openstack.org/openstack/cloudbase-init ${RefChange}
        git checkout FETCH_HEAD
        $env:Path = $env:Path + ";$CloudbaseInitInstallPythonPath;${CloudbaseInitInstallPythonPath}\Scripts"
        Remove-Item -Force -Recurse $CloudbaseInitInstallPythonPathCBS
        python -m pip install -r requirements.txt
        python -m pip install .
    popd
}

function Wait-ForServiceToStop {
    $dateStart = Get-Date
    while($true) {
       if ((Get-Service "cloudbase-init").Status -ne "Running") {
           $dateStop = Get-Date
           $seconds = ($dateStop - $dateStart).TotalSeconds
           Write-Host "Cloudbase-Init ran for ${seconds} seconds"
           return
       } else {
           Write-Host "Cloudbase-Init is still running"
           Start-Sleep 5
       }
    }
}

function Run-CloudbaseInit {
    if (Test-Path "$CloudbaseInitInstallPath\Log") {
        Remove-Item -Force -Recurse "$CloudbaseInitInstallPath\Log\*"
        Remove-Item -Force -Recurse 'HKLM:\SOFTWARE\Cloudbase Solutions' -ErrorAction "SilentlyContinue"
        Restart-Service "Cloudbase-Init"
        Wait-ForServiceToStop
        notepad.exe "$CloudbaseInitInstallPath\Log\cloudbase-init.log"
    }
}


Install-Git
Install-NotepadPlusPlus

Install-CloudbaseInit
Run-CloudbaseInit