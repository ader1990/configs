function Create-SCSI-Vhd([string]$scsiVhdPath){
    $vhdBytes = (100*1024*1024*1024)
    New-VHD $scsiVhdPath -SizeBytes $vhdBytes -Dynamic
}

function Create-Test-Vm([string]$vmName, [string]$rootVhdPath, [string]$netAdapterVMSwitch){
    $vmMemoryBytes = (1024*1024*1024)
    New-VM $vmName -MemoryStartupBytes $vmmemorybytes

    Set-Vm $vmName -ProcessorCount 4

    Add-VMHardDiskDrive $vmName -ControllerType IDE -Path $rootVhdPath
    Connect-VMNetworkAdapter $vmName -SwitchName $netAdapterVMSwitch
    Add-VMScsiController $vmName
    
    Start-Vm $vmName
}

function Attach-SCSI-Disk([string]$vmName, [int]$address, [string]$scsiVhdPath){
    Add-VMHardDiskDrive $vmName -ControllerType SCSI -ControllerLocation $address -Path $scsiVhdPath
}


$vmName = "SCSITest3"
$rootVhdPath = "C:\VM\root3.vhd"
$netAdapterVMSwitch = "external"
Create-Test-Vm $vmName $rootVhdPath $netAdapterVMSwitch 

$scsiVhdPath = "C:\VM\SCSITest3.VHDX"
$address = 10
Create-SCSI-Vhd $scsiVhdPath
Attach-SCSI-Disk  $vmName $address $scsiVhdPath

#if on linux vm is executed "ls -lia /dev/sd*", it will not show the attached scsi disk

#if the following commands are executed, both scsi disks will be shown 
#$address = 0
#$scsiVhdPath = "C:\VM\SCSITest4.VHDX"
#Create-SCSI-Vhd $scsiVhdPath
#Attach-SCSI-Disk  $vmName $address $scsiVhdPath

