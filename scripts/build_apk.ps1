$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$appDirectory = Join-Path $projectRoot 'dalo'
$sourceApk = Join-Path $appDirectory 'build\app\outputs\flutter-apk\app-debug.apk'
$outputDirectory = Join-Path $projectRoot 'output\apk'
$outputApk = Join-Path $outputDirectory 'Dalo.apk'

Push-Location $appDirectory
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }

    flutter build apk --debug
    if ($LASTEXITCODE -ne 0) { throw 'Flutter APK build failed.' }
} finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $sourceApk)) {
    throw "Flutter build succeeded but the APK was not found: $sourceApk"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceApk -Destination $outputApk -Force
Write-Host "Daló APK created: $outputApk"
