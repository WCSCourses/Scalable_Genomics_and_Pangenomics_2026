# Introgression Detection Practical

## Overview

In this practical, we will use **pan-k-mers** to investigate potential introgression in *Solanum aethiopicum* by comparing its pan-k-mer bitmaps with those of *Solanum anguivi*, a wild relative.

By the end of this exercise, you should be able to:

* Query pan-k-mer bitmaps using the Panagrams API.
* Visualise pan-k-mer distributions across chromosomes.
* Compare patterns between two species.
* Identify genomic regions that could be candidates for introgression.


## 0. How the data/pangenome was made

To facilitate a smooth and fast practical, I have already run a set of *S. aethiopicum* genomes plus 1 *S. anguivi* genome through [**Panagram**](https://github.com/kjenike/panagram).

If you really, really want to run through everything on your own you can download the data here. 

The first step of Panagram to build a samples.tsv file that lists all of the fasta files that you want to include in your pangenome. For this example, the samples file looks like this: 

```
name    fasta   gff     id      anchor
Saethiopicum    FASTAS/Saethiopicum_edited.fasta                0       True
Solaet1371      FASTAS/Solaet1371_edited.fasta          1       True
Solaetbc2060    FASTAS/Solaetbc2060_edited.fasta                2       True
Solaetbc2063    FASTAS/Solaetbc2063_edited.fasta                3       True
Solaetbc2066    FASTAS/Solaetbc2066_edited.fasta                4       True
Solaetbc2072    FASTAS/Solaetbc2072_edited.fasta                5       True
Solaetbc2073    FASTAS/Solaetbc2073_edited.fasta                6       True
Solaetbc2074    FASTAS/Solaetbc2074_edited.fasta                7       True
SolaetSC103     FASTAS/SolaetSC103_edited.fasta         8       True
SolaetSID104435 FASTAS/SolaetSID104435_edited.fasta             9       True
SolaetSID104440 FASTAS/SolaetSID104440_edited.fasta             10      True
Solang8 FASTAS/Solang8_edited.fasta             11      True
```

Then you prepare the data with this command:

```
panagram index samples.tsv -k 31 --prepare
```

Notice that for this dataset we are using k=31. The time and disk space requirements will change based on k. Also note that this step may take some time if the fasta files are not yet indexed. Once an *.fai file has been generated once Panagram won't need to make that again and the --prepare step will be faster. 

The next step is to run the indexing, which uses snakemake. 

```
snakemake --cores 12 all
```

With 12 cores it took about 32 minutes to run a 12 genome pangenome through Panagram. 


## 1. Download the data

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

Make sure the data is there! Do you see a directory called "anchor"? 

Open the samples.tsv file. There are 12 samples, 11 of which are *S. aethiopicum* accessions while the last sample (named Solang8) is *S. anguivi*. 

The first sample, named Saethiopicum, is the reference *S. aethiopicum*. 

## 2. Explore the query script

The directory contains a script called `query_pankmer_bitmap.py`. This script uses the **Panagrams API** to query pan-k-mer bitmaps.

Start by exploring the script's help message:

```
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

<details>
<summary>The command I would recommend</summary>

```
python query_pankmer_bitmap.py \
                --anchor Saethiopicum \
                --all-chromosomes
                --index-dir . \
                --font-size 20 \
                --width 600 \
                --height 400 \
                --png-scale 2 \
                --formats png
```
</details>

Inspect the resulting plots.

**Questions to consider:**

* What patterns do you observe across the chromosomes?
* Are there regions with noticeably different patterns from their surroundings?
* Do any chromosomes contain unusual or unexpected regions?
* What is the difference between multiplicity and containment?

## 4. Visualise *Solanum anguivi*

Next, repeat the analysis for *Solanum anguivi*, the wild relative of *S. aethiopicum*.

Run the script to plot the bitmap for **all chromosomes of *S. anguivi***.

Inspect the resulting plots and note any similarities or differences compared with *S. aethiopicum*.

<details>
<summary>The command I would recommend</summary>

```
python query_pankmer_bitmap.py \
                --anchor Solang8 \
                --all-chromosomes
                --index-dir . \
                --font-size 20 \
                --width 600 \
                --height 400 \
                --png-scale 2 \
                --formats png
```

</details>

**Questions to consider:**

* How do the bitmap patterns compare between the two species?
* Are there regions that appear similar in one species but different in the other?
* Do any patterns suggest that particular genomic regions may have a different or unexpected evolutionary history?

In case you are unable to run the querying all of the outputs are located here: 

https://github.com/WCSCourses/Scalable_Genomics_and_Pangenomics_2026/tree/main/course_modules_2026/module_7_introgressions/Solanum_plots

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

## 6. Discussion

Discuss your findings with the group:

1. Did you identify any regions that could represent introgression?
2. Which patterns were most informative when comparing the two species?
3. What alternative explanations could account for the patterns you observed?
4. What additional analyses or data would help confirm the candidate regions?

## Take-home message

Pan-k-mer bitmaps provide a way to explore genomic patterns across species and identify regions worthy of further investigation. In this practical, you have used visual comparisons to generate hypotheses about possible introgression between *Solanum aethiopicum* and *Solanum anguivi*.
