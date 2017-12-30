Add-PSSnapin VmWare.Vimautomation.core
Connect-VIServer VMSERVERS #Connect to VM Server
$minfreespace = 10  #Minnimum freespace on VM before adding additional space
#$freespace = 5
$computers = import-csv LOCATIONOFCSV #location of machine list
foreach($computer in $computers)
{
    write-host $computer.name    
    $vm = Get-VM -Name $computer.name -ErrorAction SilentlyContinue | select Name, usedspaceGB, provisionedspaceGB  #Getting VM Object  
    $usedspace =$vm.UsedSpaceGB
    $provisionedspace =$vm.provisionedspaceGB
    $space = ($provisionedspace - $usedspace) #Calculating Space Variable
    $HD = (Get-HardDisk -VM $VM.name)[0]
    $HD.CapacityGB
    $NewCap = [decimal]::round(($HD.CapacityGB +10)) 
    $Dest = "\\" + $vm.Name + "\"+ "C$\temp"   #Placing the diskpart .bat in the C$temp location
    #Foreach ($VM in $computer.name)
    if ($space -lt $minfreespace)
    {
        if ($VM -eq $null)
        {
        $Space = 'VM Not Found'
        }
        Copy-Item "LOCATION OF DISKPART" -Destination $Dest -Force
        $HD | Set-HardDisk -CapacityGB $NewCap -Confirm:$false
        Invoke-VMScript -vm $vm.name -ScriptText "C:\windows\system32\diskpart.exe /s c:\temp\diskpart.txt" -ScriptType BAT #Executing created .bat file
        write-host $computer.name $space       
        $temp = New-Object pscustomobject -Property @{"computername" = $computer.name; "availablespace" = $space;} #Creating new array to export as csv
        $temp | export-csv DESIREDLOCATION -Append -NoTypeInformation

     }

       

 

}

 