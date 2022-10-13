#https://thesysadminchannel.com/get-azure-ad-last-login-date-and-sign-in-activity/
#Import a CSV of migration waves to export a report of who has and has not logged in

Write-host "Be sure to run Connect-AzureAD first!!!"

$checkconn = Get-AzureADTenantDetail
If ($checkconn -ne $null){

$upnlist = Import-csv "wave6-output.csv"
$outputfile = "wave6-usersignin.txt"

foreach ($User in $UPNList) {
	$user1 = $($user.identity)
	Write-host "Processing $user1"
    	$arr = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$user1'" -Top 1 | select CreatedDateTime,  UserPrincipalName, IsInteractive, AppDisplayName, IpAddress, TokenIssuerType, @{Name = 'DeviceOS'; Expression = {$_.DeviceDetail.OperatingSystem}}
	If ($arr -ne $null){
	$arruser = $arr.userprincipalname
	$arrtime = $arr.createddatetime
	$arrout = "$arruser logged in at $arrtime"
	$arrout | Out-file $outputfile -append}else
	{$arr = "No signin found for $user1"
	$arr | Out-file $outputfile -append}
	Clear-Variable $user1
	Clear-Variable $arr
	Clear-Variable $arrout
	Start-Sleep -Milliseconds 250
}
#let the user
}else{Write-host "You are not connected to AzureAD, please retry" -ForegroundColor Yellow}
