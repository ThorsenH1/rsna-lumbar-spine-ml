# RSNA Lumbar Spine MRI Grading

DICOM geometry, nested landmark localization, and severity grading at five lumbar levels.

**0.8809 macro AUROC** over five held-out folds, with a 95% study-bootstrap interval of 0.8762–0.8854. The same model has **0.4877 weighted log loss**. The best measured weighted log loss is **0.4836** from the narrower-crop model used before the grade weight adjustment.

The AUROC-selected model blends the previous ensemble with a spatial-detail grader. The grader reads a regular view and a tighter view of each side region and uses reflection when DICOM orientation supports it. It partially compensates for the severity weights used during training. See the [full research comparison](RESEARCH.md), [earlier discrimination audit](DISCRIMINATION.md), [search trajectories](figures/search.png), and [synthetic prediction example](examples/README.md).

## Start with one prediction

See a synthetic MRI study, the actual crop selected by the localizer and the model's three grade probabilities at L4–L5. The [walkthrough](WALKTHROUGH.md) explains how to generate the study and run it yourself. [See the crops for all five disc levels and the additional side-region view](WHERE-THE-MODEL-LOOKS.md)

![Synthetic MRI planes, a selected L4–L5 region and the three grade probabilities](examples/workflow.png)

## Benchmark

![AUROC by severity for the reference and spatial-detail models](figures/spatial-detail-comparison.png)

The [research report](RESEARCH.md) compares the original localizer with a learned disc detector and measures what changes when the grading model receives better crops.

## Dataset

| Unit | Count |
| --- | ---: |
| Training studies across folds | 1,975 |
| Held-out study–target predictions | 49,375 |
| Local unlabeled test studies | 1 |

The public score is a paired comparison across five outer folds. The local test has one unlabeled study and verifies the 25-row submission. Supply `-HistoricalOof` and `-HistoricalSubmission` to match the reported historical reference. The workflow can also build a fresh localized reference. [RSNA challenge](https://www.rsna.org/artificial-intelligence/ai-image-challenge/lumbar-spine-degenerative-classification-ai-challenge) · [Dataset paper](https://doi.org/10.1148/ryai.250480)

## Workflow

```mermaid
flowchart LR
    A[Raw DICOM] --> B[Physical coordinates]
    B --> C[Held-out landmark fits]
    C --> D[2.5D crops and descriptors]
    D --> E[Nested head search]
    E --> F[Probability blend and RSNA CSV]
```

The project uses a pinned [shared training engine](https://github.com/ThorsenH1/medimage-ml-lab) and has a task-specific runner. The published artifact contains source, aggregate benchmark results, and synthetic examples. Dataset files, checkpoints, and individual evaluation predictions stay in local storage.

## Reproduce the experiment

Use Python 3.11, PowerShell 7, and a CUDA-capable GPU. The original workstation used an RTX 2080 SUPER with 8 GiB VRAM.

```powershell
python -m venv .venv
$p = './.venv/Scripts/python.exe'
& $p -m pip install torch==2.14.0+cu126 torchvision==0.29.0+cu126 --index-url https://download.pytorch.org/whl/cu126
& $p -m pip install -r requirements.txt
```

Set the data and pretrained weight locations for your machine. The initial ResNet-18 weight directory uses `hub/checkpoints/resnet18-f37072fd.pth`. The Hugging Face cache uses `refs/main` and `snapshots/<revision>/model.safetensors`. Use the Hugging Face snapshot for `timm/resnet18.a1_in1k`. [Initial ResNet-18 weights](https://download.pytorch.org/models/resnet18-f37072fd.pth)

```powershell
$data = 'D:/datasets/spine'
$torchCache = 'D:/models/torch'
$hf = 'D:/models/huggingface/hub'
pwsh -File scripts/Run-Project.ps1 -Task spine -Python $p -DataRoot $data -InitialWeights $torchCache -WeightRoot $hf
```

The runner writes the initial experiment under `artifacts/` and the extended search under `search-artifacts/`. For a larger volume, supply `-Artifacts` and `-Search` and use matching paths at inference. The prepared caches and training stages can resume from saved boundaries.

## Predict from raw input

Run the [spatial-detail reproduction commands](RESEARCH.md#reproduce-the-five-fold-comparison) to prepare the current deployment lock. The [prediction walkthrough](WALKTHROUGH.md) shows the raw DICOM commands for the current ensemble. To score the supplied real test study, use its dataset root and a reference prediction generated for that same study.

The [example](examples/README.md) runs the selected local models on deterministic synthetic inputs. This is a research and education project.
