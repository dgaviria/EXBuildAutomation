Install-Module AzureAD
Import-Module AzureAD

$currentFolder = $PSScriptRoot
$buildParamsPath = Join-Path -Path $PSScriptRoot -ChildPath "BuildParams.json"
$buildParams = Get-Content -Raw -Path $buildParamsPath | ConvertFrom-Json
$inputFile = $buildParams.CVSFile

$userName = $buildParams.AADAdminName
$password = $buildParams.AADAdminPassword

$secPassword = ConvertTo-SecureString $password -AsPlainText -Force

$creds = New-Object System.Management.Automation.PSCredential ($userName, $secPassword)
Connect-AzureAD -Credential $creds

$allUsers = Get-AzureADUser
$usageLocation = "US"

# Get these values from running Get-AzureADSubscribedSku
$licenseSKUName = "DEVELOPERPACK_E5"
$skuID = "c42b9cae-ea4f-4ab7-9717-81576235ccac"

ForEach ($currentUser in $allUsers ){
   If ($currentUser.CompanyName = "WWT") {
      $upn = $currentUser.UserPrincipalName
      Write-Output($currentUser.UserPrincipalName + " " + $currentUser.AssignedLicenses)
      Set-AzureADUser -ObjectId $upn -UsageLocation $usageLocation
      $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
      $license.SkuId = $skuID
      $licenseToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
      $licenseToAssign.AddLicenses = $license
      Set-AzureADUserLicense -ObjectId $upn -AssignedLicenses $licenseToAssign
   }
}

# $userUPN = "scurry@vmwareex.com"
# Get-AzureADSubscribedSku #| Select SkuPartNumber, SKUID
# Get-AzureADUser -ObjectID $userUPN | Select -ExpandProperty AssignedLicenses | Select SkuID 