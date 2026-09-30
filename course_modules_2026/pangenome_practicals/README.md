# README

Supplementary notes for the pre-built files under `data/` used in the pangenome practicals.

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

Building the MHC variation graph with `impg query` over the **5** human genomes (CHM13 region `chr6:28381448-33301940`, `-o gfa:seqwish`) took **124m19.699s** (~2 h 4 min).

---

## Pre-built *A. thaliana* datasets runtimes (`data/athaliana`)

The indexes and alignments in `data/athaliana/tool_outputs/` and `data/athaliana/alignments.paf.gz` were built using **68** assemblies (Tanz-1 held out), using **48 threads** on the EBI codon cluster. The following are runtimes and memory usage stats for each tool for reference.


| Tool / step           | Wall time                | Approx. memory                                | Notes                                             |
| --------------------- | ------------------------ | --------------------------------------------- | ------------------------------------------------- |
| mumemto + shredtools  | **23 min**               | **~25 GB / batch** (~150 GB if 8 run at once) | 8 parallel batches, one CPU per batch                     |
| ropebwt3              | **43 min**               | **~4 GB**                                     | `build` → `.fmr` / `.fmd`                         |
| syng + syngpath2gbwt  | **6.7 min**              | **~3 GB**                                     | syncmer dict + GBWT                               |
| panagram              | **10 min**               | **~10 GB**                                    | prepare + snakemake                               |
| impg all-vs-all align | **~263 h** pair-job time | **~5 GB / pair**                              | 2,346 wfmash pairs @ 12 CPUs each (~7 min / pair) |
