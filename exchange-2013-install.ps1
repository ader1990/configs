#ps1_sysnative
$charmName = 'win-mssql' 
$adminusername = "administrator"
$adminpassword = "Passw0rd"
$localAdminUsername = "adminlocal"
$localAdminPassword = 'Passw0rd'
$DatabaseName = "exchange-db"
setupPath = "X:\\mu_exchange_server_2013_x64_dvd_1112105.iso"
$domain = "CLOUDBASE11"
$OwaName = "cloudbase-exchange-2"
$tempFolder = "X:\\exchange\\"
$domainCtrlIp = "192.168.100.175"
$stateRegKey = "HKLM:\\Software\\Wow6432Node\\Cloudbase Solutions\\Juju\\" + $charmName + "\\RebootsRequired"

#Create local administrator to enable Active Directory Domain join:
function Create-Local-Admin($localAdminUsername, $localAdminPassword){
    juju-log.exe "Creating local administrator"
    $computer = [ADSI]"WinNT://$env:computername"
    $localAdmin = $Computer.Create("User", $localAdminUsername)
    $localAdmin.SetPassword($localAdminPassword)
    $localAdmin.SetInfo()
    ([ADSI]"WinNT://$env:computername/Administrators,group").Add("WinNT://$env:computername/$localAdminUsername")
}

function Set-Dns($interface, $dnsIp){
	Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses $dnsIp
}

function log($arg){
  write-host $arg
}

$iso = Mount-DiskImage -PassThru $setupPath
$isoSetupPath = (Get-Volume -DiskImage $iso).DriveLetter + ":\setup.exe"

Write-Host "Installing Exchange Server 2013"
if (!($env:userdomain -eq $domain))
{
New-Item -Path $stateRegKey -Force
Set-ItemProperty -Path $stateRegKey  -Name "RebootsRequired" -Value 2

Set-Dns 'Ethernet0' $domainCtrlIp
Create-Local-Admin $localAdminUsername $localAdminPassword 

#Join the Active Directory Domain
netdom join $env:computername /Domain:$domain /UserD:$adminusername /PasswordD:$adminpassword /UserO:$localAdminUsername /PasswordO:$localAdminPassword
if (!$?) {
throw "Failed to join Active Directory Domain."
}
Install-WindowsFeature RSAT-ADDS, AS-HTTP-Activation, Desktop-Experience, NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation

Set-ItemProperty -Path $stateRegKey  -Name "RebootsRequired" -Value 1

write-host 'finished first step'
exit 0
}
else
{
try{
$CountLogon = [int](Get-ItemProperty -Path $stateRegKey -Name RebootsRequired).RebootsRequired
if ($CountLogon -eq 1)
{
Start-Process -Wait "$temp\FilterPack64bit.exe" -ArgumentList "/quiet"
Start-Process -Wait "$temp\filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe" -ArgumentList "/quiet"
Start-Process -Wait "$temp\UcmaRuntimeSetup.exe" -ArgumentList "/quiet"
Start-Process  -Wait -FilePath $isoSetupPath -ArgumentList "/IAcceptExchangeServerLicenseTerms /ps"
if (!$?) {
log ($error[0] | out-string)
}
Start-Process  -Wait -FilePath $isoSetupPath -ArgumentList "/IAcceptExchangeServerLicenseTerms /p /on:$env:userdomain"
if (!$?) {
log ($error[0] | out-string)
}
Start-Process  -Wait -FilePath $isoSetupPath -ArgumentList "/IAcceptExchangeServerLicenseTerms /pd"
if (!$?) {
log ($error[0] | out-string)
}
Start-Process  -Wait -FilePath $isoSetupPath -ArgumentList "/IAcceptExchangeServerLicenseTerms /mode:install /InstallWindowsComponents /r:mb,ca /MdbName:$DatabaseName"
if (!$?) {
log ($error[0] | out-string)
}
log "Finished first step of the Exchange install."
Set-ItemProperty -Path $stateRegKey  -Name "RebootsRequired" -Value 0
}
else
{
log "Started last step of the Exchange install."
ADD-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
if (!$?) {
log "Failed adding snap-in"
}
$ExServer=hostname
$InternalName=$OwaName
$ExternalName=$OwaName
New-SendConnector -Internet -Name "MSExchange Send Connector$ExServer" -AddressSpaces "*"
if (!$?) {
log ($error[0] | out-string)
}
Get-WebservicesVirtualDirectory -Server $ExServer | Set-WebservicesVirtualDirectory -Confirm:$false -InternalURL https://$InternalName/EWS/Exchange.asmx -ExternalURL https://$externalName/EWS/Exchange.asmx -Force
if (!$?) {
log ($error[0] | out-string)
}
Get-OwaVirtualDirectory -Server $ExServer | Set-OwaVirtualDirectory -Confirm:$false -InternalURL https://$InternalName/owa -ExternalURL https://$ExternalName/owa 
if (!$?) {
log ($error[0] | out-string)
}
Get-ecpVirtualDirectory -Server $ExServer | Set-ecpVirtualDirectory -Confirm:$false -InternalURL https://$InternalName/ecp -ExternalURL https://$ExternalName/ecp
if (!$?) {
log ($error[0] | out-string)
}
Get-ActiveSyncVirtualDirectory -Server $ExServer | Set-ActiveSyncVirtualDirectory -Confirm:$false -InternalURL https://$InternalName/Microsoft-Server-ActiveSync -ExternalURL https://$ExternalName/Microsoft-Server-ActiveSync
if (!$?) {
log ($error[0] | out-string)
}
Get-OABVirtualDirectory -Server $ExServer | Set-OABVirtualDirectory -Confirm:$false -InternalUrl https://$InternalName/OAB -ExternalURL https://$ExternalName/OAB
if (!$?) {
log ($error[0] | out-string)
}
Set-ClientAccessServer -Confirm:$false $ExServer -AutodiscoverServiceInternalUri https://$internalName/Autodiscover/Autodiscover.xml
if (!$?) {
log ($error[0] | out-string)
}
Set-OutlookAnywhere -Confirm:$false -Identity "$ExServer\Rpc (Default Web Site)" -InternalHostname $internalName -ExternalHostName $ExternalName -InternalClientAuthenticationMethod ntlm -InternalClientsRequireSsl:$True -ExternalClientAuthenticationMethod Basic -ExternalClientsRequireSsl:$True
if (!$?) {
log ($error[0] | out-string)
}
iisreset
if (!$?) {
log ($error[0] | out-string)
}
}
}
catch {
log ($error[0] | out-string)
}
}

