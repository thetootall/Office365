#Establish a PowerShell session with Office 365. You'll be prompted for your Delegated Admin credentials
Connect-MsolService
$CSVpath = "UserLicenseReport.csv"
  
    $licensedUsers = Get-MsolUser -All | Where-Object {$_.islicensed}
  
    foreach ($user in $licensedUsers) {
        Write-Host "$($user.displayname)" -ForegroundColor Yellow  
        $licenses = $user.Licenses
        $licenseArray = $licenses | foreach-Object {$_.AccountSkuId}
        $licenseString = $licenseArray -join ", "
        Write-Host "$($user.displayname) has $licenseString" -ForegroundColor Blue
        $licensedSharedMailboxProperties = [pscustomobject][ordered]@{
            CustomerName      = $customer.Name
            DisplayName       = $user.DisplayName
            Licenses          = $licenseString
            TenantId          = $customer.TenantId
            UserPrincipalName = $user.UserPrincipalName
        }
        $licensedSharedMailboxProperties | Export-CSV -Path $CSVpath -Append -NoTypeInformation   
	}
