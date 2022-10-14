#foundation: https://thesysadminchannel.com/get-azure-ad-last-login-date-and-sign-in-activity/
#progressbar: https://communary.net/2015/01/19/how-to-add-a-progress-bar-to-your-powershell-script/

$checkexg = Get-Organizationrelationship
if ($checkexg -ne $null){

#--------- select a batch
Write-host "Loading migration waves, please select a number to continue"

$services = Get-MigrationBatch
$menu = @{}
for ($i=1;$i -le $services.count; $i++) 
{ Write-Host "$i. $($services[$i-1].identity),$($services[$i-1].totalcount)" 
$menu.Add($i,($services[$i-1].name))}

[int]$ans = Read-Host 'Enter selection'
$selection = [string]$services[$ans-1].identity
Write-host "Selecting wave $selection"
$selectiontype = Get-migrationbatch -Identity $selection

Write-host "You selected $selectiontype" -backgroundcolor Cyan -ForegroundColor Black
$userlist = get-migrationuser -batchid $selection | select Identity

Pause



$checkconn = Get-AzureADAuditDirectoryLogs -top 1
If ($checkconn -ne $null){
Write-host "Connected to Azure AD Powershell, continuing" -BackgroundColor Cyan -ForegroundColor Black
$upnlist = $userlist
$outputfile = "$selection-usersignin.txt"

foreach ($User in $UPNList) {

$counter++
Write-Progress -Activity 'Processing Users' -CurrentOperation $user -PercentComplete (($counter / $UPNList.count) * 100)

$user1 = $($user.identity)
$arr = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$user1'" -Top 1 | select CreatedDateTime,  UserPrincipalName, IsInteractive, AppDisplayName, IpAddress, TokenIssuerType, @{Name = 'DeviceOS'; Expression = {$_.DeviceDetail.OperatingSystem}}
	If ($arr -ne $null){
	$arruser = $arr.userprincipalname
	$arrtime = $arr.createddatetime
	$arrout = "$arruser, $arrtime"
	$arrout | out-file $outputfile -append
	Write-host $arrout -backgroundcolor green -foregroundcolor black
	Clear-Variable $user1 -ErrorAction SilentlyContinue
	Clear-Variable $arr -ErrorAction SilentlyContinue
	Clear-Variable $arrout -ErrorAction SilentlyContinue}
	else
	{$arrout = "$user1, null"
	$arrout | out-file $outputfile -append
	write-host $arrout -backgroundcolor red -foregroundcolor white
	#we need to add an extra timeout so we dont get a 429 Too Many Requests
	Start-Sleep -Milliseconds 250}

Start-Sleep -Milliseconds 500
}
#let the user know they dont have a connection
}else{Write-host "You are not connected to AzureAD Powershell or do not have the AzureAD Preview module installed, please retry" -ForegroundColor Yellow}

}else{Write-host "You are not connected to Exchange Online Powershell, please retry" -ForegroundColor Yellow}
