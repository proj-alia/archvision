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
function Add-Result([string]$Category, [string]$Id, [bool]$Passed, [string]$Detail = '') {
    $results.Add([ordered]@{ category=$Category; id=$Id; passed=$Passed; detail=$Detail })
}
function Read-Json([string]$RelativePath) {
    Get-Content -LiteralPath (Join-Path $RepositoryRoot $RelativePath) -Raw | ConvertFrom-Json -Depth 100
}
function Check-Schema([object]$Value, [string]$SchemaPath) {
    Test-ContractJson -Json (ConvertTo-Json -InputObject $Value -Depth 100 -Compress) -SchemaFile (Join-Path $RepositoryRoot $SchemaPath)
}
try {
    $suite = Read-Json 'tests/contracts/cases.json'
    foreach ($case in $suite.cases) {
        $actual = Check-Schema $case.data $case.schema
        Add-Result 'schema' $case.id ($actual -eq $case.expected_valid) "expected=$($case.expected_valid); actual=$actual"
    }
    $catalog = Read-Json 'schemas/catalog.json'
    $paths = @($catalog.entries.path)
    $actualPaths = @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'schemas') -Recurse -Filter '*.schema.json' | ForEach-Object { [IO.Path]::GetRelativePath($RepositoryRoot,$_.FullName).Replace('\','/') })
    Add-Result 'catalog' 'single-draft' ($catalog.design_status -eq 'draft' -and @($catalog.entries | Where-Object { $_.version -ne '1.0' }).Count -eq 0)
    Add-Result 'catalog' 'all-and-only-schemas' ((($paths | Sort-Object) -join ',') -ceq (($actualPaths | Sort-Object) -join ','))
    foreach ($entry in $catalog.entries) {
        Add-Result 'schema-coverage' $entry.path (@($suite.cases | Where-Object { $_.schema -eq $entry.path -and $_.expected_valid }).Count -gt 0)
    }
    $dynamic = Read-Json 'tests/contracts/dynamic-payload-cases.json'
    $contract = Read-Json $dynamic.contract_file
    $contractHash = (Get-FileHash -LiteralPath (Join-Path $RepositoryRoot $dynamic.contract_file) -Algorithm SHA256).Hash.ToLowerInvariant()
    Add-Result 'digest' 'service-bytes' ($contractHash -ceq $dynamic.schema_digest)
    foreach ($case in $dynamic.cases) {
        $members = if ($case.member_kind -eq 'method') { @($contract.methods) } else { @($contract.events) }
        $member = @($members | Where-Object { $_.name -eq $case.member_name })
        $valid = $false
        if ($member.Count -eq 1) {
            $payloadSchema = if ($case.member_kind -eq 'method') { $member[0].input_schema } else { $member[0].payload_schema }
            $valid = Test-ContractJson -Json (ConvertTo-Json -InputObject $case.payload -Depth 100 -Compress) -Schema (ConvertTo-Json -InputObject $payloadSchema -Depth 100 -Compress)
        }
        Add-Result 'dynamic-payload' $case.id ($valid -eq $case.expected_valid)
    }
    $digest = Read-Json 'tests/contracts/action-digest-example.json'
    $actionHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($digest.canonical_json))).ToLowerInvariant()
    Add-Result 'digest' 'fixed-action-canonical-bytes' ($actionHash -ceq $digest.sha256) 'Fixed JCS fixture only; no general canonicalizer or authorization service executed.'
    $action = $digest.canonical_json | ConvertFrom-Json -Depth 100
    Add-Result 'digest' 'action-shape' (Check-Schema $action 'schemas/core/action.schema.json')
    $authorizedSample = @($suite.cases | Where-Object { $_.schema -eq 'schemas/core/authorization.schema.json' -and $_.expected_valid })[0]
    Add-Result 'digest' 'authorization-reference' ($authorizedSample.data.action_digest -ceq $actionHash)
    # Every reference to the anonymous contract must identify its actual distributed bytes.
    foreach ($fixturePath in @('tests/contracts/cases.json','tests/contracts/anonymous-extension.json')) {
        $tree = Get-Content -LiteralPath (Join-Path $RepositoryRoot $fixturePath) -Raw | ConvertFrom-Json -AsHashtable -Depth 100
        $pending = [Collections.Generic.Stack[object]]::new(); $pending.Push($tree); $consistent=$true
        while ($pending.Count) {
            $item=$pending.Pop()
            if ($item -is [Collections.IDictionary]) {
                if ($item.Contains('contract_id') -and $item.contract_id -eq $contract.contract_id -and $item.Contains('schema_digest')) { $consistent=$consistent -and $item.schema_digest -ceq $contractHash }
                foreach ($value in $item.Values) { if ($null -ne $value) { $pending.Push($value) } }
            } elseif ($item -is [array]) { foreach ($value in $item) { if ($null -ne $value) { $pending.Push($value) } } }
        }
        Add-Result 'digest' $fixturePath $consistent
    }
    $anonymous = Read-Json 'tests/contracts/anonymous-extension.json'
    foreach ($pair in @(@('provider_manifest','manifest'),@('consumer_manifest','manifest'),@('service_contract','contract'))) {
        Add-Result 'anonymous-extension' $pair[0] (Check-Schema $anonymous.($pair[0]) ("schemas/extension/"+$pair[1]+'.schema.json'))
    }
    Add-Result 'anonymous-extension' 'honest-scope' (!$anonymous.runtime_executed -and !$anonymous.core_changes_allowed)
    $manifest = Read-Json 'config/technology-stack.json'
    Add-Result 'configuration' 'contract-selection' ($manifest.contract_versions.core -eq '1.0' -and $manifest.contract_versions.extension -eq '1.0')
    $persona = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'config/persona.example.yaml') -Raw
    $policy = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'config/cognitive-policy.example.yaml') -Raw
    Add-Result 'configuration' 'persona-identity' ($persona -match 'identity_id:\s*"identity-001"' -and $persona -match 'schema_version:\s*"1.0"')
    Add-Result 'configuration' 'policy-contracts' ($policy -match 'protocol_version:\s*"1.0"' -and $policy -match 'core_contract_version:\s*"1.0"')
    Add-Result 'configuration' 'initial-adapter-not-capability-limit' ($policy -match 'initial_delivery_adapter:\s*webui_text' -and $policy -match 'required_fake_contracts:\s*\[audio, visual, avatar, game, device\]')
    $coverage = Read-Json 'tests/design-coverage.json'
    foreach ($group in $coverage.groups) {
        $content = Get-Content -LiteralPath (Join-Path $RepositoryRoot $group.document) -Raw
        foreach ($marker in $group.markers) { Add-Result 'capability-reference' ($group.document+':'+$marker) ($content.Contains($marker)) 'Presence only; future behavior must be tested.' }
    }
    $documents = @((Join-Path $RepositoryRoot 'README.md'),(Join-Path $RepositoryRoot 'AGENTS.md'),(Join-Path $RepositoryRoot 'CLAUDE.md'),(Join-Path $RepositoryRoot 'schemas/README.md'),(Join-Path $RepositoryRoot 'goal/README.md'))
    $documents += @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'docs') -Recurse -File | Where-Object { $_.Extension -in @('.md','.txt','.html') } | ForEach-Object { $_.FullName })
    $technicalPatterns = 'individual_id|companion_id|alia_id|/v1/(individuals|companions)/|actor_kind\s*[:=]\s*["'']alia["'']'
    foreach ($document in $documents) {
        $content = Get-Content -LiteralPath $document -Raw
        $relative=[IO.Path]::GetRelativePath($RepositoryRoot,$document)
        Add-Result 'neutral-naming' $relative ($content -notmatch $technicalPatterns)
        foreach ($link in [regex]::Matches($content,'\[[^\]]*\]\(([^)]+)\)')) {
            $target=$link.Groups[1].Value.Trim('<','>')
            if ($target -match '^(https?:|mailto:|#)') { continue }
            $parts=$target.Split('#',2); $targetPath=Join-Path (Split-Path -Parent $document) ([Uri]::UnescapeDataString($parts[0]))
            Add-Result 'document-link' ($relative+' -> '+$target) (Test-Path -LiteralPath $targetPath) 'Local target existence; external URLs and fragments not executed.'
        }
    }
} catch { Add-Result 'checker' 'unexpected-error' $false ($_.Exception.Message+' '+$_.ScriptStackTrace) }
if (!$OutputDirectory) { $OutputDirectory=Join-Path ([IO.Path]::GetTempPath()) ('alia-design-checks/contracts-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')) }
[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$failed=@($results | Where-Object { !$_.passed })
$report=[ordered]@{
    recorded_at=[DateTime]::UtcNow.ToString('o'); powershell_version=$PSVersionTable.PSVersion.ToString(); status=$(if($failed.Count){'FAIL'}else{'PASS'}); total=$results.Count; failed=$failed.Count
    checks=$results.ToArray()
    limitations=@('Design structure and fixed digest samples only.','No runtime, authority, lifecycle, database, security or real-media execution.','Local document targets only; no browser or external source verification.')
}
$report | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'report.json') -Encoding utf8NoBOM
Write-Output ("{0}: {1} checks, {2} failed; {3}" -f $report.status,$report.total,$report.failed,$OutputDirectory)
foreach ($failure in $failed) { Write-Output ("  {0}/{1}: {2}" -f $failure.category,$failure.id,$failure.detail) }
if ($failed.Count) { exit 1 }
