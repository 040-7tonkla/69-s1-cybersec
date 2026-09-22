# Runs the REAL forgot -> reset password flow for admin + user (single-use token)
# and verifies by logging in with the new password.
#   .\scripts\reset-demo.ps1                          # reset to current passwords (idempotent)
#   .\scripts\reset-demo.ps1 -AdminPassword 'NewPass' # change admin password to NewPass
param(
    [string]$AdminEmail    = 'real922548@gmail.com',
    [string]$AdminPassword = 'Tonkla25488',
    [string]$UserEmail     = 'real922548@gmail.com',
    [string]$UserPassword  = 'Tonkla2548'
)
$ErrorActionPreference = 'Stop'
$base = 'http://localhost:9091'

$envFile = Join-Path $PSScriptRoot '..\.env'
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^(POSTGRES_(?:PASSWORD|USER|DB))=(.+)$') { Set-Variable -Name $matches[1] -Value $matches[2] }
    }
}
$env:PGPASSWORD = $POSTGRES_PASSWORD

function Reset-One([string]$Cluster, [string]$Email, [string]$NewPassword) {
    $forgotUrl = if ($Cluster -eq 'user') { '/api/auth/forgot-password' } else { '/admin/forgot-password' }
    $resetUrl  = if ($Cluster -eq 'user') { '/api/auth/reset-password' } else { '/admin/reset-password' }
    $loginUrl  = if ($Cluster -eq 'user') { '/api/auth/local' } else { '/admin/login' }
    $table     = if ($Cluster -eq 'user') { 'up_users' } else { 'admin_users' }

    Invoke-WebRequest -Uri "$base$forgotUrl" -Method POST -Body (@{ email = $Email } | ConvertTo-Json) -ContentType 'application/json' -UseBasicParsing -TimeoutSec 120 | Out-Null
    $sql = "SELECT reset_password_token FROM $table WHERE email='$Email' ORDER BY id DESC LIMIT 1;"
    $token = ($sql | docker exec -i 69-s1-db psql -U $POSTGRES_USER -d $POSTGRES_DB -X -A -t).Trim()

    $body = if ($Cluster -eq 'user') {
        @{ code = $token; password = $NewPassword; passwordConfirmation = $NewPassword }
    } else {
        @{ resetPasswordToken = $token; password = $NewPassword }
    }
    $reset = Invoke-WebRequest -Uri "$base$resetUrl" -Method POST -Body ($body | ConvertTo-Json) -ContentType 'application/json' -UseBasicParsing -TimeoutSec 120

    $login = if ($Cluster -eq 'user') {
        @{ identifier = $Email; password = $NewPassword }
    } else {
        @{ email = $Email; password = $NewPassword; rememberMe = $false }
    }
    $auth = Invoke-WebRequest -Uri "$base$loginUrl" -Method POST -Body ($login | ConvertTo-Json) -ContentType 'application/json' -UseBasicParsing -TimeoutSec 120

    Write-Host ("{0,-6} forgot=OK reset={1} login-verify={2}" -f $Cluster, $reset.StatusCode, $auth.StatusCode)
}

Reset-One 'admin' $AdminEmail $AdminPassword
Reset-One 'user'  $UserEmail  $UserPassword
Write-Host 'Done. Password changed successfully (login-verify 200 = new password works).'