param(
    [Parameter(Mandatory)] [ValidateSet('chest','mammo','spine')] [string] $Task,
    [Parameter(Mandatory)] [string] $Python,
    [Parameter(Mandatory)] [string] $DataRoot,
    [Parameter(Mandatory)] [string] $InitialWeights,
    [Parameter(Mandatory)] [string] $WeightRoot,
    [string] $Artifacts = 'artifacts',
    [string] $Search = 'search-artifacts',
    [string] $HistoricalOof,
    [string] $HistoricalSubmission
)

$ErrorActionPreference = 'Stop'
$Python = (Resolve-Path -LiteralPath $Python).Path
$DataRoot = (Resolve-Path -LiteralPath $DataRoot).Path
$InitialWeights = (Resolve-Path -LiteralPath $InitialWeights).Path
$WeightRoot = (Resolve-Path -LiteralPath $WeightRoot).Path
if ($HistoricalOof -or $HistoricalSubmission) {
    if ($Task -ne 'spine' -or -not ($HistoricalOof -and $HistoricalSubmission)) {
        throw 'The MRI historical comparison requires both OOF and test prediction CSV files.'
    }
    $HistoricalOof = (Resolve-Path -LiteralPath $HistoricalOof).Path
    $HistoricalSubmission = (Resolve-Path -LiteralPath $HistoricalSubmission).Path
}

Push-Location (Join-Path $PSScriptRoot '..')
try {
    New-Item -ItemType Directory -Path $Artifacts,$Search -Force | Out-Null
    $Artifacts = (Resolve-Path -LiteralPath $Artifacts).Path
    $Search = (Resolve-Path -LiteralPath $Search).Path
    if ($Task -eq 'spine') {
        & (Join-Path $PSScriptRoot 'Run-Spine.ps1') -Python $Python -Weights $InitialWeights -DataRoot $DataRoot -ArtifactRoot $Artifacts -BaselineOof $HistoricalOof -BaselineSubmission $HistoricalSubmission
        & (Join-Path $PSScriptRoot 'Search-Models.ps1') -Python $Python -WeightRoot $WeightRoot -SearchRoot $Search -OriginalArtifacts $Artifacts -Tasks spine -SpineData $DataRoot
    } else {
        & (Join-Path $PSScriptRoot 'Run-Radiography.ps1') -Python $Python -Weights $InitialWeights -Task $Task -DataRoot $DataRoot -ArtifactRoot $Artifacts
        $folder = if ($Task -eq 'chest') { 'chest' } else { 'mammo-full' }
        & $Python -u -m medimage.search_features pixels $Task --cohort (Join-Path $Artifacts "cache/$folder") --root $DataRoot --output (Join-Path $Search "pixels/$Task")
        if ($LASTEXITCODE -ne 0) { throw 'Pixel cache preparation failed.' }
        & (Join-Path $PSScriptRoot 'Extract-SearchFeatures.ps1') -Python $Python -WeightRoot $WeightRoot -SearchRoot $Search -OriginalArtifacts $Artifacts -Tasks $Task
        & (Join-Path $PSScriptRoot 'Search-Models.ps1') -Python $Python -WeightRoot $WeightRoot -SearchRoot $Search -OriginalArtifacts $Artifacts -Tasks $Task
    }
}
finally { Pop-Location }
