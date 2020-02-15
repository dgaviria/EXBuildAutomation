# Builds AD Users with Manager Information

$currentFolder = $PSScriptRoot
$buildParamsPath = Join-Path -Path $PSScriptRoot -ChildPath "BuildParams.json"
$buildParams = Get-Content -Raw -Path $buildParamsPath | ConvertFrom-Json
$inputFile = $buildParams.CVSFile

$infilePath = Join-Path -Path $currentFolder -ChildPath $inputFile
$fileExists = Test-Path ($infilePath)
If ($fileExists -ne $true) {
    Write-Output ($infilePath + " not found")
    Exit(1000)
}

# Add an OU for the particular customer.  This will allow for less cleanup on the AD side, but moves the issue to getting the connectors correct.
$ouName = $buildParams.OU
$company = $buildParams.Company
$groupName = $buildParamsPath.GroupName
Write-Output $ouName
$ouPath = "OU=EmpExperience,DC=vmwareex,DC=com"
New-ADOrganizationalUnit -Name $ouName -DisplayName $ouName -City $buildParams.City -ProtectedFromAccidentalDeletion $false -Path $ouPath
$ouFilter = "(name=" + $ouName + ")"
$ouInfo = Get-ADOrganizationalUnit -LDAPFilter $ouFilter
# We need the DN to add the users to the correct OU.
$ouDistinguishedName = $ouInfo.DistinguishedName

# Create a group that can be used to add users to the UEM Console.
New-ADGroup -Name $groupName -Path $ouDistinguishedName -GroupCategory Security -GroupScope Global -DisplayName $groupName

# Two step process.  Just add the user in this step and add the manager in the next step.
$userData = Import-Csv -Path $infilePath -Delimiter "`t"
ForEach ($currentUser in $userData) {
    $firstName = $currentUser.'First Name'
    $lastName = $currentUser.'Last Name'
    $department = $currentUser.Department
    $employeeID = $currentUser.'Employee ID'
    $mobilePhone = $currentUser.'Mobile Phone'
    $title = $currentUser.Title
    $manager = $currentUser.'Manager Last Name'
    $displayName = $firstName + " " + $lastName
    $defaultPassword = ConvertTo-SecureString $buildParams.DefaultPassword -AsPlainText -Force 
    $usageLocation = "US"

    $samAccountName = $firstName.ToLower().SubString(0,1) + $lastName.ToLower()
    $emailAddress = $samAccountName + "@" + $buildParams.Domain

    New-ADUser -City $buildParams.City -Department $department -EmailAddress $emailAddress -EmployeeID $employeeID -Name $displayName -MobilePhone $mobilePhone `
            -Path $ouDistinguishedName -SamAccountName $samAccountName -Title $title -UserPrincipalName $emailAddress -DisplayName $displayName -CannotChangePassword $true `
            -ChangePasswordAtLogon $false -AccountPassword $defaultPassword -GivenName $firstName -Surname $lastName -Enabled $true -Company $company

    Set-ADUser $samAccountName -Replace @{c="US";co="UNITED STATES";countrycode=826}
    Add-ADGroupMember -Identity $groupName -Members $samAccountName

    Write-Output $firstName
}

# Cycle back through and add the manager if the manager field exists.
ForEach ($currentUser in $userData) {
    If ($currentUser.'Manager Last Name'.Length -gt 0) {
        $userInfo = $currentUser.'Last Name'
        $currentUserInfo = Get-ADUser -LDAPFilter "(sn=$userInfo)" -Properties SamAccountName
        $managerSN = $currentUser.'Manager Last Name'
        $managerInfo = Get-ADUser -LDAPFilter "(sn=$managerSN)" -Properties sAMAccountName
        Set-ADUser -Identity $currentUserInfo.SamAccountName -Manager $managerInfo.SamAccountName
    }
}