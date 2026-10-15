# Introgression Detection Practical

## Overview

In this practical, we will use **pan-k-mers** to investigate potential introgression in *Solanum aethiopicum* by comparing its pan-k-mer bitmaps with those of *Solanum anguivi*, a wild relative.

By the end of this exercise, you should be able to:

* Query pan-k-mer bitmaps using the Panagrams API.
* Visualise pan-k-mer distributions across chromosomes.
* Compare patterns between two species.
* Identify genomic regions that could be candidates for introgression.

## 1. Download and prepare the data

First, download the practical data archive:

[**Download introgression_practical.tar.gz**](https://drive.google.com/file/d/1Ad8ik8SA-ZI0QBHR8QCweG-yhboGPRHL/view?usp=sharing)

Open a terminal and extract the archive:

```bash
tar -xzf introgression_practical.tar.gz
```

Navigate into the extracted directory:

```bash
cd introgression_practical
```

Take a moment to explore the contents of the directory.

## 2. Explore the query script

The directory contains a script called `query_pankmer_bitmap.py`. This script uses the **Panagrams API** to query pan-k-mer bitmaps.

Start by exploring the script's help message:

```bash
python query_pankmer_bitmap.py --help
```

Use the help output to familiarise yourself with the available arguments and options.

**Your task:**

* What arguments does the script require?
* How do you specify a species or chromosome?
* What options are available for querying or plotting a bitmap?

Experiment with the help commands and identify the options you will need for the following steps.

## 3. Visualise *Solanum aethiopicum*

We will first examine the pan-k-mer bitmap for *Solanum aethiopicum*.

Using the options you discovered in the previous section, run the script to plot the bitmap for **all chromosomes of *S. aethiopicum***.

Inspect the resulting plots.

**Questions to consider:**

* What patterns do you observe across the chromosomes?
* Are there regions with noticeably different patterns from their surroundings?
* Do any chromosomes contain unusual or unexpected regions?

Record any interesting observations.

## 4. Visualise *Solanum anguivi*

Next, repeat the analysis for *Solanum anguivi*, the wild relative of *S. aethiopicum*.

Run the script to plot the bitmap for **all chromosomes of *S. anguivi***.

Inspect the resulting plots and note any similarities or differences compared with *S. aethiopicum*.

**Questions to consider:**

* How do the bitmap patterns compare between the two species?
* Are there regions that appear similar in one species but different in the other?
* Do any patterns suggest that particular genomic regions may have a different evolutionary history?

## 5. Identify candidate introgressions

Now compare the plots from both species.

Introgression occurs when genetic material from one population or species is incorporated into another through hybridisation and subsequent breeding. Introgressed regions may therefore show patterns that differ from the expected genomic background.

**Your task:** Identify any regions that could be candidate introgressions.

For each candidate region, record:

* **Species:** Which species' bitmap are you examining?
* **Chromosome:** Where is the region located?
* **Approximate position:** What genomic interval does it span?
* **Evidence:** What pattern makes the region interesting?
* **Interpretation:** Why might this region be a candidate for introgression?

Remember that **an unusual bitmap pattern is a clue, not proof of introgression**. Further analyses and independent evidence would be needed to confirm the evolutionary origin of a region.

## 6. Discussion

Discuss your findings with the group:

1. Did you identify any regions that could represent introgression?
2. Which patterns were most informative when comparing the two species?
3. What alternative explanations could account for the patterns you observed?
4. What additional analyses or data would help confirm the candidate regions?

## Take-home message

Pan-k-mer bitmaps provide a way to explore genomic patterns across species and identify regions worthy of further investigation. In this practical, you have used visual comparisons to generate hypotheses about possible introgression between *Solanum aethiopicum* and *Solanum anguivi*.
