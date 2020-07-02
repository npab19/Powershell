param (
    [Parameter(Mandatory=$false)] 
    [String]  $VMName = 'VM Name',
        
    [Parameter(Mandatory=$false)]
    [String] $ResourceGroupName = 'Resource Group Name',

    [Parameter(Mandatory=$false)] 
    [String] $ServiceName = 'Print Spooler'
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name AzureRunAsConnection

# Wrap authentication in retry logic for transient network failures
$logonAttempt = 0
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationId $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}

$AzureContext = Get-AzSubscription -SubscriptionId $connection.SubscriptionID


$Script = "`$Service = Get-Service -Name '$ServiceName'
Write-Output `$Service.status"

Out-File -FilePath .\Script.ps1 -InputObject $Script


Import-Module Az.Compute

$result = Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -Name $VMName -CommandId 'RunPowerShellScript' -ScriptPath '.\Script.ps1'

$status = $result.value[0].message

if ($status -eq 'Stopped') {
    Stop-AzVM -ResourceGroupName "$ResourceGroupName" -Name "$VMName" -force
    Write-Output "Stopping Server $VMName"
}



