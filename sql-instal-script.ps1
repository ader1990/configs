#ps1_sysnative
$mssqlServiceUsername = "mssql"
$mssqlServicePassword = "Passw0rd"
$mssqlAdminUsername = "mssqladmin"
$mssqlSaPassword = "Passw0rd"
$mssqlFeatures = "SQLENGINE,ADV_SSMS"
$mssqlInstanceName = "mssql"
$mssqlIsoPath = "X:\\en_sql_server_2012_standard_edition_with_sp1_x64_dvd_1228198.iso"

New-SmbMapping -LocalPath X: -RemotePath \\10.7.1.10\ISO

$iso = Mount-DiskImage -PassThru $mssqlIsoPath
$isoSetupPath = (Get-Volume -DiskImage $iso).DriveLetter + ":\setup.exe"

Write-Host "Installing Sql Server 2012"
NET USER $mssqlServiceUsername $mssqlServicePassword /ADD
$hostname = hostname
$PARAMS="/ACTION=install "
$PARAMS+="/Q " #full quiet mode - required by cloudbaseinit
$PARAMS+="/IACCEPTSQLSERVERLICENSETERMS=1 "
$PARAMS+="/INSTANCENAME=$mssqlInstanceName "
$PARAMS+="/FEATURES=$mssqlFeatures " #features enabled. Possible features are stated at http://technet.microsoft.com/en-us/library/ms144259.aspx#Feature
if ($adDomainName -ne "")
{
$PARAMS+="/SQLSYSADMINACCOUNTS=$adDomainName\$adDomainAdminUsername "
}
else
{
$PARAMS+="/SQLSYSADMINACCOUNTS=.\$mssqlAdminUsername "
}
$PARAMS+="/UpdateEnabled=1 "
$PARAMS+="/AGTSVCSTARTUPTYPE=Automatic "
$PARAMS+="/BROWSERSVCSTARTUPTYPE=Automatic "
$PARAMS+="/SECURITYMODE=SQL "
$PARAMS+="/SAPWD=$mssqlSaPassword "
$PARAMS+="/SQLSVCACCOUNT=.\$mssqlServiceUsername "
$PARAMS+="/SQLSVCPASSWORD=$mssqlServicePassword "
$PARAMS+="/SQLSVCSTARTUPTYPE=Automatic "
$PARAMS+="/NPENABLED=1 "
$PARAMS+="/TCPENABLED=1 /ERRORREPORTING=1"

Start-Process -Wait -FilePath $isoSetupPath -ArgumentList $PARAMS
if (!$?) {
throw "Failed to install MSSQL SERVER 2012."
}
else{
if ($domain -ne ""){
#Disable local admin account
$localAdmin.userflags = 2
$localAdmin.SetInfo()
}
#Unmount the sql server iso file
Dismount-DiskImage -ImagePath $mssqlIsoPath
winrm quickconfig -Force
netsh advfirewall firewall add rule name="Open Port 80" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow protocol=TCP localport=1433
netsh advfirewall firewall add rule name="SQL Admin Connection" dir=in action=allow protocol=TCP localport=1434
netsh advfirewall firewall add rule name="SQL Service Broker" dir=in action=allow protocol=TCP localport=4022
netsh advfirewall firewall add rule name="SQL Debugger/RPC" dir=in action=allow protocol=TCP localport=135
netsh advfirewall firewall add rule name="Analysis Services" dir=in action=allow protocol=TCP localport=2383
netsh advfirewall firewall add rule name="SQL Browser" dir=in action=allow protocol=TCP localport=2382
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="SSL" dir=in action=allow protocol=TCP localport=443
netsh advfirewall firewall add rule name="SQL Browser" dir=in action=allow protocol=UDP localport=1434
netsh firewall set multicastbroadcastresponse ENABLE
}
