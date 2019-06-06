$APIURI = "https://na.myconnectwise.net/v4_6_release/apis/3.0/system/ssoConfigurations/"
$APIMethod = "GET"
# Your public key
$PubKey = ""

# Your private key
$PriKey = ""

# The password you would like your account to be reset to.
$Password = ''

# Your ConnectWise company ID
$CWCompanyID = ''

# Authentication
$Authstring = "$CWCompanyID" + '+' + $PubKey + ':' + $PriKey
$encodedAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)))
$key = 'basic' + ' ' + $encodedAuth

# Warning message and a chance to back out.
Write-host -ForegroundColor red "***Please read this thoroughly***"
Write-host -ForegroundColor red "This will disable all SSO configurations! You will need to reset members accounts after running this."
Write-host -ForegroundColor red "This script will also reset your ConnectWise Manage password to '$Password' Are you sure you want to continue? (Y/N)"
Write-host -ForegroundColor red "Select your answer then press 'Enter'"
$Response = Read-Host
if ($Response -ne 'y') {Exit}

# Prompt for CW User
Write-host "Please type in your ConnectWise Manage username"
$CWUser = Read-Host

# Getting all SSO configuration's ID
Write-host -ForegroundColor green "Finding all SSO configurations"
$Response = Invoke-RestMethod -Uri $APIURI -Method $APIMethod -headers $Headers

# Disabling all SSO Configurations.
$Headers = @{
    "Authorization" = "$key"
    "Content-Type"  = "application/json"
}

$Body = @"
[
    {
        "op":"replace",
        "Path":"inactiveFlag",
        "Value":"true"
    }
]
"@


foreach ($ID in $Response.id) {
    Write-host -ForegroundColor Green "Disabling SSO ID $ID"
    $APIURI = "https://na.myconnectwise.net/v4_6_release/apis/3.0/system/ssoConfigurations/$ID"
    $null = Invoke-RestMethod -Uri $APIURI -Method PATCH -headers $Headers -Body ($Body)
}

# Getting members ID to reset their password.

$APIURI = "https://na.myconnectwise.net/v4_6_release/apis/3.0/system/members?conditions=identifier='$CWUser'"
$Members = Invoke-RestMethod -Uri $APIURI -Method GET -headers $Headers
$MemberID = $Members.id

# Resetting members password to $Password.
$Headers = @{
    "Authorization" = "$key"
    "Content-Type"  = "application/json"
}

$Body = @"
[
    {
        "op":"replace",
        "Path":"password",
        "Value":"$Password"
    }
]
"@

$APIURI = "https://na.myconnectwise.net/v4_6_release/apis/3.0/system/members/$MemberID"
Write-Host "Resetting "$CWUser" password to $Password"
$null = Invoke-RestMethod -Uri $APIURI -Method PATCH -headers $Headers -Body ($Body)