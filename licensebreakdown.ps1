Connect-MsolService
$listGetMsolAccountSku = Get-MsolAccountSku | Select-Object -property AccountSkuId, ActiveUnits, ConsumedUnits    
$listGetMsolAccountSku | export-csv totalO365license.csv -NoTypeInformation 
                                                                                                                  
$CSVpath = "UserLicenseReport.csv"
  
    $licensedUsers = Get-MsolUser -All | Where-Object {$_.islicensed}
  
    foreach ($user in $licensedUsers) {
        Write-Host "$($user.displayname)" -ForegroundColor Yellow  
        $licenses = $user.Licenses
        $licenseArray = $licenses | foreach-Object {$_.AccountSkuId}
        $licenseString = $licenseArray -join ", "
        Write-Host "$($user.displayname) has $licenseString" -ForegroundColor Red
        $licensedSharedMailboxProperties = [pscustomobject][ordered]@{
            DisplayName       = $user.DisplayName
            Licenses          = $licenseString
            UserPrincipalName = $user.UserPrincipalName
        }
        $licensedSharedMailboxProperties | Export-CSV -Path $CSVpath -Append -NoTypeInformation   
}

Write-host "Export complete; please return UserLicenseReport.csv & totalO365license.csv to consultant" -ForegroundColor Yellow -BackgroundColor Black
