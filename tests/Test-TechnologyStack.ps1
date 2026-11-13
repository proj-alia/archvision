#Requires -Version 7.6
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
. (Join-Path $PSScriptRoot 'Schema-Validation.ps1')
$results = [Collections.Generic.List[object]]::new()
function Add-StackResult([string]$Category, [string]$Id, [bool]$Passed, [string]$Detail = '') {
    $results.Add([ordered]@{ category = $Category; id = $Id; passed = $Passed; detail = $Detail })
}
function Read-StackJson([string]$Path) {
    Get-Content -LiteralPath (Join-Path $RepositoryRoot $Path) -Raw | ConvertFrom-Json -Depth 100
}

try {
    foreach ($scriptName in @('Schema-Validation.ps1','Test-Contracts.ps1','Test-TechnologyStack.ps1')) {
        $tokens = $null; $parseErrors = $null
        $null = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $scriptName), [ref]$tokens, [ref]$parseErrors)
        Add-StackResult 'powershell-syntax' $scriptName ($parseErrors.Count -eq 0) (($parseErrors | ForEach-Object { $_.Message }) -join '; ')
    }
    $manifest = Read-StackJson 'config/technology-stack.json'
    $schemaPath = Join-Path $RepositoryRoot 'config/technology-stack.schema.json'
    $fixture = Read-StackJson 'tests/technology-stack/cases.json'
    foreach ($case in $fixture.cases) {
        $candidate = $manifest | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable -Depth 100
        foreach ($mutation in $case.mutations) {
            $cursor = $candidate
            for ($index = 0; $index -lt $mutation.path.Count - 1; $index++) {
                $part = $mutation.path[$index]
                $cursor = if ($cursor -is [array]) { $cursor[[int]$part] } else { $cursor[$part] }
            }
            $key = $mutation.path[-1]
            if ($mutation.op -eq 'remove') { $null = $cursor.Remove($key) }
            elseif ($mutation.op -eq 'set') { $cursor[$key] = $mutation.value }
            else { throw "Unknown fixture mutation $($mutation.op)" }
        }
        $accepted = Test-ContractJson -Json (ConvertTo-Json -InputObject $candidate -Depth 100 -Compress) -SchemaFile $schemaPath
        Add-StackResult 'manifest-schema' $case.id ($accepted -eq $case.expected_valid) "expected=$($case.expected_valid); actual=$accepted"
    }
    $ids = @($manifest.components | ForEach-Object { $_.id })
    Add-StackResult 'version-selection' 'unique-components' (($ids | Sort-Object -Unique).Count -eq $ids.Count)
    foreach ($id in @('rust','node','postgresql','pgvector','cargo:tokio','cargo:axum','cargo:tower','cargo:tower-http','cargo:sqlx','cargo:serde','cargo:serde_json','cargo:jsonschema','cargo:tauri','cargo:wasmtime','cargo:wasmtime-wasi','cargo:tracing','cargo:tracing-subscriber','cargo:tracing-opentelemetry','cargo:opentelemetry','cargo:opentelemetry_sdk','cargo:opentelemetry-otlp','cargo:proptest','npm:react','npm:react-dom','npm:vite','npm:@vitejs/plugin-react','npm:typescript','npm:tailwindcss','npm:@tailwindcss/vite','npm:shadcn','npm:zustand','npm:@tanstack/react-router','npm:@tanstack/react-query','npm:@tauri-apps/api','npm:@tauri-apps/cli','npm:vitest','npm:@playwright/test','npm:pnpm')) {
        Add-StackResult 'version-selection' $id ($id -in $ids) 'Required by the approved stack; not an installed-package check.'
    }
    $rust = @($manifest.components | Where-Object { $_.id -eq 'rust' })[0]
    foreach ($component in $manifest.components) {
        Add-StackResult 'published-metadata' $component.id ($component.metadata_verified -and $component.source.StartsWith('https://')) 'Recorded official metadata; no live query or install in this checker.'
        if ($component.metadata.PSObject.Properties['yanked']) {
            Add-StackResult 'version-selection' ($component.id + '-not-yanked') (!$component.metadata.yanked)
        }
        if ($component.metadata.PSObject.Properties['rust_version'] -and $component.metadata.rust_version) {
            Add-StackResult 'declared-msrv' $component.id ([version]$rust.version -ge [version]$component.metadata.rust_version) 'Declared MSRV only; does not resolve features or transitive dependencies.'
        }
    }
    foreach ($name in @('tokio','axum','tower','tower-http','sqlx','tauri','wasmtime','wasmtime-wasi','react','react-dom')) {
        Add-StackResult 'domain-boundary' $name ($name -in $manifest.boundaries.domain_forbidden_dependencies)
    }
    foreach ($project in $manifest.reference_projects) {
        $pinned = $project.revision -match '^[a-f0-9]{40}$' -and @($project.sources).Count -eq @($project.manifest_paths).Count
        foreach ($source in $project.sources) { $pinned = $pinned -and $source.Contains('/blob/' + $project.revision + '/') }
        Add-StackResult 'research-snapshot' $project.name $pinned 'Pinned source manifests; not a product integration test.'
    }

    $ports = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'docs/05-STATE-CONTRACTS.md') -Raw
    foreach ($type in @('StateStore','PerceptionPort','ContextCompiler','DecisionEngine','PolicyEngine','MemoryStore','ExpressionPlanner','CapabilityRegistry','ActionExecutor','ModelProvider','Reducer')) {
        Add-StackResult 'boundary-spec' $type ($ports.Contains('| ' + $type + ' |')) 'Design operation boundary only; no Rust compilation.'
    }

    $matrix = Read-StackJson 'tests/technology-stack/differential-matrix.json'
    Add-StackResult 'differential-definition' 'execution-status' ($matrix.status -eq 'specified' -and !$matrix.rust_executed)
    foreach ($vector in $matrix.vectors) {
        $accepted = Test-ContractJson -Json $vector.json -Schema (ConvertTo-Json -InputObject $vector.schema -Depth 100 -Compress)
        Add-StackResult 'powershell-oracle' $vector.id ($accepted -eq $vector.expected_valid) "expected=$($vector.expected_valid); actual=$accepted; Rust side not run"
    }
}
catch { Add-StackResult 'checker' 'unexpected-error' $false $_.Exception.Message }

