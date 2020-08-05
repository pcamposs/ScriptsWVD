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
$disponibles=0
$encendidos=0
$Vms=@()
$SessionHosts | ForEach-Object{
    if($_.Status -eq "Unavailable")
    {
        $nombre=$_.Name.Split('/')[-1].Replace($domain,"")
        $disponibles++
        $Vms+=$nombre
    }
    elseif($_.Status -eq "Available" -and $_.AllowNewSession -eq $true) {
        $encendidos++
    }
}

if($Quantity -gt $encendidos){
    For ($i=0; $i -le ($disponibles-$Quantity); $i++) {
        $SessionHostName = $Vms[$i]+$dominio 
        $Vmname=$Vms[$i].ToString()
        #$SessionHostName="VM-0"
        $actualiza=Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$true
        $prende=Start-AzVM -ResourceGroupName $ResourceGroupName -Name $Vmname
        Write-Output "Starting $SessionHostName" 
    }
}
Write-Output "Detected $encendidos Running"
Write-Output "Detectad $disponibles Available to Start"
