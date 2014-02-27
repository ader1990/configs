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

#Centos 6.5 with LIS 3.5 drivers installed
$rootVhdPath = "C:\VM\root3.vhd"

$netAdapterVMSwitch = "external"
Create-Test-Vm $vmName $rootVhdPath $netAdapterVMSwitch 

$scsiVhdPath = "C:\VM\SCSITest3.VHDX"
$address = 10
Create-SCSI-Vhd $scsiVhdPath
Attach-SCSI-Disk  $vmName $address $scsiVhdPath

#if inside the linux vm we run "ls -lia /dev/s*", it will NOT show the attached scsi disk

#by attaching another scsi disk at the first address, both scsi disks will be visible inside the linx vm
#$address = 0
#$scsiVhdPath = "C:\VM\SCSITest4.VHDX"
#Create-SCSI-Vhd $scsiVhdPath
#Attach-SCSI-Disk  $vmName $address $scsiVhdPath

