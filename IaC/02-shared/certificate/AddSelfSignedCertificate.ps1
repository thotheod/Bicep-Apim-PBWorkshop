
$appGatewayFQDN = "appgw.theolabs.gr"
$certificateName = "appgw-theolabs-gr"
$subjectName = "CN=$appGatewayFQDN"
$vaultName = "kv-apimpoc-NE-dev"

# you need to authenticate first
# Connect-AzAccount -SubscriptionId '0a52391c-0d81-434e-90b4-d04f5c670e8a'
# Set-AzKeyVaultAccessPolicy -VaultName $vaultName -UserPrincipalName "thotheod@microsoft.com" -PermissionsToSecrets get, list, set, delete -PermissionsToCertificates get, list, create, import

$policy = New-AzKeyVaultCertificatePolicy -SubjectName $subjectName -IssuerName Self -ValidityInMonths 12 -Verbose
        
# private key is added as a secret that can be retrieved in the ARM template
Add-AzKeyVaultCertificate -VaultName $vaultName -Name $certificateName -CertificatePolicy $policy -Verbose

$newCert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certificateName

# it takes a few seconds for KeyVault to finish
$tries = 0
do {
    Write-Host 'Waiting for certificate creation completion...'
    Start-Sleep -Seconds 10
    $operation = Get-AzKeyVaultCertificateOperation -VaultName $vaultName -Name $certificateName
    $tries++

    if ($operation.Status -eq 'failed')
    {
    throw 'Creating certificate $certificateName in vault $vaultName failed with error $($operation.ErrorMessage)'
    }

    if ($tries -gt 120)
    {
    throw 'Timed out waiting for creation of certificate $certificateName in vault $vaultName'
    }
} while ($operation.Status -ne 'completed')	