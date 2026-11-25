# Lumbar MRI discrimination

This report describes the earlier feature ensemble. The [current localizer and original-and-reflected grader](RESEARCH.md) reached 0.8789 on the same five held-out folds.

| Metric | Held-out result |
| --- | ---: |
| Macro one-vs-rest AUROC | **0.8534** |
| 95% study-bootstrap interval | 0.8472–0.8599 |
| Macro average precision | 0.5597 |
| RSNA weighted log loss | 0.5260 |
| Evaluation cohort | 1,975 studies across five outer folds |

The AUROC averages 75 comparisons across conditions, anatomical levels, and severity grades. Each comparison uses the studies with an observed reference grade for that target. The bootstrap resamples studies within their folds and retains all observed grades from each resampled study.

## Severity

| Grade | Macro AUROC |
| --- | ---: |
| Normal or mild | 0.8657 |
| Moderate | 0.7937 |
| Severe | 0.9007 |

The intermediate grade has the lowest discrimination. The model needs to distinguish moderate findings from both neighbouring grades. The pooled metric describes discrimination on cross-validated development data. The available local test study has no released reference grades.

## Reproduce the audit

Run the [training workflow](README.md#reproduce-the-experiment) to generate predictions on the five frozen folds. The audit checks the split checksum and reproduces the selected model's weighted log loss before calculating AUROC.

```powershell
& $p -m medimage.auc_spine --root $data --folds artifacts/spine/folds.csv --selection search-artifacts/runs/spine/selection.json --predictions search-artifacts/runs/spine/selected-oof.csv --output search-artifacts/evaluation/spine-discrimination
```

The [synthetic inference example](examples/README.md) shows how each anatomical target receives three probabilities and how the prediction file is assembled. [RSNA challenge](https://www.rsna.org/artificial-intelligence/ai-image-challenge/lumbar-spine-degenerative-classification-ai-challenge)
