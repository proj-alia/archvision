# Design-only checks; no sockets, peer execution, authentication or translation.
function Read-AeipPointer([object]$Value, [string]$Pointer) {
    foreach ($part in $Pointer.TrimStart('/').Split('/')) {
        $key=$part.Replace('~1','/').Replace('~0','~')
        if ($Value -is [array]) { $Value=$Value[[int]$key] } else { $Value=$Value.$key }
    }
    return ,$Value
}
function Test-AeipDesign {
    $suite=Read-Json 'tests/contracts/aeip-cases.json'
    Add-Result 'aeip' 'honest-scope' ($suite.design_status -eq 'draft' -and !$suite.runtime_executed -and !$suite.translation_executed -and !$suite.core_changes_allowed_for_new_platform)
    foreach ($item in $suite.services) {
        $service=Read-Json $item.path
        $hash=(Get-FileHash -LiteralPath (Join-Path $RepositoryRoot $item.path) -Algorithm SHA256).Hash.ToLowerInvariant()
        Add-Result 'aeip-contract' $item.path ($service.contract_id -ceq $item.contract_ref.contract_id -and $service.version -ceq $item.contract_ref.version -and $hash -ceq $item.contract_ref.schema_digest -and (Check-Schema $service 'schemas/extension/contract.schema.json'))
        $services[$service.contract_id]=$service; $serviceHashes[$service.contract_id]=$hash
    }
    foreach ($entry in $suite.messages.PSObject.Properties) {
        Add-Result 'aeip-message' $entry.Name (Check-Schema $entry.Value $suite.schema)
    }
    $wire=Read-Json $suite.schema
    Add-Result 'aeip-message' 'all-kinds-have-fixtures' (@($wire.properties.kind.enum | Where-Object { $_ -cnotin @($suite.messages.PSObject.Properties.Value.kind) }).Count -eq 0)
    foreach ($case in $suite.invalid_messages) {
        $value=$suite.messages.($case.base) | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable -Depth 100
        $cursor=$value
        for ($index=0; $index -lt $case.path.Count-1; $index++) {
            $key=$case.path[$index]
            if ($cursor -is [array]) { $cursor=$cursor[[int]$key] } else { $cursor=$cursor[$key] }
        }
        $key=$case.path[-1]
        if ($case.remove) { $cursor.Remove($key) } else { $cursor[$key]=$case.value }
        Add-Result 'aeip-negative' $case.id (!(Check-Schema $value $suite.schema))
    }
    Check-PayloadCases $suite.payload_cases $services 'aeip-payload'
    $wirePayloads=@($suite.message_payload_links | ForEach-Object {
        [pscustomobject]@{ id=$_.message; contract_id=$_.contract_id; member_kind=$_.member_kind; member_name=$_.member_name; schema_slot=$_.schema_slot; payload=$suite.messages.($_.message).body.payload; expected_valid=$true }
    })
    Check-PayloadCases $wirePayloads $services 'aeip-wire-payload'
    $adapter=Read-Json $suite.adapter
    $manifest=Read-Json $suite.manifest
    Add-Result 'aeip-adapter' 'shape' (Check-Schema $adapter 'schemas/aeip/adapter.schema.json')
    Add-Result 'aeip-adapter' 'manifest' (Check-Schema $manifest 'schemas/extension/manifest.schema.json')
    foreach ($case in $suite.configuration_cases) {
        $valid=Test-ContractJson -Json (ConvertTo-Json -InputObject $case.data -Depth 100 -Compress) -Schema (ConvertTo-Json -InputObject $adapter.configuration_schema -Depth 100 -Compress)
        Add-Result 'aeip-configuration' $case.id ($valid -eq $case.expected_valid)
    }
    $descriptor=$manifest.contributions[0].descriptor_ref
    $descriptorPath=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent (Join-Path $RepositoryRoot $suite.manifest)) $descriptor.path))
    $descriptorHash=(Get-FileHash -LiteralPath (Join-Path $RepositoryRoot $suite.adapter) -Algorithm SHA256).Hash.ToLowerInvariant()
    Add-Result 'aeip-adapter' 'registration-reference' ($manifest.contributions[0].type_id -ceq 'alia.contribution.protocol-adapter' -and $descriptor.sha256 -ceq $descriptorHash -and $descriptorPath -ceq [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $suite.adapter)))
    foreach ($mapping in $adapter.mappings) {
        $contract=$services[$mapping.contract_ref.contract_id]
        $members=switch ($mapping.member_kind) { 'method' { $contract.methods }; 'event' { $contract.events }; 'stream' { $contract.streams } }
        $selected=@($members | Where-Object { $_.name -ceq $mapping.member_id })
        Add-Result 'aeip-adapter' $mapping.native_member ($null -ne $contract -and $contract.version -ceq $mapping.contract_ref.version -and $serviceHashes[$contract.contract_id] -ceq $mapping.contract_ref.schema_digest -and $selected.Count -eq 1 -and $null -ne $selected[0].($mapping.schema_slot))
    }
    $standalone=$adapter | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
    $standalone.execution_location='standalone'
    Add-Result 'aeip-adapter' 'standalone-shape' (Check-Schema $standalone 'schemas/aeip/adapter.schema.json')
    Add-Result 'aeip-adapter' 'native-hello-needs-no-package' (!$suite.messages.hello.body.PSObject.Properties['manifest_ref'] -and !$suite.messages.hello.body.PSObject.Properties['extension_id'])
    $bytes=[Convert]::FromBase64String($suite.messages.description.body.bytes)
    $decoded=[Text.Encoding]::UTF8.GetString($bytes)
    $decodedHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    Add-Result 'aeip-contract' 'description-bytes' ($decodedHash -ceq $suite.messages.description.body.contract_ref.schema_digest -and (Test-ContractJson -Json $decoded -SchemaFile (Join-Path $RepositoryRoot 'schemas/extension/contract.schema.json')))
    foreach ($pair in $suite.pairs) {
        Add-Result 'aeip-pair' ($pair.id+':native-shape') (Check-Schema $pair.native $suite.native_schema)
        foreach ($comparison in $pair.comparisons) {
            $public=Read-AeipPointer $suite.messages.($pair.message) $comparison.public_pointer
            $native=Read-AeipPointer $pair.native $comparison.native_pointer
            Add-Result 'aeip-pair' ($pair.id+':'+$comparison.public_pointer) (Same-Json $public $native) 'Authored pair only; no translator executed.'
        }
    }
    $core=Read-Json 'schemas/core/event.schema.json'
    $publicInput=@($services['alia.peer.interaction'].events | Where-Object name -eq 'input')[0].payload_schema
    $observation=$services['alia.peer.observation'].events[0].payload_schema
    Add-Result 'aeip-core-reuse' 'input-content-parts' (Same-Json $publicInput.properties.content_parts $core.properties.content_parts)
    Add-Result 'aeip-core-reuse' 'observation-content-parts' (Same-Json $observation.properties.content_parts $core.properties.content_parts)
    Add-Result 'aeip-core-reuse' 'source-not-fake-conversation' ('source_ref' -in $observation.required -and 'conversation_ref' -notin $observation.required -and 'actor_ref' -notin $observation.required)
    foreach ($entry in $catalog.service_contracts) {
        $raw=[IO.File]::ReadAllBytes((Join-Path $RepositoryRoot $entry.path))
        Add-Result 'distribution-bytes' $entry.path (!([Text.Encoding]::UTF8.GetString($raw).Contains("`r")) -and !($raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191))
    }
}
