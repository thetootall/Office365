### Code architecture by Chris Blackburn 
### updates and more at http://www.github.com/thetootall

#foundation: https://thesysadminchannel.com/get-azure-ad-last-login-date-and-sign-in-activity/
#progressbar: https://communary.net/2015/01/19/how-to-add-a-progress-bar-to-your-powershell-script/
#mfastatus: https://www.alitajran.com/export-office-365-users-mfa-status-with-powershell/
#future improvement - add a menu https://adamtheautomator.com/powershell-menu/

### Check for installed modules
#check for ExchangeOnlineManagement module
$verexg = get-installedmodule -Name ExchangeOnlineShell -MinimumVersion 2.0.3 -ErrorAction SilentlyContinue
If ($verexg -eq $null){
Write-Error "You do not have the Exchange Online Powershell installed. Please run install-module exchangeonlinemanagement to continue" -ErrorAction Stop}

#check for AzureADPreview module
$verexg = get-installedmodule -Name AzureADPreview -MinimumVersion 2.0.2.149 -ErrorAction SilentlyContinue
If ($verexg -eq $null){
Write-Error "You do not have the Exchange Online Powershell installed. Please run install-online azureadpreview to continue" -ErrorAction Stop}

#check for MSOnline module
$verexg = get-installedmodule -Name MSOnline -MinimumVersion 1.1.180 -ErrorAction SilentlyContinue
If ($verexg -eq $null){
Write-Error "You do not have the MSOnline Powershell installed. Please run install-module msonline to continue" -ErrorAction Stop}

### Check for loaded modules
#Connct to Exchange Online if Module Is Found
$checkexg = Get-Organizationrelationship
if ($checkexg -eq $null){Write-host "You are not connected to Exchange Online Powershell, logging in" -ForegroundColor Yellow
Connect-ExchangeOnline}else{Write-host "You are connected to Exchange Online Powershell, continuing...." -ForegroundColor Green }

$checkconn = Get-AzureADAuditDirectoryLogs -top 1
If ($checkconn -eq $null){

#let the user know they dont have a connection
Write-host "You are not connected to AzureAD Powershell or do not have the AzureAD Preview module installed, logging in" -ForegroundColor Yellow
Connect-AzureAD}else{Write-host "You are connected to Azure AD Powershell, continuing...." -ForegroundColor Green }

#Connct to Microsoft Online if Module Is Loaded
$checkmsol = Get-MsolCompanyInfo
if ($checkmsol -eq $null){Write-host "You are not connected to MSOnline Powershell, logging in" -ForegroundColor Yellow
Connect-MsolService}else{Write-host "You are connected to MSOnline Powershell, continuing...." -ForegroundColor Green }


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
#End the Exchange Migration Batch loop

Write-host "Connected to Azure AD Powershell, continuing" -BackgroundColor Cyan -ForegroundColor Black
$upnlist = $userlist
$outputfile = "$selection-usersignin.txt"

foreach ($User in $UPNList) {

$counter++
Write-Progress -Activity 'Processing Users' -CurrentOperation $user -PercentComplete (($counter / $UPNList.count) * 100)

$user1 = $($user.identity)

#process MFA state for user
$mfastate = Get-MsolUser -UserPrincipalName $user1
$mfainfo = $MFAState.StrongAuthenticationMethods | ?{$_.isdefault -eq $true}
If ($mfainfo -ne $null){
$mfamethod = $mfainfo.methodtype
}else{
$mfamethod = "<no mfa setup>"
}

#Find Activity Log
$arr = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$user1'" -Top 1 | select CreatedDateTime,  UserPrincipalName, IsInteractive, AppDisplayName, IpAddress, TokenIssuerType, @{Name = 'DeviceOS'; Expression = {$_.DeviceDetail.OperatingSystem}}
	If ($arr -ne $null){
	$arruser = $arr.userprincipalname
	$arrtime = $arr.createddatetime
	$arrout = "$arruser, $arrtime, $mfamethod"
	$arrout | out-file $outputfile -append
	Write-host $arrout -backgroundcolor green -foregroundcolor black}
	else
    #adding one more if/then for users who truly have no MFA setup
	{if($mfamethod -eq "<no mfa setup>"){
    $arrout = "$user1, null, $mfamethod"
	$arrout | out-file $outputfile -append
	write-host $arrout -backgroundcolor red -foregroundcolor white}else{
    $arrout = "$user1, null, $mfamethod"
	$arrout | out-file $outputfile -append
	write-host $arrout -backgroundcolor green -foregroundcolor black}
    #we need to add an extra timeout so we dont get a 429 Too Many Requests
    Start-Sleep -Milliseconds 1000}
    #end CSVLOOP

#add a sleep to avoid 429 Too Many Requests
Start-Sleep -Milliseconds 1000
Clear-Variable user1 -ErrorAction SilentlyContinue
Clear-Variable arr -ErrorAction SilentlyContinue
Clear-Variable arrout -ErrorAction SilentlyContinue
Clear-Variable mfamethod -ErrorAction SilentlyContinue
Clear-Variable mfainfo -ErrorAction SilentlyContinue
}
#End the AAD Userloop

