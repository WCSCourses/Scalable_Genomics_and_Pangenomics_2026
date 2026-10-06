# Practical 1 - Build Your Own Pangenome

There are many notions of what a pangenome is:

- A sequence graph representing the variation present in the set of genomes
- A compressed index of each genome as a text that is queryable
- A catalog of variation and conservation

In this practical session, we will run a few tools that “build” different notions of a pangenome and walk through how each lets us visualize and query our dataset.

**Docker Image with all the tools pre-installed:** [npmalfoy/scalable:2026](https://hub.docker.com/r/npmalfoy/scalable) (`linux/amd64`)

**Course data (FTP):** [https://ftp.ebi.ac.uk/pub/databases/metagenomics/research-team/shivakumar/scalable_course/](https://ftp.ebi.ac.uk/pub/databases/metagenomics/research-team/shivakumar/scalable_course/)

> Expected runtimes and memory below are rough guidelines based on running on an M5 MacBook Pro (Docker `linux/amd64`). Your machine may differ; larger datasets than the yeast examples will take longer and use more RAM.

---



## Learning objectives

In this practical you will:

1. Run each tool on a small set of genome assemblies
2. Understand the inputs and outputs of each method
3. Explain the pros and cons of each method and which method is appropriate for different types of pangenomes

---



## 0) Pull the docker container and datasets

See the course informatics guide for full setup instructions. Start in a clean working directory with the course tar archives downloaded, then unpack and start an interactive session:

**Unpack:**

```bash
mkdir -p datasets
tar -xzf datasets_agc.tar.gz -C datasets
tar -xzf course_data.tar.gz
# needed for impg index step:
tar -xzf alignments_athaliana.tar.gz   # → data/athaliana/alignments.paf
mkdir -p data/work
```

**Docker:**

```bash
docker pull npmalfoy/scalable:2026
docker run --rm -it --platform linux/amd64 -v "$PWD:/course" -w /course npmalfoy/scalable:2026
```

**Singularity / Apptainer:**

```bash
apptainer pull scalable-2026.sif docker://npmalfoy/scalable:2026

apptainer shell \
  --bind "$PWD:/course" \
  --pwd /course \
  scalable-2026.sif
```

> Use `singularity` in place of `apptainer` if that is what your cluster provides. On Apple Silicon (or other arm64 hosts), keep `--platform linux/amd64` for Docker.

Inside the container, paths use `/course/...` (AGCs under `/course/datasets`, pre-built outputs under `/course/data`, writable outputs under `/course/data/work`).

To test that the tools are installed and available:

```bash
which agc ropebwt3 syng impg BandageNG panacus vg mumemto shredtools minimap2
```

We provided a few datasets to choose from depending on your computing setup and species of interest. We provide an AGC file for each dataset:

- *A. thaliana* full genomes (n=5)
- *A. thaliana* chr5 (n=5)
- Human full genomes (n=5)
- Human chr20 (n=5)
- *S. cerevisiae* full genomes (n=22)

You may also run any of the tools on your own dataset of interest!
For an added challenge, pick two datasets from above and compare the outputs. 

---



## 1) Run each tool on your chosen dataset

In this section, we will run each of the tools on a dataset of your choosing. We will provide pre-computed outputs for the following sections, as some tools may be slow or memory intensive on personal machines.

We highly encourage you to use the help pages (`toolname -h`) and documentation to devise a command to run first. For each tool, we provide a command to run in the dropdown menu (using the yeast dataset as an example.)

Set shared paths once for this section (reuse them below; only create tool-specific output dirs as needed):

```bash
DATASETS=/course/datasets
DATA=/course/data
OUT=/course/data/work
AGC=$DATASETS/yeast_t2t_haploid.agc
FASTA_DIR=$OUT/fastas
mkdir -p "$OUT" "$FASTA_DIR" "$OUT/tool_outputs"
```



### AGC

[AGC](https://github.com/refresh-bio/agc) stores many genomes in one compressed archive. If you are using the provided datasets, you can use AGC to decompress the archives into a set of FASTA files.

**Expect (yeast example):** a few seconds; <0.1 GB RAM.

Task: Inspect the AGC archive and decompress it into a set of FASTA files for the downstream tools.

<details>
<summary>Show agc example command</summary>

```bash
agc info "$AGC"
agc listset "$AGC" | head
agc getcol -o "$FASTA_DIR" "$AGC"
ls "$FASTA_DIR" | head
```

</details>

Inputs: an AGC archive (`.agc`)

Outputs: a directory of FASTA files (one file per sample)

---



### Mumemto / Shredtools

[Mumemto](https://github.com/vikshiv/mumemto) reports maximal unique matches across a set of assemblies. These matches represent conserved columns in the underlying multiple sequence alignment. Shredtools is a companion tool to Mumemto that indexes the MUMs list for querying.

**Expect (yeast example):** mumemto ~2–3 min and ~2–3 GB RAM; shredtools filter/index a few seconds each and <0.5 GB.

Task: run Mumemto on the set of assemblies to create a `bumbl` file containing the MUMs. Then filter and index the set of MUMs for querying.

```bash
mkdir -p "$OUT/tool_outputs/mumemto"
```

<details>
<summary>Show mumemto example command</summary>

```bash
mumemto -o "$OUT/tool_outputs/mumemto/mumemto" -b "$FASTA_DIR"/*.fa
```

</details>

<details>
<summary>Show shredtools example command</summary>

```bash
shredtools filter -i "$OUT/tool_outputs/mumemto/mumemto.bumbl"
shredtools index --multi "$OUT/tool_outputs/mumemto/mumemto.bumbl" -v
```

</details>

Inputs: a set of FASTA files

Outputs: a `bumbl` file, a binary file that contains a list of exact matches and their locations in each assembly

<details>
<summary>How to view the output <code>bumbl</code> file</summary>

```bash
mumemto view "$OUT/tool_outputs/mumemto/mumemto.bumbl" | less
```

</details>

Extra exercises:

<details>
<summary>Compute the coverage of MUMs (how much of a given assembly is “shared” and unique across the pangenome?)</summary>

```bash
mumemto coverage -i "$OUT/tool_outputs/mumemto/mumemto.bumbl"
```

</details>

<details>
<summary>Compute the average MUM length</summary>

```bash
mumemto view "$OUT/tool_outputs/mumemto/mumemto.bumbl" | awk '{s+=$1;n++} END{print n?s/n:0}'
```

</details>



---



### ropebwt3

[ropebwt3](https://github.com/lh3/ropebwt3) builds an FM-index (a compressed text index) over the collection of genomes and supports MEM queries.

**Expect (yeast example):** `.fmr` build ~2–3 min and ~0.5 GB RAM; `.fmd` conversion a few seconds and ~0.1 GB.

Task: Build an FM-index over the set of assemblies (dynamic `.fmr`, then static `.fmd`).

```bash
mkdir -p "$OUT/tool_outputs/ropebwt3"
```

<details>
<summary>Show ropebwt3 example command</summary>

```bash
# constructs the dynamic version, needed initially to build the index
ropebwt3 build -bo "$OUT/tool_outputs/ropebwt3/rb3.fmr" "$FASTA_DIR"/*.fa
# constructs the static version, faster and more efficient to load, but no longer can add new assemblies
ropebwt3 build -i "$OUT/tool_outputs/ropebwt3/rb3.fmr" -do "$OUT/tool_outputs/ropebwt3/rb3.fmd"
```

</details>

Inputs: a set of FASTA files

Outputs: a dynamic BWT (`.fmr`) and a static FM-index (`.fmd`)

Extra exercise:

Compute the size of the BWT

```bash
ropebwt3 stat "$OUT/tool_outputs/ropebwt3/rb3.fmd"
```

---



### syng

[syng](https://github.com/richarddurbin/syng) builds a syncmer graph of the assemblies. Syncmers are specially chosen kmers that cover the full sequence, and are often shared across a pangenome. To navigate the graph, syng also builds a GBWT, which enables rapid stepping through the graph for querying.

**Expect (yeast example):** a few seconds for `syng` + `syngpath2gbwt`; ~0.2 GB RAM.

Task: Build a syncmer path graph of the assemblies, then convert the paths into a GBWT for querying.

```bash
mkdir -p "$OUT/tool_outputs/syng"
```

<details>
<summary>Show syng example command</summary>

```bash
syng -o "$OUT/tool_outputs/syng/syng" -writeK -writePath "$FASTA_DIR"/*.fa
syngpath2gbwt "$OUT/tool_outputs/syng/syng.1path" "$OUT/tool_outputs/syng/syng.1gbwt"
```

</details>

Inputs: a set of FASTA files

Outputs: syng path / kmer files (e.g. `.1path`) and a GBWT (`.1gbwt`)

---



### impg

[impg](https://github.com/pangenome/impg) indexes and enables querying of genomic intervals across a pangenome using all-vs-all pairwise genome alignments. Running all pairs alignments is slow without a multi-CPU machine, so for this step we provide pre-computed *A. thaliana* alignments (`alignments_athaliana.tar.gz` — unpacks to `data/athaliana/alignments.paf`). The index you build here is what you will use in Practical 2.

**Expect (indexing step only):** a few seconds; ~0.2 GB RAM.

Task: Build an `impg` index over the shipped *A. thaliana* all-vs-all PAF.

```bash
IMPG_PAF=$DATA/athaliana/alignments.paf
IMPG_IDX=$OUT/alignments.paf.impg
```

<details>
<summary>Show impg index example command</summary>

```bash
impg index -a "$IMPG_PAF" -i "$IMPG_IDX"
```

</details>

Inputs: all-vs-all pairwise alignments (PAF)

Outputs: an `.impg` index

---



### vg

[vg](https://github.com/vgteam/vg) is a toolkit to manipulate variation graphs (such as those produced by [minigraph-cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md)). Here we build a Giraffe index for read mapping from a variation graph.

We provide a pre-shipped MHC graph in GFA format (minigraph-cactus) under `$DATA/human/mhc/mhc.full.gfa.gz`, plus a linear CHM13 sequence for the same region. Pre-built Giraffe indexes are also available under `$DATA/human/vg_giraffe/` if you prefer to skip indexing.

**Expect:** MHC GFA autoindex ~15–30 s and ~0.5–1 GB RAM; CHM13 linear autoindex a few seconds and ~0.5–1 GB.

Task: Build a `vg giraffe` index from the MHC GFA. Also build an index for the CHM13 linear sequence.

```bash
mkdir -p "$OUT/vg_giraffe/mhc" "$OUT/vg_giraffe/mhc_chm13"
```

<details>
<summary>Show solution</summary>

```bash
gunzip -c "$DATA/human/mhc/mhc.full.gfa.gz" > "$OUT/vg_giraffe/mhc/mhc.full.gfa"
vg autoindex --workflow lr-giraffe -g "$OUT/vg_giraffe/mhc/mhc.full.gfa" -p "$OUT/vg_giraffe/mhc/mhc"
vg autoindex --workflow lr-giraffe -r "$DATA/human/mhc/mhc_chm13.fa" -p "$OUT/vg_giraffe/mhc_chm13/mhc_chm13"
```

</details>

Inputs: a variation graph in GFA format (and optionally a linear FASTA)

Outputs: long-read Giraffe indexes (e.g. `.giraffe.gbz`, `.dist`, and `.longread.withzip.min` / zipcode files)

---



## Next: Practical 2

The indexes and tool outputs you wrote under `$OUT` (`/course/data/work`) — mumemto / ropebwt3 / syng under `tool_outputs/`, the impg index, and the Giraffe indexes under `vg_giraffe/` — are the inputs for **Practical 2** (visualizing and querying a pangenome). If a step was slow or you skipped it, use the matching pre-built files under `$DATA`.


---



## Reference: yeast solution outputs (optional)

You do not need these for the practical. If you could not run the yeast builds above and just want to see what the outputs look like, reference copies of the mumemto / ropebwt3 / syng yeast indexes are shipped under:

```text
$DATA/yeast/tool_outputs/{mumemto,ropebwt3,syng}/
```

Practical 2 uses the *A. thaliana* pre-builts under `$DATA/athaliana/tool_outputs/`, not these yeast files.
