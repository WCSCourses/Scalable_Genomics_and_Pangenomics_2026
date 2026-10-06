# README

Supplementary notes for the pre-built files under `data/` used in the pangenome practicals.

**Docker image:** [npmalfoy/scalable:2026](https://hub.docker.com/r/npmalfoy/scalable) (`linux/amd64`). Typical session mount: `-v "$PWD:/course" -w /course`.

---

## MHC reference region (I002C)

The MHC FASTA used as the mapping target was taken from the I002C paternal haplotype. Coordinates were obtained with [shredtools (HPRC browser)](https://vikshiv.github.io/shredtools/hprc/): query the CHM13 region `chr6:28381448-33301940`, which returns the homologous interval

```text
I002C_hap1	chr6:28477481-33546197
```

That interval was excerpted from the donor assembly using `samtools faidx` to produce the ~5 Mb reference FASTA.

---

## MHC HiFi query reads

The query reads used in Practical 2 are PacBio HiFi reads from the paternal sample of the I002C Singaporean T2T trio, subset to the MHC region above.

**Source accession:** [SRR36352204](https://www.ncbi.nlm.nih.gov/sra/SRR36352204) (experiment [SRX31382426](https://www.ncbi.nlm.nih.gov/sra/SRX31382426); BioProject [PRJNA1150503](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1150503))

Reads were streamed from SRA and kept only if they mapped to that I002C MHC excerpt (`chr6:28477481-33546197`). We collected 1k reads as a small sample read dataset.

### Minimal example

Given an MHC-region FASTA (`mhc.fa`) and the SRA Toolkit + minimap2 + samtools:

```bash
fastq-dump -Z SRR36352204 \
  | minimap2 -t 8 -x map-hifi --secondary=no -a mhc.fa - \
  | samtools fastq -F 2308 -q 20 \
  > mhc_reads.fastq
```

---

## Pre-built human MHC graph (`data/human`)

The shipped MHC variation graph is a **minigraph-cactus** build:

```text
data/human/mhc/mhc.full.gfa.gz
```

Pre-built `vg giraffe` long-read indexes for Practical 2 live under `data/human/vg_giraffe/` (e.g. `mhc/` and `mhc_chm13/`).

> Note: an older course narrative timed an `impg query` / seqwish MHC GFA over 5 human genomes (~2 h). That impg-built `mhc.gfa` is **not** the shipped graph for this year; use `mhc.full.gfa.gz` (and the giraffe indexes above) instead.

---

## Pre-built *A. thaliana* datasets (`data/athaliana`)

### Alignments (optional archive)

Optional large download `alignments_athaliana.tar.gz` unpacks to a **single** all-vs-all PAF:

```text
data/athaliana/alignments.paf
```

The corresponding `.impg` index is **not** shipped — build it in Practical 1 with `impg index` (same pattern as the human alignments). Do not expect `alignments.paf.gz` or a pre-built `all.impg` in `course_data`.

### Tool outputs layout

Layout under `data/athaliana/tool_outputs/`:

| Directory | Files |
| --------- | ----- |
| `mumemto/` | `mumemto.bumbl`, `mumemto.bumbl.bi`, `mumemto.lengths` |
| `ropebwt3/` | `rb3.fmd`, `rb3.fmr` |
| `syng/` | `syng.1gbwt`, `syng.1khash`, `syng.1path` |
| `panagram/` | panagram run dir without `kmc/` or `FASTAS/` (stage FASTAs from `athaliana_all.agc`; used in different practical) |

Practical 2 points mumemto viz / shredtools extract at `$ATH_OUT/mumemto/…`.

The mumemto collection includes **69** assemblies (Tanz-1 merged in for locus extraction). The ropebwt3 / syng / panagram / impg builds used **68** assemblies with Tanz-1 held out. Runtimes below used **48 threads** on the EBI codon cluster.


| Tool / step           | Wall time                | Approx. memory                                | Notes                                             |
| --------------------- | ------------------------ | --------------------------------------------- | ------------------------------------------------- |
| mumemto + shredtools  | **23 min**               | **~25 GB / batch** (~150 GB if 8 run at once) | 8 parallel batches, one CPU per batch; index → `.bumbl.bi` |
| ropebwt3              | **43 min**               | **~4 GB**                                     | `build` → `.fmr` / `.fmd`                         |
| syng + syngpath2gbwt  | **6.7 min**              | **~3 GB**                                     | syncmer dict + GBWT                               |
| panagram              | **10 min**               | **~10 GB**                                    | prepare + snakemake                               |
| impg all-vs-all align | **~263 h** pair-job time | **~5 GB / pair**                              | 2,346 wfmash pairs @ 12 CPUs each (~7 min / pair) |