$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-technology-stack'
if (!$OutputDirectory) { $OutputDirectory = Join-Path ([IO.Path]::GetTempPath()) "alia-design-checks/$runId" }
[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$failed = @($results | Where-Object { !$_.passed })
$report = [ordered]@{
    run_id = $runId
    recorded_at = [DateTime]::UtcNow.ToString('o')
    powershell_version = $PSVersionTable.PSVersion.ToString()
    checker_sha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
    schema_validator_sha256 = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'Schema-Validation.ps1') -Algorithm SHA256).Hash.ToLowerInvariant()
    manifest_sha256 = (Get-FileHash -LiteralPath (Join-Path $RepositoryRoot 'config/technology-stack.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    status = $(if ($failed.Count) { 'FAIL' } else { 'PASS' })
    total = $results.Count
    failed = $failed.Count
    categories = @($results | Group-Object -Property { $_['category'] } | ForEach-Object { [ordered]@{ category = $_.Name; checks = $_.Count; failed = @($_.Group | Where-Object { !$_.passed }).Count } })
    checks = $results.ToArray()
    limitations = @('No Rust or frontend build or full dependency resolution run.', 'PowerShell oracle only; Rust differential remains specified.', 'No database initialization, desktop/platform, performance or runtime security test run.', 'Metadata existence is not compatibility evidence.')
}
$reportPath = Join-Path $OutputDirectory 'report.json'
$report | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $reportPath -Encoding utf8NoBOM
Write-Output ("{0}: {1} checks, {2} failed; {3}" -f $report.status, $report.total, $report.failed, $reportPath)
foreach ($failure in $failed) { Write-Output ("  {0}/{1}: {2}" -f $failure.category, $failure.id, $failure.detail) }
if ($failed.Count) { exit 1 }
