# Follow one lumbar MRI prediction

This example uses a synthetic MRI study made from mathematical patterns. It shows how the trained model turns image slices into probabilities for a specific location in the spine.

![Synthetic MRI planes, an L4–L5 crop and the model's grade probabilities](examples/workflow.png)

## 1. Open the study

A study contains a stack of DICOM files for each acquisition. DICOM stores the image pixels and the physical position and orientation of each slice. The [example preview](examples/phantom.png) shows two sagittal sequences from the side and one axial sequence from above. The data generator creates the full slice stacks.

## 2. Locate the anatomy

The localizer estimates the positions of five disc levels. Using the DICOM geometry, the pipeline finds the slices and extracts a small region around each estimate. It projects the same physical locations into the higher-resolution grid. The box is the actual crop selected by the first fold's learned localizer at L4–L5. In the synthetic example the box is near the edge of the image, which illustrates a localization failure. [All five crops and their model scores](WHERE-THE-MODEL-LOOKS.md)

## 3. Read the model output

A residual image encoder describes the crops. Five higher-resolution graders score the original and reflected crops when the orientation check passes. The system puts the reflected predictions back into the original side order and averages the two passes. The result is then averaged with the grade-adjusted original-grid prediction. The trace records the crop coordinates, fold scores and final blend. [Trace](examples/study-trace.json)

| L4–L5 spinal canal narrowing | Normal or mild | Moderate | Severe |
| --- | ---: | ---: | ---: |
| Grade-adjusted original-grid ensemble | 0.6365 | 0.1673 | 0.1962 |
| Average of five higher-resolution graders | 0.9657 | 0.0334 | 0.0009 |
| Final blend | **0.8011** | **0.1003** | **0.0985** |

The final blend gives both branches equal weight. Each of the 25 rows has three probabilities summing to one. The input is generated for this demonstration. [Full example JSON](examples/spatial-detail-prediction.json)

The optional geometric blend also gives both branches equal weight. For each grade, multiply the two branch scores, take the square root, and rescale the three values to sum to one. In the example above the branches disagree on the severe grade, so its score drops from **0.0985 to 0.0151**. The geometric result is **0.8992 normal or mild, 0.0857 moderate, and 0.0151 severe**. On the labeled folds this formula slightly improved AUROC and increased weighted log loss. [Geometric prediction CSV](examples/geometric-prediction.csv) · [Measured comparison](RESEARCH.md#compare-ways-to-combine-the-two-grading-branches)

The two-step variant first assigns **0.0664** to moderate or severe at L4–L5. It then allocates about **31.2%** of that score to severe. The result is **0.9336 normal or mild, 0.0456 moderate, and 0.0207 severe**. You can compare the same target across all three formulas using the example CSVs. [Two-step prediction CSV](examples/two-step-prediction.csv) · [Grade-boundary results](RESEARCH.md#distinguish-moderate-from-both-neighboring-grades)

Inside the original-grid branch, adjusting the weights also changes the scores for the left subarticular region at L4–L5.

| Left side at L4–L5 | Normal or mild | Moderate | Severe |
| --- | ---: | ---: | ---: |
| Narrower crops | 0.539 | 0.297 | 0.164 |
| Narrower crops and grade weight adjustment | **0.587** | **0.277** | **0.135** |

## 4. Generate the study and rerun the selected model

Use `$p`, `$localizer`, `$learned`, `$graders`, `$plan`, `$nativeGraders`, and `$nativePlan` from the [training and deployment guide](RESEARCH.md#reproduce-the-five-fold-comparison). The commands generate the scan, produce the original-grid probabilities, then pass those 25 rows to the higher-resolution graders. The example contains the starting reference probabilities for the first step. [Starting reference](examples/synthetic-reference.csv)

```powershell
$example = 'search-artifacts/synthetic-spine'
& $p -m medimage.demo spine --output $example
& $p -m medimage.search_predict spine --selection search-artifacts/runs/spine/selection.json `
    --search search-artifacts/runs/spine --weights $hf --root $example --cache "$example/cache" `
    --localization artifacts/spine/localization --incumbent examples/synthetic-reference.csv `
    --output "$example/previous-ensemble.csv"
& $p -m medimage.spine_detail_infer predict --plan $plan --root $example --cache "$example/cache" `
    --reference $localizer --learned $learned --runs $graders --prior "$example/previous-ensemble.csv" `
    --output "$example/grade-adjusted.csv" --trace "$example/grade-adjusted-trace.json"
& $p -m medimage.spine_detail_infer predict --plan $nativePlan --root $example --cache "$example/cache" `
    --native-cache "$example/cache256" --reference $localizer --learned $learned --runs $nativeGraders `
    --prior "$example/grade-adjusted.csv" --output "$example/prediction.csv" --trace "$example/study-trace.json"
& $p -m medimage.workflow_figure spine --examples $example --cache "$example/cache256" `
    --trace "$example/study-trace.json" --output "$example/workflow.png"
```

Find the L4–L5 spinal canal row in the CSV and check that the three columns sum to 1. The published scores use a specific set of trained weights. A freshly trained run can produce different scores.

After running the [pooling comparison](RESEARCH.md#reproduce-the-higher-resolution-model), use its `$pooling` output and the study trace to reproduce the optional geometric result.

```powershell
& $p -m medimage.spine_pool_audit apply --report "$pooling/metrics.json" --plan $nativePlan `
    --trace "$example/study-trace.json" --output "$example/geometric-prediction.csv"
& $p -m medimage.spine_pool_audit apply --report "$boundaries/metrics.json" --plan $nativePlan `
    --trace "$example/study-trace.json" --method native_presence --output "$example/two-step-prediction.csv"
```

## 5. Understand the evaluation

| What can go wrong | How the experiment addresses it |
| --- | --- |
| Reversed slice order points the model to the wrong anatomy | Use physical DICOM coordinates to order slices and find each plane |
| A localizer memorizes an evaluation study | Fit the localizer without that study's outer fold |
| A confident model confuses the moderate grade with its neighbors | Show AUROC for each grade and report a probability-sensitive log loss |
| The local test has no reference grades | Score the model on five held-out study folds and check file generation on the local test |

The reported model reached **0.8868 macro AUROC** on the held-out predictions for 1,975 studies. It averages 75 comparisons across findings, levels and grades. Its weighted log loss is **0.4734** on these folds. The local unlabeled test study verifies the 25-row output. [Full research report](RESEARCH.md)
