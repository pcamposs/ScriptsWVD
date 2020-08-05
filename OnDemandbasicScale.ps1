Disable-AzContextAutosave –Scope Process

$TenantID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#Format .XXXX.XX
$domain=".test.local"
$ResourceGroupName="XXXX"
$HostPoolName="YYYY"

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

$context=Set-AzContext -TenantId $TenantID

$SessionHosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName)
$Quantity=2
$checkdate = Get-Date
if($checkdate.DayOfWeek -eq "Saturday" -or $checkdate.DayOfWeek -eq "Sunday"){$Quantity=1}
$Availables=0
$Runnings=0
$Vms=@()
$SessionHosts | ForEach-Object{
    if($_.Status -eq "Unavailable")
    {
        $ShortName=$_.Name.Split('/')[-1].Replace($domain,"")
        $Availables++
        $Vms+=$ShortName
    }
    elseif($_.Status -eq "Available" -and $_.AllowNewSession -eq $true) {
        $Runnings++
    }
}

if($Quantity -gt $Runnings){
    For ($i=0; $i -le ($Availables-$Quantity); $i++) {
        $SessionHostName = $Vms[$i]+$domain 
        $Vmname=$Vms[$i].ToString()
        #$SessionHostName="VM-0"
        $UpdateAllowNewSession=Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$true
        $StartVM=Start-AzVM -ResourceGroupName $ResourceGroupName -Name $Vmname
        Write-Output "Starting $SessionHostName" 
    }
}
Write-Output "Detected $Runnings Running"
Write-Output "Detectad $Availables Available to Start"
