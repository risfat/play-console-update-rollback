param(
    [string]$InputAab = "app-release.aab",
    [string]$OutputAab = "rollback.aab",
    [string]$VersionCode = "122",
    [string]$VersionName = "1.0.8"
)

# --- Read signing config from key.properties ---
$props = @{}
Get-Content ".\key.properties" | ForEach-Object {
    if ($_ -match "^\s*([^=]+)=(.*)$") {
        $props[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$Keystore = $props["storeFile"]
$Alias = $props["keyAlias"]
$KeystorePassword = $props["storePassword"]
$KeyPassword = $props["keyPassword"]

if (-not (Test-Path $Keystore)) {
    Write-Error "Keystore file '$Keystore' not found."
    exit 1
}

# --- Tool check ---
function Check-Tool($tool) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "$tool not found in PATH. Please install or add to PATH."
        exit 1
    }
}
Check-Tool "java"
Check-Tool "jarsigner"
Check-Tool "zipalign"

# --- Temp work dir ---
$tempDir = "temp_aab"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# --- Unpack AAB ---
Write-Host "Unpacking $InputAab..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($InputAab, $tempDir)

# --- Locate manifest ---
$manifestXml = Join-Path $tempDir "base\manifest\AndroidManifest.xml"
$manifestPb  = Join-Path $tempDir "base\manifest\AndroidManifest.xml.pb"

if (Test-Path $manifestXml) {
    $manifestPath = $manifestXml
    $manifestType = "xml"
} elseif (Test-Path $manifestPb) {
    $manifestPath = $manifestPb
    $manifestType = "proto"
} else {
    Write-Error "No AndroidManifest found in unpacked AAB."
    exit 1
}

Write-Host "Found manifest: $manifestPath ($manifestType)"

# --- Patch manifest ---
if ($manifestType -eq "xml") {
    Write-Host "Patching XML manifest..."
    (Get-Content $manifestPath) `
        -replace 'android:versionCode="[0-9]+"', "android:versionCode=`"$VersionCode`"" `
        -replace 'android:versionName="[^"]+"', "android:versionName=`"$VersionName`"" `
        | Set-Content $manifestPath -Encoding utf8
} else {
    Write-Host "Proto manifest detected - requires android/manifest.proto (advanced)"
    Write-Error "Stopping: proto re-encode not configured yet on this system."
    exit 1
}

# --- Remove META-INF (old signatures) ---
$metaInf = Join-Path $tempDir "META-INF"
if (Test-Path $metaInf) { Remove-Item -Recurse -Force $metaInf }

# --- Repack AAB ---
Write-Host "Repacking..."
$tempZip = "$OutputAab.zip"
if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
Compress-Archive -Path "$tempDir\*" -DestinationPath $tempZip
Move-Item -Force $tempZip $OutputAab

# --- Align ---
$alignedAab = "aligned-$OutputAab"
Write-Host "Aligning with zipalign..."
& zipalign -f -p 4 $OutputAab $alignedAab

# --- Sign ---
Write-Host "Signing with jarsigner..."
& jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 `
  -keystore $Keystore `
  -storepass $KeystorePassword `
  -keypass $KeyPassword `
  $alignedAab $Alias

Write-Host "✅ Done. Output AAB: $alignedAab"
