Disable-AzContextAutosave –Scope Process

$TenantID="72f988bf-86f1-41af-91ab-2d7cd011db47"
$dominio=".test.local"
$ResourceGroupName="WRD"
$HostPoolName="PoolW10"

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

$contexto=Set-AzContext -TenantId $TenantID

$SessionHosts = @(Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName)
$Cantidad=2
$checkdate = Get-Date
if($checkdate.DayOfWeek -eq "Saturday" -or $checkdate.DayOfWeek -eq "Sunday"){$Cantidad=1}
$disponibles=0
$encendidos=0
$Vms=@()
$SessionHosts | ForEach-Object{
    if($_.Status -eq "Unavailable")
    {
        $nombre=$_.Name.Split('/')[-1].Replace($dominio,"")
        $disponibles++
        $Vms+=$nombre
    }
    elseif($_.Status -eq "Available" -and $_.AllowNewSession -eq $true) {
        $encendidos++
    }
}

if($Cantidad -gt $encendidos){
    For ($i=0; $i -le ($disponibles-$cantidad); $i++) {
        $SessionHostName = $Vms[$i]+$dominio 
        $Vmname=$Vms[$i].ToString()
        #$SessionHostName="VM-0"
        $actualiza=Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$true
        $prende=Start-AzVM -ResourceGroupName $ResourceGroupName -Name $Vmname
       Write-Output "Encendiendo $SessionHostName" 
    }
}
Write-Output "Detectadas $encendidos Encendidas"
Write-Output "Detectadas $disponibles Disponibles para encender"
