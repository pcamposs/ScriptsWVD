
Disable-AzContextAutosave –Scope Process

## V 0.03-t

Param 
    (    
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $domain, 
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $ResourceGroupName, 
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $HostPoolName 
    ) 

#Format .XXXX.XX
#$domain=".test.local"
#$ResourceGroupName="XXXX"
#$HostPoolName="YYYY"

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Get the list of Session host of the pool 
$SessionHosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName)
#How many Vms I want to be running at Schedule 
# If there is 1 VM Running, the script Will Start 1 VM to reach The $Quantity
$Quantity=2

#Different Quantity for weekend due the low usage 
$checkdate = Get-Date
if($checkdate.DayOfWeek -eq "Saturday" -or $checkdate.DayOfWeek -eq "Sunday"){
    $Quantity=1
}

$Availables=0
$Runnings=0
$Vms=@()

$SessionHosts | ForEach-Object{
    if($_.Status -eq "Unavailable")
    {
        $ShortName=$_.Name.Split('/')[-1].Replace($domain,"")
        #Validate the VM Status 
        $VmStatus=Get-AzVM -ResourceGroupName $ResourceGroupName -Name $ShortName -Status
        if($VmStatus.Statuses[1].DisplayStatus -eq "VM deallocated" -and $VmStatus.Statuses[0].DisplayStatus -eq "Provisioning succeeded"){
            $Availables++
            # Arrays of Vms in State Unavailable And (Stop Deallocated)
            $Vms+=$ShortName
        }
    }
    elseif($_.Status -eq "Available" -and $_.AllowNewSession -eq $true) {
        $Runnings++
    }
}
Write-Output "Detected $Runnings Running"
Write-Output "Detected $Availables Available to Start"
Write-Output "I Will Start $($Quantity-$Runnings) VMS"
if($Quantity -gt $Runnings){
    For ($i=0; $i -lt ($Quantity-$Runnings); $i++) {
        $SessionHostName = $Vms[$i]+$domain 
        $Vmname=$Vms[$i].ToString()
        #$SessionHostName="VM-0"
        $UpdateAllowNewSession=Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$true
        $StartVM=Start-AzVM -ResourceGroupName $ResourceGroupName -Name $Vmname
        Write-Output "Starting $SessionHostName" 
    }
}