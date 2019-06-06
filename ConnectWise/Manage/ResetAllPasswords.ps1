$APIURI = "https://na.myconnectwise.net/v4_6_release/apis/3.0/system/members?conditions=type/name='Employee' and inactiveFlag=false"
$APIMethod = "GET"

# Public Key
$PubKey = ""

# Private Key
$PriKey = ""

# Password everyone will be set to.
$Password = ''

# ConnectWise Manage Company ID
$CWCompanyID = ''

Write-host -NoNewline -ForegroundColor red "This script will reset all active employees ConnectWise Manage password to '$Password' Are you sure you want to continue? (Y/N)"
$Response = Read-Host
if ($Response -ne 'y') {Exit}


Write-host -ForegroundColor Red "Resetting all active employees ConnectWise Manage password to '$Password'"


# Authentication
$Authstring = '$CWCompanyID' + '+' + $PubKey + ':' + $PriKey
$encodedAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)))
$key = 'basic' + ' ' + $encodedAuth

$Members = Invoke-RestMethod -Uri $APIURI -Method $APIMethod -headers $Headers

$Headers = @{
    "Authorization" = "$key"
    "Content-Type"  = "application/json"
}


foreach ($ID in $Members.id) {
    $Body = @"
[
    {
        "op":"replace",
        "Path":"password",
        "Value":"$Password"
    }
]
"@
    $APIURI = "https://na.myconnectwise.net/v4_6_release/apis/3.0/system/members/$ID"
    Write-Host "Resetting "$Members.identifier" password to $Password"
    Invoke-RestMethod -Uri $APIURI -Method PATCH -headers $Headers -Body ($Body)
}