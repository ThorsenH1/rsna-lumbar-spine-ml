# See the regions the MRI grader actually reads

![The synthetic spine, predicted centers, five exact model crops, and their full scores](examples/where-model-looked.png)

The turquoise points are the learned localizer's estimated centers for the five disc levels. The dashed box shows the central crop for L4–L5. Each thumbnail is the central slice from the exact three-slice crop the first fold's new grader received. The colored bars are the final ensemble probabilities for each spinal canal target.

Some estimated centers miss the bright column in this generated image. The resulting crops near the edge are dark. The model still produces probabilities, so a score alone cannot tell you whether the model had a good view. This example shows why inspecting crop placement matters. [Complete trace with coordinates and scores](examples/study-trace.json)

The location overlay shows the image supplied to the selected grading model. It does not indicate which individual pixels inside that crop contributed most to a score. For actual grading and localization benchmarks, use the study-level [research results](RESEARCH.md). Follow the [end-to-end walkthrough](WALKTHROUGH.md) to generate the example and rebuild the figure.

```powershell
& $p -m medimage.spine_region_explain --cache "$example/cache" `
    --trace "$example/study-trace.json" --output "$example/where-model-looked.png"
```
