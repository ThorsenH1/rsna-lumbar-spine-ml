# Follow one lumbar MRI prediction

This example uses a synthetic MRI study made from mathematical patterns. It shows how the trained model turns image slices into probabilities for a specific location in the spine.

![Synthetic MRI planes, an L4–L5 crop and the model's grade probabilities](examples/workflow.png)

## 1. Open the study

A study contains a stack of DICOM files for each acquisition. DICOM stores the image pixels and the physical position and orientation of each slice. The [example preview](examples/phantom.png) shows two sagittal sequences from the side and one axial sequence from above. The data generator creates the full slice stacks.

## 2. Locate the anatomy

The localizer estimates the positions of five disc levels. Using the DICOM geometry, the pipeline finds the slices and extracts a small region around each estimate. The box is the actual crop selected by the first fold's learned localizer for spinal canal stenosis at L4–L5. In the synthetic example the box is near the edge of the image, which illustrates a localization failure. [All five crops and their model scores](WHERE-THE-MODEL-LOOKS.md)

## 3. Read the model output

A residual image encoder describes the crops. The spatial-detail branch preserves where evidence appears inside each crop. Each of five fold models scores the original crops and those same crops reflected left to right when the orientation check passes. It puts the reflected predictions back into the original side order and averages the two passes. Each side region also gets a tighter view, which contributes a quarter of that grader's score. The [trace](examples/study-trace.json) records the crop coordinates, fold scores and final blend. [Look at both crop sizes](WHERE-THE-MODEL-LOOKS.md#compare-two-views-of-the-same-side-region)

| L4–L5 spinal canal narrowing | Normal or mild | Moderate | Severe |
| --- | ---: | ---: | ---: |
| Previous ensemble | 0.4752 | 0.2328 | 0.2920 |
| Average of five original-and-reflected spatial-detail models | 0.7979 | 0.1017 | 0.1003 |
| Final blend | **0.6365** | **0.1673** | **0.1962** |

The final blend uses **50%** of the previous ensemble and **50%** of the new models. For side targets, it partially compensates for the spatial grader's training weights before the final average. Each of the 25 rows has three probabilities summing to one. The input is generated for this demonstration. [Full example JSON](examples/spatial-detail-prediction.json)

The same example shows how adjusting the weights changes the scores for the left subarticular region at L4–L5.

| Left side at L4–L5 | Normal or mild | Moderate | Severe |
| --- | ---: | ---: | ---: |
| Narrower crops | 0.539 | 0.297 | 0.164 |
| Narrower crops and grade weight adjustment | **0.587** | **0.277** | **0.135** |

## 4. Generate the study and rerun the selected model

Use the Python environment, `$learned`, `$graders`, and `$plan` from the [training and deployment guide](RESEARCH.md#reproduce-the-five-fold-comparison). The example includes the first model's [starting reference probabilities](examples/synthetic-reference.csv) for the generated study. The following commands reproduce the previous ensemble and pass its 25 rows to the new graders.

```powershell
$example = 'search-artifacts/synthetic-spine'
& $p -m medimage.demo spine --output $example
& $p -m medimage.search_predict spine --selection search-artifacts/runs/spine/selection.json `
    --search search-artifacts/runs/spine --weights $hf --root $example --cache "$example/cache" `
    --localization artifacts/spine/localization --incumbent examples/synthetic-reference.csv `
    --output "$example/previous-ensemble.csv"
& $p -m medimage.spine_detail_infer predict --plan $plan --root $example --cache "$example/cache" `
    --reference artifacts/spine/localization --learned $learned --runs $graders `
    --prior "$example/previous-ensemble.csv" --output "$example/prediction.csv" --trace "$example/study-trace.json"
& $p -m medimage.workflow_figure spine --examples $example --cache "$example/cache" `
    --trace "$example/study-trace.json" --output "$example/workflow.png"
```

Find the L4–L5 spinal canal row in the CSV and check that the three columns sum to 1. The published scores use a specific set of trained weights. A freshly trained run can produce different scores.

## 5. Understand the evaluation

| What can go wrong | How the experiment addresses it |
| --- | --- |
| Reversed slice order points the model to the wrong anatomy | Use physical DICOM coordinates to order slices and find each plane |
| A localizer memorizes an evaluation study | Fit the localizer without that study's outer fold |
| A confident model confuses the moderate grade with its neighbors | Show AUROC for each grade and report a probability-sensitive log loss |
| The local test has no reference grades | Score the model on five held-out study folds and check file generation on the local test |

The reported model reached **0.8809 macro AUROC** on the held-out predictions for 1,975 studies. It averages 75 comparisons across findings, levels and grades. Its weighted log loss is **0.4877** on these folds. The narrower-crop model before grade weight adjustment reached the lower log loss of **0.4836**. The local test study checks the 25-row output format. [Full research report](RESEARCH.md)
