param (
    [switch]$forreal
)
if($cred -eq $null)
{
    $cred = Get-Credential
}
Import-Module #AD Powershell Module
Import-Module  #SCCM Powershell Module
$dc = NAMEOFYOURDC  #SCCM Data Collecto
Add-PSSnapin VmWare.Vimautomation.core
Connect-VIServer Servernae -cred $cred #Connect to VMServer
$computers = get-vm
write-host $computers.count
foreach ($computer in $computers)
{
    if ($forreal)
    {
        write-host ('I am checking computer {0}' -f $computer.name) -f gray
        $adobject = Get-ADComputer $computer.name -ErrorAction SilentlyContinue
        if($adobject -ne $null)
        {
            $lastLog = (Get-ADComputer $computer.name -prop LastLogonDate).LastLogonDate #If C: cannot be accessed uses AD property LastLogon
        }
        else
        {
            Write-Host '  AD Object does not exist'   
        }
        $adobject = $null #Reset AD Object to null
        $path = '\\{0}\c$\users' -f $computer.name; #last time user profile was accessed
        if(Test-path $path)
        {
            $date = (Get-ChildItem $path -directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime;
            Write-Host $date
            if(((get-date).addDays(-90)) -gt (get-date $date) -or ((get-date).AddDays(-120) -gt (get-date $lastLog)))
            {
                write-host $lastLog -f Cyan
                remove-vm $computer #Remove VM from VMware 
                write-host ('Removing from VMware {0}' -f $computer.name) -f gray
                Remove-ADComputer $computer.name -ErrorAction SilentlyContinue #RemoveADObject
                write-host ('Removing from AD {0}' -f $computer.name) -f gray
                Set-Location ST1:
                Remove-CMDevice -name $computer.name -ErrorAction SilentlyContinue #Remove SCCM Object
                write-host ('Removing from SCCM {0}' -f $computer.name) -f gray
            }
            else
            {
                write-host '  Machine is Okay'
            }
        }
        else
        {
            Write-Host ('Machine is powered off {0}' -f $computer.name)
        }      
    }
    else
    {
        write-host ('I am checking computer {0}' -f $computer.name) -f gray
        $adobject = Get-ADComputer $computer.name -ErrorAction SilentlyContinue
        if($adobject -ne $null)
        {
            $lastLog = (Get-ADComputer $computer.name -prop LastLogonDate).LastLogonDate #If C: cannot be accessed uses AD property LastLogon
        }
        else
        {
            Write-Host '  AD Object does not exist'   
        }
        $adobject = $null
        $path = '\\{0}\c$\users' -f $computer.name; #last time user profile was accessed
        if(Test-path $path)
        {
            $date = (get-childitem $path -directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime;
            Write-Host $date
            if(((get-date).addDays(-90)) -gt (get-date $date) -or ((get-date).AddDays(-120) -gt (get-date $lastLog)))
            {
                write-host $lastLog -f Cyan
                remove-vm $computer -WhatIf 
                write-host ('Removing from VMware {0}' -f $computer.name) -f gray
                Remove-ADComputer $computer.name -WhatIf -ErrorAction SilentlyContinue
                write-host ('Removing from AD {0}' -f $computer.name) -f gray
                set-location ST1:
                Remove-CMDevice -name $computer.name -WhatIf -ErrorAction SilentlyContinue
                write-host ('Removing from SCCM {0}' -f $computer.name) -f gray
            }
            else
            {
                write-host '  Machine is Okay'
            }
        }
        else
        {
            Write-Host ('Machine is powered off {0}' -f $computer.name)
        }
    }
}