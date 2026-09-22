# Seeds reset-password tokens for admin + user so api.http returns 200.
# Run BEFORE a demo whenever reset-password has been consumed (single-use) -> got 400.
$ErrorActionPreference = 'Stop'

$envFile = Join-Path $PSScriptRoot '..\.env'
if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match '^(POSTGRES_PASSWORD|POSTGRES_USER|POSTGRES_DB)=(.+)$' } | ForEach-Object {
        if ($_ -match '^(POSTGRES_(?:PASSWORD|USER|DB))=(.+)$') {
            Set-Variable -Name $matches[1] -Value $matches[2]
        }
    }
}

$container = '69-s1-db'
$adminToken = 'e5fc350a24aef7a8c50342e3df6b5d4bdf11b75d'
$userToken = '22952c04acca759ede1d44a45fe9ab2e8d8041f89f58706c76312c84a17ad9121dc3d11f4fd83fe48c8691931b96d1ba4f0b22b1e9cd0b87ca5a28ab07301e59'
$email = 'real922548@gmail.com'

$sql = "UPDATE admin_users SET reset_password_token = '$adminToken' WHERE email = '$email'; UPDATE up_users SET reset_password_token = '$userToken' WHERE email = '$email';"

$env:PGPASSWORD = $POSTGRES_PASSWORD
$sql | docker exec -i $container psql -U $POSTGRES_USER -d $POSTGRES_DB -X -v ON_ERROR_STOP=1

Write-Host 'Seeded reset tokens:'
Write-Host "  admin (resetPasswordToken): $adminToken"
Write-Host "  user   (code):              $userToken"
Write-Host 'Tokens in api.http now match the DB - click reset-password to get 200.'