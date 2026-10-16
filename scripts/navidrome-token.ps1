# Prints the three navidrome_* lines for Home Assistant's secrets.yaml.
# The password is typed into a hidden prompt and never leaves this window; only md5(password + salt) is printed.
$user = Read-Host 'Navidrome username'
$sec = Read-Host 'Navidrome password' -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try { $pw = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }

$bytes = New-Object byte[] 8
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$salt = -join ($bytes | ForEach-Object { $_.ToString('x2') })
$token = -join ([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($pw + $salt)) | ForEach-Object { $_.ToString('x2') })
Remove-Variable pw

# Check the token against Navidrome before you paste anything
$q = "u=$([uri]::EscapeDataString($user))&t=$token&s=$salt&v=1.16.1&c=homeassistant&f=json"
$r = (Invoke-RestMethod "http://10.10.0.175:4533/rest/ping?$q").'subsonic-response'
if ($r.status -ne 'ok') { Write-Host "Navidrome rejected it: $($r.error.message)" -ForegroundColor Red; exit 1 }

Write-Host "Navidrome accepted the token. Replace the placeholder lines in secrets.yaml with:`n" -ForegroundColor Green
"navidrome_user: `"$user`""
"navidrome_salt: `"$salt`""
"navidrome_token: `"$token`""
