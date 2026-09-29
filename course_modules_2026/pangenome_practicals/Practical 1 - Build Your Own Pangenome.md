# Practical 1 - Build Your Own Pangenome

There are many notions of what a pangenome is:

- A sequence graph representing the variation present in the set of genomes
- A compressed index of each genome as a text that is queryable
- A catalog of variation and conservation

In this practical session, we will run a few tools that “build” different notions of a pangenome and walk through how each let’s us visualize and query our dataset.

**Docker Image with all the tools pre-installed:** [vikshiv/scalable-course:latest](https://hub.docker.com/r/vikshiv/scalable-course) (`linux/amd64`)

---

## Learning objectives

In this practical you will:

1. Run each tool on a small set of genome assemblies
2. Understand the inputs and outputs of each method

---



## 0) Pull the docker container and datasets

See the course informatics guide for instructions on using the docker image.

To test that the tools are installed and available:

```bash
which agc ropebwt3 syng impg BandageNG panacus vg mumemto shredtools panagram minimap2
```

Next, follow the informatics guide to start an interactive terminal session inside the container, mounting the datasets directory. We provided a few datasets to choose from depending on your computing setup and species of interest.

We provide an AGC file for each dataset:

- *A. thaliana* full genomes (n=5)
- *A. thaliana* chr5 (n=5)
- Human full genomes (n=5)
- Human chr20 (n=5)
- *S. ceraviseae* full genomes (n=22)

You may also run any of the tools on your own dataset of interest!

---



## 1) Run each tool on your chosen dataset

In this section, we will run each of the tools on a dataset of your choosing. We will provide pre-computed outputs for the following sections, as some tools may be slow or memory intensive on personal machines.

We highly encourage you to use the help pages (`toolname -h`) and documentation to devise a command to run first. For each tool, we provide a command to run in the dropdown menu (using the yeast dataset as an example.)

```bash
AGC=/data/datasets/yeast_t2t_haploid.agc
OUT=/data/work/
FASTA_DIR=$OUT/fastas
mkdir -p "$OUT" "$FASTA_DIR"
```



### AGC

[AGC](https://github.com/refresh-bio/agc) stores many genomes in one compressed archive. If you are using the provided datasets, you can use AGC to decompress the archives into a set of FASTA files.

Task: Inspect the AGC archive and decompress it into a set of FASTA files for the downstream tools.

Show agc example command

```bash
agc info "$AGC"
agc listset "$AGC" | head
agc getcol -o "$FASTA_DIR" "$AGC"
ls "$FASTA_DIR" | head
```



Inputs: an AGC archive (`.agc`)

Outputs: a directory of FASTA files (one file per sample)

---



### Mumemto / Shredtools

[Mumemto](https://github.com/vikshiv/mumemto) reports maximal unique matches across a set of assemblies. These matches represent conserved columns in the underlying multiple sequence alignment. Shredtools is a companion tool to Mumemto that indexes the MUMs list for querying. 

Task: run Mumemto on the set of assemblies to create a `bumbl` file containing the MUMs. Then filter and index the set of MUMs for querying.

Show mumemto example command

```bash
mumemto -o "$OUT/mumemto" -b "$FASTA_DIR"/*.fa
```



Show shredtools example command

```bash
shredtools filter -i "$OUT/mumemto.bumbl"
shredtools index --multi "$OUT/mumemto.bumbl" -v
```



Inputs: a set of FASTA files

Outputs: a `bumbl` file, a binary file that contains a list of exact matches and their locations in each assembly

How to view the output `bumbl` file

```bash
mumemto view $OUT/mumemto.bumbl | less
```



Extra exercises:

Compute the coverage of MUMs (how much of a given assembly is “shared” and unique across the pangenome?)

```bash
mumemto coverage -i $OUT/mumemto.bumbl
```



Compute the average MUM length

```bash
mumemto view "$OUT/mumemto.bumbl" | awk '{s+=$1;n++} END{print n?s/n:0}'
```



---



### ropebwt3

[ropebwt3](https://github.com/lh3/ropebwt3) builds an FM-index (a compressed text index) over the collection of genomes and supports MEM queries.

Task: Build an FM-index over the set of assemblies (dynamic `.fmr`, then static `.fmd`).

Show ropebwt3 example command

```bash
# constructs the dynamic version, needed initially to build the index
ropebwt3 build -bo "$OUT/rb3.fmr" "$FASTA_DIR"/*.fa
# constructs the static version, faster and more efficient to load, but no longer can add new assemblies
ropebwt3 build -i "$OUT/rb3.fmr" -do "$OUT/rb3.fmd"
```



Inputs: a set of FASTA files

Outputs: a dynamic BWT (`.fmr`) and a static FM-index (`.fmd`)

Extra exercise:

Compute the size of the BWT

```bash
ropebwt3 stat "$OUT/rb3.fmd"
```



---



### syng

[syng](https://github.com/richarddurbin/syng) builds a syncmer graph of the assemblies. Syncmers are specially chosen kmers that cover the full sequence, and are often shared across a pangenome. To navigate the graph, syng also builds a GBWT, which enables rapid stepping through the graph for querying.

Task: Build a syncmer path graph of the assemblies, then convert the paths into a GBWT for querying.

Show syng example command

```bash
syng -o "$OUT/syng" -writeK -writePath "$FASTA_DIR"/*.fa
syngpath2gbwt "$OUT/syng.1path" "$OUT/syng.1gbwt"
```



Inputs: a set of FASTA files

Outputs: syng path / kmer files (e.g. `.1path`) and a GBWT (`.1gbwt`)

---



### panagram

[panagram](https://github.com/kjenike/panagram) indexes k-mer presence/absence across genomes for interactive visualisation of various different pangenome metrics for exploratory analysis.

Task: Build a panagram samples table and k-mer index for interactive exploration of presence/absence patterns.

Show panagram example command

```bash
PAN_DIR=$OUT/panagram

## the following step can also be done manually to build a samples file
{
  echo -e "name\tfasta\tgff\tid\tanchor"
  id=0
  for f in "$FASTA_DIR"/*.fa; do
    name=$(basename "$f" .fa)
    echo -e "${name}\tFASTAS/${name}.fa\t\t${id}\tTrue"
    id=$((id+1))
  done
} > "$PAN_DIR/samples.tsv"

cd "$PAN_DIR"
panagram index samples.tsv -k 21 --prepare
snakemake --cores 1 all
```



Inputs: a `samples.tsv` listing FASTA paths (and optional annotations)

Outputs: a panagram index directory for interactive visualisation

---



### impg

[impg](https://github.com/pangenome/impg) indexes and enables querying of genomic intervals across a pangenome using all-vs-all pairwise genome alignments. Running all pairs alignments is slow without a multi-CPU machine, so for this step we provide pre-computed alignments.

TODO: finalize HLA contig names / coords for the provided human dataset

Task: Index the pairwise alignments. Build a graph from of the HLA region across the set of human genomes.

Show impg example command

```bash
impg index -a "$OUT/all.paf" -i "$OUT/all.impg"
# replace contig/coords with names from your human FASTA headers (HLA / MHC region)
impg query -i "$OUT/all.impg" -a "$OUT/all.paf" -r "SAMPLE#1#chr6:28510120-33480577" -d 1000 -x -o gfa --sequence-files "$OUT/all.fa" -O "$OUT/hla"
```



Inputs: all-vs-all pairwise alignments (PAF) and the corresponding FASTA sequences

Outputs: an `.impg` index and a GFA graph for the queried region

---



### vg

[vg](https://github.com/vgteam/vg) is a toolkit to manipulate variation graphs (such as those produced by impg or [minigraph-cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md)). Here we build a Giraffe index for read mapping from a variation graph.

Task: Build a `vg giraffe` index from a GFA (e.g. the HLA graph from impg).

Show vg example command

```bash
vg autoindex --workflow giraffe -g "$OUT/hla.gfa" -p "$OUT/hla"
```



Inputs: a variation graph in GFA format

Outputs: Giraffe indexes (e.g. `.giraffe.gbz`, `.dist`, and minimizer / zipcode files)

---



### panacus

[panacus](https://github.com/codialab/panacus) computes coverage and growth statistics over a pangenome graph (GFA).

Task: Summarize node coverage and pangenome growth for the HLA graph from impg.

Show panacus example command

```bash
panacus histgrowth "$OUT/hla.gfa" > "$OUT/hla.histgrowth.tsv"
```



Inputs: a variation graph in GFA format

Outputs: a table of histogram / growth statistics (TSV)