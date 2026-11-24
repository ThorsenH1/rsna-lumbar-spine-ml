param(
    [Parameter(Mandatory)] [string] $Python,
    [Parameter(Mandatory)] [string] $Weights,
    [Parameter(Mandatory)] [string] $DataRoot,
    [string] $ArtifactRoot = 'artifacts',
    [string] $BaselineOof,
    [string] $BaselineSubmission
)

$ErrorActionPreference = 'Stop'
$Python = (Resolve-Path -LiteralPath $Python).Path
$Weights = (Resolve-Path -LiteralPath $Weights).Path
$DataRoot = (Resolve-Path -LiteralPath $DataRoot).Path
if ($BaselineOof) { $BaselineOof = (Resolve-Path -LiteralPath $BaselineOof).Path }
if ($BaselineSubmission) { $BaselineSubmission = (Resolve-Path -LiteralPath $BaselineSubmission).Path }

function Invoke-PythonModule {
    & $Python -u -m @args
    if ($LASTEXITCODE -ne 0) { throw "Python exited with code $LASTEXITCODE." }
}

Push-Location (Join-Path $PSScriptRoot '..')
try {
    $cache = Join-Path $ArtifactRoot 'cache/spine-train'
    $folds = Join-Path $ArtifactRoot 'spine/folds.csv'
    $localization = Join-Path $ArtifactRoot 'spine/localization'
    $runs = Join-Path $ArtifactRoot 'spine/runs'
    $assessment = Join-Path $ArtifactRoot 'evaluation/spine'
    Invoke-PythonModule medimage.spine_data --root $DataRoot --output $cache --workers 10
    Invoke-PythonModule medimage.spine_splits --root $DataRoot --output $folds
    Invoke-PythonModule medimage.spine_localize --cache $cache --folds $folds --output $localization
    foreach ($fold in 0..4) {
        Invoke-PythonModule medimage.spine_train --root $DataRoot --cache $cache --folds $folds --localization $localization --weights $Weights --fold $fold --output (Join-Path $runs "fold-$fold")
    }
    $evaluate = @('--root', $DataRoot, '--folds', $folds, '--runs', $runs, '--localization', $localization, '--output', $assessment)
    if ($BaselineOof) { $evaluate += @('--baseline-oof', $BaselineOof) }
    Invoke-PythonModule medimage.spine_evaluate @evaluate
    $infer = @('--root', $DataRoot, '--cache', (Join-Path $ArtifactRoot 'cache/spine-test'), '--assessment', (Join-Path $assessment 'metrics.json'), '--localization', $localization, '--runs', $runs, '--output', (Join-Path $ArtifactRoot 'inference/spine.csv'))
    if ($BaselineSubmission) { $infer += @('--baseline-submission', $BaselineSubmission) }
    Invoke-PythonModule medimage.spine_infer @infer
}
finally { Pop-Location }
