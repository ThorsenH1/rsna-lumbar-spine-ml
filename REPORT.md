# Experiment report

The selected configuration is `incumbent+raw-0.15`.

The [discrimination audit](DISCRIMINATION.md) reports 0.8534 macro AUROC and explains the validation protocol, uncertainty, and severity differences.

## Out-of-fold comparison

| Model | Overall | Spinal | Foraminal | Subarticular | Any severe spinal | Folds improved | Paired delta CI |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `incumbent+raw-0.15` | 0.5260 | 0.4019 | 0.6305 | 0.6901 | 0.3817 | 5/5 | [-0.0067, -0.0024] |
| `incumbent+cal-0.15` | 0.5264 | 0.4021 | 0.6309 | 0.6907 | 0.3819 | 5/5 | [-0.0064, -0.0021] |
| `incumbent+raw-0.30` | 0.5277 | 0.4027 | 0.6336 | 0.6905 | 0.3841 | 3/5 | [-0.0066, +0.0009] |
| `incumbent+cal-0.30` | 0.5283 | 0.4032 | 0.6342 | 0.6916 | 0.3844 | 3/5 | [-0.0059, +0.0015] |
| `incumbent` | 0.5307 | 0.4084 | 0.6326 | 0.6965 | 0.3852 | 0/5 | [+0.0000, +0.0000] |
| `incumbent+raw-0.50` | 0.5377 | 0.4116 | 0.6442 | 0.6992 | 0.3956 | 1/5 | [+0.0012, +0.0131] |
| `incumbent+cal-0.50` | 0.5384 | 0.4121 | 0.6448 | 0.7005 | 0.3960 | 1/5 | [+0.0021, +0.0137] |
| `incumbent+raw-0.70` | 0.5567 | 0.4299 | 0.6627 | 0.7169 | 0.4174 | 1/5 | [+0.0179, +0.0348] |
| `incumbent+cal-0.70` | 0.5568 | 0.4298 | 0.6625 | 0.7180 | 0.4170 | 1/5 | [+0.0182, +0.0348] |
| `feature_calibrated` | 0.6075 | 0.4873 | 0.7081 | 0.7672 | 0.4674 | 0/5 | [+0.0637, +0.0909] |
| `feature_uncalibrated` | 0.6140 | 0.4943 | 0.7132 | 0.7705 | 0.4778 | 0/5 | [+0.0690, +0.0989] |

## Nested selection

| Outer fold | Inner validation fold | Inner fit studies | Outer validation studies | Head | Descriptor | Epochs | Standalone loss | With inner calibration |
| ---: | ---: | ---: | ---: | --- | --- | ---: | ---: | ---: |
| 0 | 1 | 1181 | 393 | attention | hybrid | 6 | 0.6300 | 0.6271 |
| 1 | 2 | 1181 | 401 | attention | hybrid | 4 | 0.5870 | 0.5870 |
| 2 | 3 | 1189 | 393 | attention | hybrid | 6 | 0.5718 | 0.5725 |
| 3 | 4 | 1187 | 393 | conv | hybrid | 7 | 0.6744 | 0.6556 |
| 4 | 0 | 1187 | 395 | attention | hybrid | 8 | 0.6074 | 0.5959 |

## Localization and endpoint

Median landmark error was 7.32 mm. The training-fold atlas reference had a 16.19 mm median. 67.6% of points were within 10 mm. Training-region localization excludes the study's own fold and the outer holdout, plus the inner holdout where applicable.

The classifier searches over 12 recipes per outer fold, varying head, descriptor, regularization, class weights, ordinal penalty, and the severe-stenosis term. The inner holdout chooses the refit budget. Two seeds train on the outer development split. The paired interval and fold-count rule gate promotion against the previous ensemble.

Raw inference on the local unlabeled test completed with 25 finite competition rows. See [the synthetic example](examples/README.md) for a public input and output.
