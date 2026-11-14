#Requires -Version 7.6
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
. (Join-Path $PSScriptRoot 'Schema-Validation.ps1')
. (Join-Path $PSScriptRoot 'Aeip-Checks.ps1')
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
function Same-Json([object]$Left, [object]$Right) {
    # Authored fragments preserve property order; this is a fixture comparison, not JCS.
    (ConvertTo-Json -InputObject $Left -Depth 100 -Compress) -ceq (ConvertTo-Json -InputObject $Right -Depth 100 -Compress)
}
function Test-ConnectorLinks([object]$Definition, [object]$Package) {
    # Static package relationships only; this does not authorize runtime calls.
    $minimum = if ($null -eq $Definition.required_features) { @($Definition.features) } else { @($Definition.required_features) }
    if (@($minimum | Where-Object { $_ -cnotin $Definition.features }).Count) { return $false }
    $seen=@{}
    foreach ($dependency in $Definition.connection_dependents) {
        if ($seen.ContainsKey($dependency.contribution_id)) { return $false }
        $seen[$dependency.contribution_id]=$true
        $contribution=@($Package.contributions | Where-Object { $_.contribution_id -ceq $dependency.contribution_id })
        if ($contribution.Count -ne 1 -or $contribution[0].type_id -eq 'alia.contribution.connector') { return $false }
        if (@($dependency.required_features).Count -eq 0 -or @($dependency.required_features | Where-Object { $_ -cnotin $Definition.features }).Count) { return $false }
        $reference=$contribution[0].contract_ref
        if (@($Package.provides | Where-Object { $_.contract_id -ceq $reference.contract_id -and $_.version -ceq $reference.version -and $_.schema_digest -ceq $reference.schema_digest }).Count -ne 1) { return $false }
    }
    return $true
}
function Check-PayloadCases([object[]]$Cases, [hashtable]$Services, [string]$Category) {
    Add-Result $Category 'unique-case-ids' (@($Cases.id | Sort-Object -Unique).Count -eq $Cases.Count)
    foreach ($case in $Cases) {
        $service = $Services[$case.contract_id]
        $members = switch ($case.member_kind) { 'method' { $service.methods }; 'event' { $service.events }; 'stream' { $service.streams } }
        $member = @($members | Where-Object { $_.name -eq $case.member_name })
        $allowedSlots = switch ($case.member_kind) { 'method' { 'input_schema'; 'output_schema' }; 'event' { 'payload_schema' }; 'stream' { 'item_schema' } }
        $resolved = $null -ne $service -and $member.Count -eq 1 -and $case.schema_slot -in $allowedSlots
        Add-Result $Category ($case.id+':member') $resolved
        $valid = $false
        if ($resolved) {
            # Each embedded payload schema is its own root, including its local $defs.
            $valid = Test-ContractJson -Json (ConvertTo-Json -InputObject $case.payload -Depth 100 -Compress) -Schema (ConvertTo-Json -InputObject $member[0].($case.schema_slot) -Depth 100 -Compress)
        }
        Add-Result $Category $case.id ($valid -eq $case.expected_valid)
    }
}
try {
    $suite = Read-Json 'tests/contracts/cases.json'
    Add-Result 'schema' 'unique-case-ids' (@($suite.cases.id | Sort-Object -Unique).Count -eq $suite.cases.Count)
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
    $services = @{}
    $serviceHashes = @{}
    $servicePaths=@(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'schemas/services') -Filter '*.contract.json' -File | ForEach-Object { [IO.Path]::GetRelativePath($RepositoryRoot,$_.FullName).Replace('\','/') })
    Add-Result 'service-catalog' 'all-and-only-standard-services' ((($catalog.service_contracts.path | Sort-Object) -join ',') -ceq (($servicePaths | Sort-Object) -join ','))
    foreach ($entry in $catalog.service_contracts) {
        $service = Read-Json $entry.path
        $hash = (Get-FileHash -LiteralPath (Join-Path $RepositoryRoot $entry.path) -Algorithm SHA256).Hash.ToLowerInvariant()
        Add-Result 'service-catalog' ($entry.contract_id+':unique') (!$services.ContainsKey($entry.contract_id))
        Add-Result 'service-catalog' $entry.contract_id ($service.contract_id -ceq $entry.contract_id -and $service.version -ceq $entry.version -and $hash -ceq $entry.schema_digest)
        Add-Result 'service-shape' $entry.contract_id (Check-Schema $service 'schemas/extension/contract.schema.json')
        $services[$entry.contract_id]=$service; $serviceHashes[$entry.contract_id]=$hash
    }
    $connectors = Read-Json 'tests/contracts/connector-cases.json'
    Add-Result 'connector' 'honest-scope' (!$connectors.runtime_executed -and !$connectors.core_changes_allowed_for_new_platform)
    $dependencyOwners=@{}
    foreach ($example in $connectors.examples) {
        $package = Read-Json $example.manifest
        $definition = Read-Json $example.definition
        $instance = Read-Json $example.instance
        foreach ($pair in @(@($package,'manifest'),@($definition,'connector-definition'),@($instance,'connector-instance'))) {
            Add-Result 'connector-shape' ($example.id+':'+$pair[1]) (Check-Schema $pair[0] ('schemas/extension/'+$pair[1]+'.schema.json'))
        }
        $definitionHash = (Get-FileHash -LiteralPath (Join-Path $RepositoryRoot $example.definition) -Algorithm SHA256).Hash.ToLowerInvariant()
        $contributions = @($package.contributions | Where-Object { $_.type_id -eq 'alia.contribution.connector' })
        Add-Result 'connector' ($example.id+':one-contribution') ($contributions.Count -eq 1)
        if ($contributions.Count -eq 1) {
            $descriptor = $contributions[0].descriptor_ref
            $resolvedPath = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent (Join-Path $RepositoryRoot $example.manifest)) $descriptor.path))
            Add-Result 'connector' ($example.id+':descriptor') ($descriptor.sha256 -ceq $definitionHash -and $resolvedPath -ceq [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $example.definition)))
        }
        Add-Result 'connector' ($example.id+':definition-reference') ($instance.definition_ref.definition_id -ceq $definition.definition_id -and $instance.definition_ref.version -ceq $definition.version -and $instance.definition_ref.sha256 -ceq $definitionHash -and $instance.extension_id -ceq $package.extension_id -and $instance.configuration_version -ceq $definition.configuration_version)
        Add-Result 'connector' ($example.id+':configuration') (Test-ContractJson -Json (ConvertTo-Json -InputObject $instance.config -Depth 100 -Compress) -Schema (ConvertTo-Json -InputObject $definition.configuration_schema -Depth 100 -Compress))
        Add-Result 'connector' ($example.id+':dependency-links') (Test-ConnectorLinks $definition $package)
        foreach ($dependency in $definition.connection_dependents) {
            $key=$instance.installation_id+':'+$dependency.contribution_id
            $owner=$definition.definition_id+':'+$definition.version
            Add-Result 'connector' ($example.id+':owner:'+ $dependency.contribution_id) (!$dependencyOwners.ContainsKey($key) -or $dependencyOwners[$key] -ceq $owner)
            $dependencyOwners[$key]=$owner
        }
        foreach ($key in @('management_contract','interaction_contract','setup_contract')) {
            $reference=$definition.$key
            if ($null -eq $reference) { continue }
            $provided=@($package.provides | Where-Object { $_.contract_id -ceq $reference.contract_id -and $_.version -ceq $reference.version -and $_.schema_digest -ceq $reference.schema_digest })
            Add-Result 'connector' ($example.id+':'+$key) ($provided.Count -eq 1 -and $serviceHashes[$reference.contract_id] -ceq $reference.schema_digest -and $services[$reference.contract_id].version -ceq $reference.version)
        }
        if ($example.setup) {
            $setup=Read-Json $example.setup
            Add-Result 'connector-shape' ($example.id+':setup') (Check-Schema $setup 'schemas/extension/setup-session.schema.json')
            Add-Result 'connector' ($example.id+':setup-reference') ($setup.connector_id -ceq $instance.connector_id -and $setup.tenant_id -ceq $instance.tenant_id -and $setup.configuration_revision -eq $instance.configuration_revision -and (Same-Json $setup.definition_ref $instance.definition_ref)) 'Independent snapshot; no state transition executed.'
        }
    }
    foreach ($case in $connectors.dependency_cases) {
        $definition=Read-Json $case.definition
        $package=Read-Json $case.manifest
        switch ($case.change) {
            'none' { }
            'missing_contribution' { $definition.connection_dependents[0].contribution_id='org.example.missing' }
            'self_dependency' { $definition.connection_dependents[0].contribution_id=$package.contributions[0].contribution_id }
            'missing_feature' { $definition.connection_dependents[0].required_features=@('avatar.unknown') }
            'missing_required_feature' { $definition.required_features=@('avatar.unknown') }
            'duplicate_dependency' { $definition.connection_dependents=@($definition.connection_dependents)+@($definition.connection_dependents[0]) }
            'unprovided_service' { $package.contributions[1].contract_ref.contract_id='org.example.missing' }
            default { throw "Unknown static dependency fixture change: $($case.change)" }
        }
        Add-Result 'connector-dependency' $case.id ((Test-ConnectorLinks $definition $package) -eq $case.expected_valid)
    }
    foreach ($case in $connectors.configuration_cases) {
        $definition=Read-Json $case.definition
        $valid=Test-ContractJson -Json (ConvertTo-Json -InputObject $case.data -Depth 100 -Compress) -Schema (ConvertTo-Json -InputObject $definition.configuration_schema -Depth 100 -Compress)
        Add-Result 'connector-config' $case.id ($valid -eq $case.expected_valid)
    }
    Check-PayloadCases $connectors.payload_cases $services 'connector-payload'
    $tool=Read-Json 'tests/contracts/tool-cases.json'
    $toolService=Read-Json $tool.contract_file
    $toolManifest=Read-Json $tool.manifest
    $toolCapability=Read-Json $tool.capability
    $toolHash=(Get-FileHash -LiteralPath (Join-Path $RepositoryRoot $tool.contract_file) -Algorithm SHA256).Hash.ToLowerInvariant()
    Add-Result 'tool' 'service-shape' (Check-Schema $toolService 'schemas/extension/contract.schema.json')
    Add-Result 'tool' 'manifest-shape' (Check-Schema $toolManifest 'schemas/extension/manifest.schema.json')
    Add-Result 'tool' 'capability-shape' (Check-Schema $toolCapability 'schemas/core/capability.schema.json')
    Add-Result 'tool' 'honest-scope' (!$tool.runtime_executed)
    Add-Result 'tool' 'no-interaction-dependency' (@($toolManifest.provides + $toolManifest.uses | Where-Object { $_.contract_id -match '^alia\.(interaction|connector\.)' }).Count -eq 0 -and @($toolManifest.contributions | Where-Object { $_.type_id -eq 'alia.contribution.connector' }).Count -eq 0)
    Add-Result 'tool' 'capability-reference' ($tool.schema_digest -ceq $toolHash -and $toolCapability.service_contract.schema_digest -ceq $toolHash -and $toolCapability.service_contract.contract_id -ceq $toolService.contract_id -and $toolCapability.service_contract.version -ceq $toolService.version -and $toolCapability.provider_extension_id -ceq $toolManifest.extension_id)
    $toolMembers=@($toolService.methods | Where-Object { $_.name -ceq $toolCapability.member_id })
    Add-Result 'tool' 'member-projection' ($toolMembers.Count -eq 1 -and (Same-Json $toolMembers[0].input_schema $toolCapability.input_schema) -and (Same-Json $toolMembers[0].output_schema $toolCapability.output_schema) -and $toolMembers[0].side_effect_class -ceq $toolCapability.side_effect_class -and $toolMembers[0].supports_cancel -eq $toolCapability.supports_cancel)
    $services[$toolService.contract_id]=$toolService; $serviceHashes[$toolService.contract_id]=$toolHash
    Check-PayloadCases $tool.payload_cases $services 'tool-payload'
    # Detect drift in exact service references, including copied structural fixtures.
    $referenceFiles=@('tests/contracts/cases.json',$tool.manifest,$tool.capability)
    foreach ($example in $connectors.examples) { $referenceFiles += @($example.manifest,$example.definition) }
    foreach ($file in $referenceFiles) {
        $tree=Get-Content -LiteralPath (Join-Path $RepositoryRoot $file) -Raw | ConvertFrom-Json -AsHashtable -Depth 100
        $pending=[Collections.Generic.Stack[object]]::new(); $pending.Push($tree); $consistent=$true
        while ($pending.Count) {
            $item=$pending.Pop()
            if ($item -is [Collections.IDictionary]) {
                if ($item.Contains('contract_id') -and $item.contract_id -is [string] -and $item.Contains('schema_digest') -and $serviceHashes.ContainsKey($item.contract_id)) {
                    $consistent=$consistent -and $item.schema_digest -ceq $serviceHashes[$item.contract_id] -and $item.version -ceq $services[$item.contract_id].version
                }
                foreach ($value in $item.Values) { if ($null -ne $value) { $pending.Push($value) } }
            } elseif ($item -is [array]) { foreach ($value in $item) { if ($null -ne $value) { $pending.Push($value) } } }
        }
        Add-Result 'service-reference' $file $consistent
    }
    $interaction=$services['alia.interaction']
    $inputSchema=@($interaction.events | Where-Object { $_.name -eq 'input' })[0].payload_schema
    $receiptSchema=@($interaction.events | Where-Object { $_.name -eq 'receipt' })[0].payload_schema
    $coreEvent=Read-Json 'schemas/core/event.schema.json'
    $coreDelivery=Read-Json 'schemas/core/delivery.schema.json'
    Add-Result 'core-reuse' 'interaction-content-parts' ((Same-Json $inputSchema.properties.content_parts $coreEvent.properties.content_parts) -and (Same-Json $inputSchema.'$defs'.contract_ref $coreEvent.'$defs'.contract_ref))
    foreach ($key in @('type','additionalProperties','properties','required','allOf')) {
        Add-Result 'core-reuse' ('interaction-receipt:'+ $key) (Same-Json $receiptSchema.properties.receipt.$key $coreDelivery.$key)
    }
    Add-Result 'core-reuse' 'interaction-receipt-defs' (Same-Json $receiptSchema.'$defs' $coreDelivery.'$defs')
    $bridge=Read-Json 'tests/contracts/bridge-cases.json'
    Add-Result 'bridge-pairs' 'honest-scope' (!$bridge.runtime_executed -and !$bridge.translation_executed)
    foreach ($pair in $bridge.pairs) {
        Add-Result 'bridge-pairs' ($pair.id+':peer-shape') (Check-Schema $pair.peer_payload $bridge.peer_schema)
        $payloadCase=[pscustomobject]@{ id=$pair.id; contract_id='alia.interaction'; member_kind=$pair.alia_member_kind; member_name=$pair.alia_member_name; schema_slot=$pair.alia_schema_slot; payload=$pair.alia_payload; expected_valid=$true }
        Check-PayloadCases @($payloadCase) $services 'bridge-alia-shape'
        $value=$pair.alia_payload
        foreach ($token in $pair.text_pointer.TrimStart('/').Split('/')) {
            $token=$token.Replace('~1','/').Replace('~0','~')
            # Assign inside the branch: pipeline output unwraps singleton arrays.
            if ($value -is [array]) { $value=$value[[int]$token] } else { $value=$value.$token }
        }
        Add-Result 'bridge-pairs' ($pair.id+':authored-text') ($value -ceq $pair.peer_payload.($pair.peer_text_key)) 'Fixed paired sample only; no translator executed.'
    }
    foreach ($case in $bridge.peer_cases) {
        Add-Result 'bridge-peer-shape' $case.id ((Check-Schema $case.data $bridge.peer_schema) -eq $case.expected_valid)
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
    Add-Result 'configuration' 'contract-selection' ($manifest.contract_versions.core -eq '1.0' -and $manifest.contract_versions.extension -eq '1.0' -and $manifest.contract_versions.aeip -eq '1.0')
    $persona = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'config/persona.example.yaml') -Raw
    $policy = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'config/cognitive-policy.example.yaml') -Raw
    Add-Result 'configuration' 'persona-identity' ($persona -match 'identity_id:\s*"identity-001"' -and $persona -match 'schema_version:\s*"1.0"')
    Add-Result 'configuration' 'policy-contracts' ($policy -match 'protocol_version:\s*"1.0"' -and $policy -match 'core_contract_version:\s*"1.0"')
    Add-Result 'configuration' 'initial-adapter-not-capability-limit' ($policy -match 'initial_delivery_adapter:\s*webui_text' -and $policy -match 'required_fake_contracts:\s*\[audio, visual, avatar, game, device\]')
    Test-AeipDesign
    $coverage = Read-Json 'tests/design-coverage.json'
    foreach ($group in $coverage.groups) {
        $content = Get-Content -LiteralPath (Join-Path $RepositoryRoot $group.document) -Raw
        foreach ($marker in $group.markers) { Add-Result 'capability-reference' ($group.document+':'+$marker) ($content.Contains($marker)) 'Presence only; future behavior must be tested.' }
    }
    $documents = @((Join-Path $RepositoryRoot 'README.md'),(Join-Path $RepositoryRoot 'AGENTS.md'),(Join-Path $RepositoryRoot 'CLAUDE.md'),(Join-Path $RepositoryRoot 'schemas/README.md'),(Join-Path $RepositoryRoot 'goal/README.md'))
    $documents += @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'docs') -Recurse -File | Where-Object { $_.Extension -in @('.md','.txt','.html') } | ForEach-Object { $_.FullName })
    $documents += @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'config') -Recurse -Filter '*.md' -File | ForEach-Object { $_.FullName })
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
