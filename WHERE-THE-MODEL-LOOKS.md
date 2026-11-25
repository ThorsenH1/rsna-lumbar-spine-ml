# See the regions the MRI grader actually reads

![The synthetic spine, predicted centers, five exact model crops, and their full scores](examples/where-model-looked.png)

The turquoise points are the learned localizer's estimated centers for the five disc levels. The dashed box shows the central crop for L4–L5. Each thumbnail is the central slice from the exact three-slice original crop the first fold's grader received. The colored bars use the final ensemble, including the original and side-corrected reflected scores.

Some estimated centers miss the bright column in this generated image. The resulting crops near the edge are dark. The model still produces probabilities, so a score alone cannot tell you whether the model had a good view. This example shows why inspecting crop placement matters. [Complete trace with coordinates and scores](examples/study-trace.json)

The overlay shows the regions supplied to the grading model. The trace records how the original and reflected passes changed each grade probability. For grading and localization benchmarks, use the study-level [research results](RESEARCH.md). Follow the [end-to-end walkthrough](WALKTHROUGH.md) to generate the example and rebuild the figure.

## Compare two views of the same side region

![The original and tighter crop for the left subarticular region at L4–L5, alongside the final score](examples/lateral-zoom.png)

The boxes outline the regular crop in gold and the 20% narrower crop in turquoise. The target is narrowing in the left passage where a nerve root travels. The two crops use the same center and output size. In this synthetic study, the localizer placed the center near the upper edge, so both crops include black padding. The ensemble still assigns **0.54** to normal or mild. Look at the crop placement before interpreting that score. The synthetic study has no clinical grade.

```powershell
& $p -m medimage.spine_region_explain --cache "$example/cache" `
    --trace "$example/study-trace.json" --output "$example/where-model-looked.png" `
    --zoom-output "$example/lateral-zoom.png"
```
