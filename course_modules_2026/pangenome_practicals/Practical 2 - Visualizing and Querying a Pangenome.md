# Practical 2 - What do we do with a pangenome?

In this practical session, we will try a few visualizations and queries that let us explore our pangenome collection. Most of these steps are follow ups to the previous section, where we built various types of indexes and representations of a "pangenome" for small datasets of genome assemblies. The next question is: what can we do with these pangenomes?

**Docker Image with all the tools pre-installed:** [vikshiv/scalable-course:latest](https://hub.docker.com/r/vikshiv/scalable-course) (`linux/amd64`)

**Course data (FTP):** [https://ftp.ebi.ac.uk/pub/databases/metagenomics/research-team/shivakumar/scalable_course/](https://ftp.ebi.ac.uk/pub/databases/metagenomics/research-team/shivakumar/scalable_course/)

---

## Learning objectives

In this practical you will:

1. Explore how to visualize the outputs for pangenome exploration
2. Learn what types of queries each type of pangenome index is suitable for

---



## 0) Pull the docker container and datasets

See the course informatics guide for full setup instructions. After unpacking the course archives into `datasets/` (AGCs) and `data/` (pre-built outputs) in your working directory, start an interactive session with both directories mounted:

**Docker:**

```bash
docker pull vikshiv/scalable-course:latest

mkdir -p work
docker run --rm -it \
  --platform linux/amd64 \
  -v "$PWD/datasets:/data/datasets:ro" \
  -v "$PWD/data:/data/data:ro" \
  -v "$PWD/work:/data/work" \
  vikshiv/scalable-course:latest
```

**Singularity / Apptainer:**

```bash
apptainer pull scalable-course.sif docker://vikshiv/scalable-course:latest

mkdir -p work
apptainer shell \
  --bind "$PWD/datasets:/data/datasets:ro,$PWD/data:/data/data:ro,$PWD/work:/data/work" \
  scalable-course.sif
```

> Use `singularity` in place of `apptainer` if that is what your cluster provides. On Apple Silicon (or other arm64 hosts), keep `--platform linux/amd64` for Docker.

Inside the container, AGCs are under `/data/datasets`, pre-built outputs under `/data/data`, and writable outputs under `/data/work`.

**Course data downloads** (from the [FTP directory](https://ftp.ebi.ac.uk/pub/databases/metagenomics/research-team/shivakumar/scalable_course/)). Unpack these next to each other in your working directory (so you end up with `datasets/` and `data/`):


| Archive                       | Required?       | Contents                                                         |
| ----------------------------- | --------------- | ---------------------------------------------------------------- |
| `datasets_agc.tar.gz`         | yes             | AGC assemblies                                                   |
| `course_data.tar.gz`          | yes             | pre-built indexes / tool outputs / reads / MHC graph             |
| `alignments_athaliana.tar.gz` | optional (~16G) | `$DATA/athaliana/alignments.paf.gz` (needed for the `impg` step) |
| `alignments_human.tar.gz`     | optional (~5G)  | `$DATA/human/alignments.paf`                                     |


```bash
# core (always)
mkdir -p datasets
tar -xzf datasets_agc.tar.gz -C datasets
tar -xzf course_data.tar.gz

# optional — only if you want the large all-vs-all PAFs
tar -xzf alignments_athaliana.tar.gz   # → data/athaliana/alignments.paf.gz
tar -xzf alignments_human.tar.gz       # → data/human/alignments.paf
```



To test that the tools are installed and available:

```bash
which agc ropebwt3 syng impg BandageNG panacus vg mumemto shredtools panagram minimap2
```

Following the previous practical, we will provide pre-built datasets for each step below. First, decompress the 68 *A. thaliana* assemblies from the AGC archive into a local FASTA directory:

```bash
OUT=/data/work/
DATA=/data/data
AGC=/data/datasets/athaliana_all.agc
FASTA_DIR=$OUT/athaliana_fastas
ATH_OUT=$DATA/athaliana/tool_outputs
ANALYSIS_DIR=$OUT/analysis
PAN_DIR=$OUT/panagram

mkdir -p "$OUT" "$FASTA_DIR" "$ANALYSIS_DIR"
```

<details>
<summary>Show AGC decompress command</summary>

```bash
agc info "$AGC"
agc listset "$AGC" | head
agc getcol -o "$FASTA_DIR" "$AGC"
ls "$FASTA_DIR" | head
```

</details>



Important: to run panagram, we need to point to this decompressed directory of FASTAs:

<details>
<summary>Show panagram FASTA staging command</summary>

```bash
# copy pre-built panagram outputs (no FASTAS) into the work dir
mkdir -p "$PAN_DIR"
cp -a "$ATH_OUT/panagram/." "$PAN_DIR/"
mkdir -p "$PAN_DIR/FASTAS"

# samples.tsv uses underscore sample names; AGC sample names use dots
for f in "$FASTA_DIR"/*.fa; do
  base=$(basename "$f" .fa)
  ln -sfn "$f" "$PAN_DIR/FASTAS/$(echo "$base" | tr '.' '_').fa"
done
ls "$PAN_DIR/FASTAS" | head
```

</details>



---



## 1) How to use each pangenome representation



### Mumemto / Shredtools

We've computed the set of multi-MUMs across the pangenome. In general for useful downstream analysis, we want the multi-MUM coverage to be >50% across the collection. Lower coverage likely indicates more dissimilar assemblies or high repeat content.

First, we will visualize the multi-MUM synteny of *A. thaliana* genomes. Since each assembly has the same number of contigs, we can split the visualization by chromosome using `mumemto viz --mode gapped`.

<details>
<summary>Show mumemto command</summary>

```bash
mumemto viz -o "$ANALYSIS_DIR/mumemto.pdf" -i "$ATH_OUT/mumemto/mumemto" --mode gapped
```

</details>



Next, we can query a region of interest and extract syntenic regions across the pangenome using `shredtools extract`. For this exercise, we will extract the FLC gene involved in flowering using the following region: `chr5:3,173,000–3,179,000`. Precomputed outputs live under `$ATH_OUT/mumemto/` (`mumemto.bumbl`, `mumemto.bumbl.bi`, `mumemto.lengths`).

<details>
<summary>Show shredtools command</summary>

```bash
shredtools extract -o "$ANALYSIS_DIR/flc" -s 0 -r CP138175.1:3173000-3179000 --plot "$ATH_OUT/mumemto/mumemto.bumbl"
```

</details>



---



### ropebwt3

We previously generated an FM-index using ropebwt3. There are a few things we can do, all centered around finding exact matches between a query and the index.

The first command is `mem`. We will query a set of reads against the index and find all the MEMs (maximal exact match) that appear between a read and the index.

<details>
<summary>Show ropebwt3 mem command</summary>

```bash
ropebwt3 mem "$ATH_OUT/ropebwt3/rb3.fmd" "$DATA/athaliana/reads/tanz1_1k.fq" > "$ANALYSIS_DIR/read_mems.txt"
```

</details>



Next, we can query an assembly against the index and compute kmer diversity with respect to the pangenome. This is helpful to identify regions that are highly similar or dissimilar in a query assembly with respect to the population. For this, we can use the `ropebwt3 hapdiv` command.

We've held out Tanz-1 from the ropebwt3 index (`$DATA/athaliana/holdout/Tanz-1.fa`), but it is included in the mumemto collection so we can recover its FLC locus from the BED produced above. Pull that sequence with `shredtools fasta`, then run `hapdiv` on the short FLC FASTA (querying the full Tanz-1 genome is slow on a laptop).

<details>
<summary>Show ropebwt3 hapdiv command</summary>

```bash
grep Tanz-1 "$ANALYSIS_DIR/flc.bed" > "$ANALYSIS_DIR/flc_tanz.bed"
shredtools fasta -o "$ANALYSIS_DIR/flc_fa" "$ANALYSIS_DIR/flc_tanz.bed"
ropebwt3 hapdiv "$ATH_OUT/ropebwt3/rb3.fmd" "$ANALYSIS_DIR/flc_fa/"*extract*.fa > "$ANALYSIS_DIR/hapdiv.txt"
```

</details>



---



### syng

We previously built a syncmer dictionary (`.1khash`) and GBWT (`.1gbwt`) with syng. Analogous to ropebwt3's MEMs over bases, `syngmap` finds MEMs over syncmers between a query read set and the pangenome GBWT.

<details>
<summary>Show syngmap command</summary>

```bash
syngmap -o "$ANALYSIS_DIR/syngmap" -outputIds "$ATH_OUT/syng/syng.1khash" "$ATH_OUT/syng/syng.1gbwt" "$DATA/athaliana/reads/tanz1_1k.fq"
```

</details>



---



### impg

We can project the same FLC gene region through the all-vs-all alignments, extract the homologous sequences across the pangenome, and build a local variation graph with `impg`.

This step needs the optional *A. thaliana* PAF (`alignments_athaliana.tar.gz`). Confirm it is present:

```bash
ls -lh "$DATA/athaliana/alignments.paf.gz" "$DATA/athaliana/all.impg"
```

If `alignments.paf.gz` is missing, unpack that archive into your course directory (outside the container) and restart / remount so `/data/data/athaliana/alignments.paf.gz` is visible.

Task: Query the FLC region (`CP138175.1:3173000-3179000`) from the *A. thaliana* alignments and build a GFA graph of the homologous sequences.

<details>
<summary>Show impg command</summary>

```bash
impg query -i "$DATA/athaliana/all.impg" -a "$DATA/athaliana/alignments.paf.gz" -r "CP138175.1:3173000-3179000" -d 1000 -x -o gfa --sequence-files "$FASTA_DIR"/*.fa -O "$ANALYSIS_DIR/flc"
```

</details>



Inputs: all-vs-all pairwise alignments (PAF), the corresponding FASTA sequences, and a query interval

Outputs: extracted homologous FASTA sequences aligned into a local GFA graph (`flc.gfa`)

---



### BandageNG

[BandageNG](https://github.com/asl/BandageNG) visualises assembly / variation graphs. Here we render the FLC graph built with impg above.

Task: Produce an image of the FLC variation graph.

<details>
<summary>Show BandageNG command</summary>

```bash
BandageNG image "$ANALYSIS_DIR/flc.gfa" "$ANALYSIS_DIR/flc.svg"
```

</details>



Inputs: a variation graph in GFA format

Outputs: an SVG image of the graph layout

---



### panacus

[panacus](https://github.com/codialab/panacus) computes coverage and growth statistics over a pangenome graph (GFA). This is useful for determining how much of the pangenome is core vs accessory based on the multiple alignment encoded in the graph topology.

Task: Build an HTML report with coverage histogram and growth curves for the FLC graph from impg.

<details>
<summary>Show panacus example command</summary>

```bash
cat > "$ANALYSIS_DIR/flc_report.yaml" <<EOF
- !Gfa
  graph: $ANALYSIS_DIR/flc.gfa
  count_type: Bp
  analyses:
    - !Hist
    - !Growth
      coverage: 1,1,2
      quorum: 0,0.9,0
EOF

panacus report "$ANALYSIS_DIR/flc_report.yaml" > "$ANALYSIS_DIR/flc_report.html"
```

</details>



Inputs: a variation graph in GFA format

Outputs: an interactive HTML report (`flc_report.html`) with histogram and growth analyses

---



### vg giraffe

In Practical 1 we built two Giraffe indexes for the MHC region (also provided under `$DATA/human/vg_giraffe/`):

- `$DATA/human/vg_giraffe/mhc` — variation graph over the 5 human haplotypes
- `$DATA/human/vg_giraffe/mhc_chm13` — linear CHM13 sequence for the same region

Task: Align the provided human HiFi long reads with `vg giraffe` against **both** indexes and compare the resulting alignments.

<details>
<summary>Show solution</summary>

```bash
# map against the 5-haplotype MHC graph (long-read indexes + hifi preset)
vg giraffe -b hifi \
  -Z "$DATA/human/vg_giraffe/mhc/mhc.giraffe.gbz" \
  -d "$DATA/human/vg_giraffe/mhc/mhc.dist" \
  -m "$DATA/human/vg_giraffe/mhc/mhc.longread.withzip.min" \
  -z "$DATA/human/vg_giraffe/mhc/mhc.longread.zipcodes" \
  -f "$DATA/human/reads/i002c_mhc_1k.fa" > "$ANALYSIS_DIR/reads.mhc.gam"

# map against the linear CHM13 MHC index
vg giraffe -b hifi \
  -Z "$DATA/human/vg_giraffe/mhc_chm13/mhc_chm13.giraffe.gbz" \
  -d "$DATA/human/vg_giraffe/mhc_chm13/mhc_chm13.dist" \
  -m "$DATA/human/vg_giraffe/mhc_chm13/mhc_chm13.longread.withzip.min" \
  -z "$DATA/human/vg_giraffe/mhc_chm13/mhc_chm13.longread.zipcodes" \
  -f "$DATA/human/reads/i002c_mhc_1k.fa" > "$ANALYSIS_DIR/reads.mhc_chm13.gam"
```

</details>

Inputs: long-read Giraffe indexes from Practical 1 (`lr-giraffe`) and long HiFi reads

Outputs: GAM alignments for each index