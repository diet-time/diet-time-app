param([string]$PostgresBin = 'C:\Program Files\PostgreSQL\18\bin', [int]$Port = 55489)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$apiRoot = Join-Path (Split-Path -Parent $workspace) 'diet-time-api'
$artifactsRoot = [IO.Path]::GetFullPath((Join-Path $workspace 'artifacts'))
$data = Join-Path $artifactsRoot ('performance-postgres-' + [Guid]::NewGuid().ToString('N'))
$reportDirectory = Join-Path $artifactsRoot 'performance'
New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
$oldConnection = $env:UPCOMING_MEALS_TEST_CONNECTION
$oldReport = $env:PERFORMANCE_REPORT_DIRECTORY
$started = $false
$testExit = 1
try {
    & (Join-Path $PostgresBin 'initdb.exe') -D $data -A trust -U postgres --no-locale --encoding=UTF8
    if ($LASTEXITCODE -ne 0) { throw 'Disposable PostgreSQL initialization failed' }
    & (Join-Path $PostgresBin 'pg_ctl.exe') -D $data -l (Join-Path $artifactsRoot 'performance-postgres.log') -o "-h 127.0.0.1 -p $Port" -w start
    if ($LASTEXITCODE -ne 0) { throw 'Disposable PostgreSQL startup failed' }
    $started = $true
    $env:UPCOMING_MEALS_TEST_CONNECTION = "Host=127.0.0.1;Port=$Port;Database=postgres;Username=postgres;Pooling=false"
    $env:PERFORMANCE_REPORT_DIRECTORY = $reportDirectory
    & dotnet test (Join-Path $apiRoot 'tests\DietTime.Meal.Api.IntegrationTests\DietTime.Meal.Api.IntegrationTests.csproj') --no-restore --filter 'FullyQualifiedName~Performance_dashboard|FullyQualifiedName~Pause_dashboard' --logger 'console;verbosity=normal' *> (Join-Path $artifactsRoot 'performance-api-tests.log')
    $testExit = $LASTEXITCODE
} finally {
    $canRemove = -not $started
    if ($started) {
        & (Join-Path $PostgresBin 'pg_ctl.exe') -D $data -m fast -w stop
        $canRemove = $LASTEXITCODE -eq 0
    }
    $env:UPCOMING_MEALS_TEST_CONNECTION = $oldConnection
    $env:PERFORMANCE_REPORT_DIRECTORY = $oldReport
    $resolvedData = [IO.Path]::GetFullPath($data)
    # Delete only this invocation's stopped cluster beneath the artifacts root.
    if ($canRemove -and $resolvedData.StartsWith($artifactsRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedData) -and -not (Test-Path -LiteralPath (Join-Path $resolvedData 'postmaster.pid'))) {
        Remove-Item -LiteralPath $resolvedData -Recurse -Force
    }
}
exit $testExit
