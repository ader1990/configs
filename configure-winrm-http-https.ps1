$ErrorActionPreference = "Stop"

function Setup-WinRMHTTP {
    New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
    $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}")) 
    $connections = $networkListManager.GetNetworkConnections() 
    # Set network location to Private for all networks
    $connections | % {$_.GetNetwork().SetCategory(1)}
    winrm quickconfig -quiet
    cmd /s /c "winrm create winrm/config/Listener?Address=*+Transport=HTTP @{Hostname = ""$ENV:COMPUTERNAME""}"
    if ($LastExitCode) { Write-Host "Failed to setup WinRM HTTP listener" }

    & winrm set winrm/config/service `@`{AllowUnencrypted=`"true`"`}
    if ($LastExitCode) { throw "Failed to setup WinRM HTTP listener" }

    & winrm set winrm/config/service/auth `@`{Basic=`"true`"`}
    if ($LastExitCode) { throw "Failed to setup WinRM basic auth" }

    & netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
    if ($LastExitCode) { throw "Failed to setup WinRM HTTP firewall rules" }

    Setup-WinRMHTTPS

    Remove-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Force
    cmd /c 'sc config winrm start= auto'
}

function Setup-WinRMHTTPS {
    $pwd = ConvertTo-SecureString -String "Passw0rd" -Force -AsPlainText
    $certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $ENV:COMPUTERNAME
    $certificateThumprint = $certificate.Thumbprint

    & netsh advfirewall firewall add rule name="WinRM HTTPS" dir=in action=allow protocol=TCP localport=5986
    if ($LastExitCode) { throw "Failed to setup WinRM HTTPS firewall rules" }

    cmd /s /c "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname = ""$ENV:COMPUTERNAME"";CertificateThumbprint = ""$certificateThumprint""}"
    if ($LastExitCode) { throw "Failed to setup WinRM HTTPS" }
}

Setup-WinRMHTTP

