param(
    [Parameter(Mandatory)] [string] $Python,
    [Parameter(Mandatory)] [string] $WeightRoot,
    [Parameter(Mandatory)] [string] $SearchRoot,
    [string] $SpineData,
    [string] $OriginalArtifacts = 'artifacts',
    [ValidateSet('mammo','spine','chest')] [string[]] $Tasks = @('mammo','spine','chest')
)

$ErrorActionPreference = 'Stop'
$Python = (Resolve-Path -LiteralPath $Python).Path
$WeightRoot = (Resolve-Path -LiteralPath $WeightRoot).Path
$SearchRoot = (Resolve-Path -LiteralPath $SearchRoot).Path
if ($Tasks -contains 'spine') {
    if (-not $SpineData) { throw 'The spine task requires -SpineData.' }
    $SpineData = (Resolve-Path -LiteralPath $SpineData).Path
}

function Invoke-Module {
    & $Python -u -m @args
    if ($LASTEXITCODE -ne 0) { throw "A model-search module exited with code $LASTEXITCODE." }
}

Push-Location (Join-Path $PSScriptRoot '..')
try {
    foreach ($task in $Tasks) {
        if ($task -eq 'spine') {
            $cohort=Join-Path $OriginalArtifacts 'cache/spine-train'
            $folds=Join-Path $OriginalArtifacts 'spine/folds.csv'
            $location=Join-Path $OriginalArtifacts 'spine/localization'
            $features=Join-Path $SearchRoot 'features/spine'
            $run=Join-Path $SearchRoot 'runs/spine'
            Invoke-Module medimage.search_spine_features --cache $cohort --folds $folds --localization $location --weights $WeightRoot --output $features
            Invoke-Module medimage.search_spine --root $SpineData --cache $cohort --folds $folds --features $features --previous $OriginalArtifacts --output $run
            continue
        }
        $cohort=if ($task -eq 'chest') { Join-Path $OriginalArtifacts 'cache/chest' } else { Join-Path $OriginalArtifacts 'cache/mammo-full' }
        $features=Join-Path $SearchRoot "features/$task"
        $pixels=Join-Path $SearchRoot "pixels/$task"
        $run=Join-Path $SearchRoot "runs/$task"
        $evaluation=Join-Path $SearchRoot "evaluation/$task"
        Invoke-Module medimage.search_heads $task --cohort $cohort --features $features --output $run
        $epochs=if ($task -eq 'chest') { 3 } else { 6 }
        $batch=if ($task -eq 'chest') { 96 } else { 12 }
        Invoke-Module medimage.search_adapt $task --cohort $cohort --pixels $pixels --search $run --weights $WeightRoot --original $OriginalArtifacts --epochs $epochs --batch-size $batch
        Invoke-Module medimage.search_evaluate $task --cohort $cohort --features $features --search $run --original $OriginalArtifacts --output $evaluation --pixels $pixels --weights $WeightRoot
    }
}
finally { Pop-Location }
