# Practical 2 - What do we do with a pangenome?

In this practical session, we will try a few visualizations and queries that let us explore our pangenome collection. Most of these steps are follow ups to the previous section, where we built various types of indexes and representations of a "pangenome" for small datasets of genome assemblies. The next question is: what can we do with these pangenomes?

**Docker Image with all the tools pre-installed:** [vikshiv/scalable-course:latest](https://hub.docker.com/r/vikshiv/scalable-course) (`linux/amd64`)

---

## Learning objectives

In this practical you will:

1. Explore how to visualize the outputs for pangenome exploration
2. Learn what types of queries each type of pangenome index is suitable for

---



## 0) Pull the docker container and datasets

See the course informatics guide for instructions on using the docker image.

To test that the tools are installed and available:

```bash
which agc ropebwt3 syng impg BandageNG panacus vg mumemto shredtools panagram minimap2
```

Next, follow the informatics guide to start an interactive terminal session inside the container, mounting the datasets directory. 

Following the previous practical, we will provide pre-built datasets for each step below. 

```bash
OUT=/data/work/
DATA=/data/datasets/analysis
ANALYSIS_DIR=$OUT/analysis

mkdir -p "$OUT" "$ANALYSIS_DIR"
```

---



## 1) How to use each pangenome representation

### Mumemto / Shredtools
TODO: finalize FLC coords

We've computed the set of multi-MUMs across the pangenome. In general for useful downstream analysis, we want the multi-MUM coverage to be >50% across the collection. Lower coverage likely indicates more dissimilar assemblies or high repeat content.

First, we will visualize the multi-MUM synteny of *A. thaliana* genomes. Since each assembly has the same number of contigs, we can split the visualization by chromosome using `shredtools viz --mode gapped`. 
<details>
<summary>Show mumemto example command</summary>

```bash
mumemto viz -o "$ANALYSIS_DIR/mumemto.pdf" -i "$OUT/mumemto" --mode gapped
```
</details>

Next, we can query a region of interest and extract syntenic regions across the pangenome using `shredtools extract`. For this exercise, we will extract the FLC gene involved in flowering using the following region: `chr5:3,173,000–3,179,000`.

<details>
<summary>Show shredtools example command</summary>
```bash
shredtools extract -o "$ANALYSIS_DIR/flc" -s 0 -r CP138175.1:3173000-3179000 --plot "$OUT/mumemto.bumbl"
```
</details>

### Ropebwt3
TODO: get reads and query assembly and finalize index

We previously generated an FM-index using ropebwt3. There are a few things we can do, all centered around finding exact matches between a query and the index. 

The first command is `mem`. We will query a set of reads against the index and find all the MEMs (maximal exact match) that appear between a read and the index.
<details>
<summary>Show ropebwt3 mem command</summary>
```bash
ropebwt3 mem "$OUT/rb3.fmd" "$DATA/reads.fa" > "$ANALYSIS_DIR/read_mems.txt"  
```
</details>

Next, we can query an assembly against the index and compute kmer diversity with respect to the pangenome. This is helpful to identify regions that are highly similar or dissimilar in a query assembly with respect to the population. For this, we can use the `ropebwt3 hapdiv` command.

<details>
<summary>Show ropebwt3 hapdiv command</summary>
```bash
ropebwt3 hapdiv "$OUT/rb3.fmd" "$DATA/assembly.fa" > "$ANALYSIS_DIR/hapdiv.txt"  
```
</details>

### Syng
TODO: get reads (same read set as ropebwt3)

We previously built a syncmer dictionary (`.1khash`) and GBWT (`.1gbwt`) with syng. Analogous to ropebwt3's MEMs over bases, `syngmap` finds MEMs over syncmers between a query read set and the pangenome GBWT.

<details>
<summary>Show syngmap command</summary>
```bash
syngmap -o "$ANALYSIS_DIR/syngmap" -outputIds "$OUT/syng.1khash" "$OUT/syng.1gbwt" "$DATA/reads.fa"
```
</details>

### impg / BandageNG
TODO: finalize Arabidopsis PAF / sequence files for the FLC region
TODO: fix to be one command to make graph w/o re-running alignments

We can project the same FLC gene region through the all-vs-all alignments, extract the homologous sequences across the pangenome, build a local variation graph with `impg graph`, and visualise it with BandageNG.

<details>
<summary>Show impg extract + graph commands</summary>
```bash
impg query -i "$OUT/all.impg" -a "$OUT/all.paf" -r "CP138175.1:3173000-3179000" -d 1000 -x -o fasta --sequence-files "$DATA/assemblies.fa" -O "$ANALYSIS_DIR/flc_impg"
impg graph --sequence-files "$ANALYSIS_DIR/flc_impg.fa" -g "$ANALYSIS_DIR/flc.gfa"
```
</details>

<details>
<summary>Show BandageNG command</summary>
```bash
BandageNG image "$ANALYSIS_DIR/flc.gfa" "$ANALYSIS_DIR/flc.png"
```
</details>

### vg giraffe
TODO: get short reads matching the Practical 1 HLA graph

Using the Giraffe indexes built in Practical 1, map a set of reads to the HLA variation graph with `vg giraffe`.

<details>
<summary>Show vg giraffe command</summary>
```bash
vg giraffe -Z "$OUT/hla.giraffe.gbz" -d "$OUT/hla.dist" -m "$OUT/hla.min" -f "$DATA/reads.fa" > "$ANALYSIS_DIR/reads.gam"
```
</details>

TODO: compare to aligning to a single reference


