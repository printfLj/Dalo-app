$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$globalNodeModules = (& npm root -g | Select-Object -Last 1).Trim()
$firebaseCli = Join-Path $globalNodeModules 'firebase-tools/lib/bin/firebase.js'
if (-not (Test-Path -LiteralPath $firebaseCli)) {
  throw 'Install Firebase CLI globally first with: npm install -g firebase-tools'
}

$previousEmulators = @(
  Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -like '*cloud-firestore-emulator*' -and
    $_.CommandLine -like '*--port 8088*' -and
    $_.CommandLine -like '*demo-dalo-security*'
  } | ForEach-Object { $_.ProcessId }
)
$testExitCode = 1
Push-Location $repoRoot
try {
  & node $firebaseCli emulators:exec --only firestore --project demo-dalo-security `
    'node --test security-tests/firestore.rules.test.mjs'
  $testExitCode = $LASTEXITCODE
}
finally {
  # Firebase CLI can leave its Java emulator child running after SIGKILL on Windows.
  # Stop only emulator processes for this demo project that were not present before.
  $newEmulators = Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -like '*cloud-firestore-emulator*' -and
    $_.CommandLine -like '*--port 8088*' -and
    $_.CommandLine -like '*demo-dalo-security*' -and
    $_.ProcessId -notin $previousEmulators
  }
  foreach ($emulator in $newEmulators) {
    Stop-Process -Id $emulator.ProcessId -Force -ErrorAction SilentlyContinue
  }
  Pop-Location
}
exit $testExitCode
