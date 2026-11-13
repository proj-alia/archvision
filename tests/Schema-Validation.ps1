#Requires -Version 7.6
# Test-Json performs strict JSON/Schema validation first. JsonSchema.Net, bundled
# with this PowerShell runtime, then asserts formats explicitly and blocks fetches.
$script:ContractSchemaValidators = @{}
$script:ContractCalendarFormatRegistered = $false
function Register-ContractCalendarFormat {
    if ($script:ContractCalendarFormatRegistered) { return }
    $script:ContractOriginalDateTimeFormat = [Json.Schema.Formats]::Get('date-time')
    $predicate = [Func[System.Text.Json.Nodes.JsonNode, bool]]{
        param($Node)
        $formatError = $null
        if (!$script:ContractOriginalDateTimeFormat.Validate($Node, [ref]$formatError)) { return $false }
        if ($Node -isnot [System.Text.Json.Nodes.JsonValue]) { return $true }
        $value = ''
        if (!$Node.TryGetValue[string]([ref]$value)) { return $true }
        if ($value -notmatch '^([0-9]{4})-([0-9]{2})-([0-9]{2})[tT]') { return $false }
        $year = [int]$Matches[1]; $month = [int]$Matches[2]; $day = [int]$Matches[3]
        if ($month -lt 1 -or $month -gt 12) { return $false }
        $days = @(31,28,31,30,31,30,31,31,30,31,30,31)
        if ($year % 4 -eq 0 -and ($year % 100 -ne 0 -or $year % 400 -eq 0)) { $days[1] = 29 }
        return $day -ge 1 -and $day -le $days[$month - 1]
    }
    # The bundled validator accepts February 30 in date-time: enforce calendar days
    # as well as its existing RFC 3339 lexical validation, using the same profile.
    [Json.Schema.Formats]::Register([Json.Schema.PredicateFormat]::new('date-time', $predicate))
    $script:ContractCalendarFormatRegistered = $true
}
function Test-ContractJson {
    [CmdletBinding(DefaultParameterSetName = 'Text')]
    param(
        [Parameter(Mandatory)][string]$Json,
        [Parameter(Mandatory, ParameterSetName = 'Text')][string]$Schema,
        [Parameter(Mandatory, ParameterSetName = 'File')][string]$SchemaFile
    )
    try {
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $valid = Test-Json -Json $Json -SchemaFile $SchemaFile -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$valid) { return $false }
            $Schema = Get-Content -LiteralPath $SchemaFile -Raw -ErrorAction Stop
        }
        else {
            $valid = Test-Json -Json $Json -Schema $Schema -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$valid) { return $false }
        }
        Register-ContractCalendarFormat
        if (!$script:ContractSchemaValidators.ContainsKey($Schema)) {
            $options = [Json.Schema.EvaluationOptions]::new()
            $options.EvaluateAs = [Json.Schema.SpecVersion]::Draft202012
            $options.RequireFormatValidation = $true
            $options.OnlyKnownFormats = $true
            $options.SchemaRegistry.Fetch = [Func[Uri, Json.Schema.IBaseDocument]]{
                param($Uri)
                throw "External schema reference fetch is disabled: $Uri"
            }
            $script:ContractSchemaValidators[$Schema] = @{
                validator = [Json.Schema.JsonSchema]::FromText($Schema)
                options = $options
            }
        }
        $entry = $script:ContractSchemaValidators[$Schema]
        $instance = [System.Text.Json.Nodes.JsonNode]::Parse($Json)
        return [bool]($entry.validator.Evaluate($instance, $entry.options)).IsValid
    }
    catch { return $false }
}
