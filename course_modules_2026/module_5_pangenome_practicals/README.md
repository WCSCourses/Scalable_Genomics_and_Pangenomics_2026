# README

Supplementary notes for the pre-built files under `data/` used in the pangenome practicals.

**Docker image:** [npmalfoy/scalable:2026](https://hub.docker.com/r/npmalfoy/scalable) (`linux/amd64`). Typical session mount: `-v "$PWD:/course" -w /course`.

---

## Course assembly datasets

AGC archives under `datasets/` (`datasets_agc.tar.gz`) are subsets drawn from published pangenome resources:

- ***A. thaliana* (5-genome and chr5 subsets; 68-assembly `athaliana_all.agc`):** [Lian et al., 2024](https://doi.org/10.1038/s41588-024-01715-9) — 69-accession *A. thaliana* pan-genome (Nat Genet). doi:[10.1038/s41588-024-01715-9](https://doi.org/10.1038/s41588-024-01715-9)
- **Human (5-haplotype subsets; MHC graph and alignments):** [Lucas et al., 2026](https://doi.org/10.64898/2026.07.21.739710) — HPRC2 human pangenome reference (bioRxiv). doi:[10.64898/2026.07.21.739710](https://doi.org/10.64898/2026.07.21.739710)
- ***S. cerevisiae* (22-strain yeast example):** [O'Donnell et al., 2023](https://doi.org/10.1038/s41588-023-01459-y) — ScRAP T2T yeast pangenome (Nat Genet). doi:[10.1038/s41588-023-01459-y](https://doi.org/10.1038/s41588-023-01459-y)

Full bibliographic entries: [References](#references) below.

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

Given an MHC-region FASTA (`mhc.fa`) and the SRA Toolkit + [minimap2](https://github.com/lh3/minimap2) + samtools:

```bash
fastq-dump -Z SRR36352204 \
  | minimap2 -t 8 -x map-hifi --secondary=no -a mhc.fa - \
  | samtools fastq -F 2308 -q 20 \
  > mhc_reads.fastq
```

---

## Pre-built human MHC graph (`data/human`)

The shipped MHC variation graph is a **[minigraph-cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md)** build:

```text
data/human/mhc/mhc.full.gfa.gz
```

Pre-built [`vg`](https://github.com/vgteam/vg) [Giraffe](https://github.com/vgteam/vg/wiki/Mapping-long-reads-with-Giraffe) long-read indexes for Practical 2 live under `data/human/vg_giraffe/` (e.g. `mhc/` and `mhc_chm13/`).

> Note: an older course narrative timed an [`impg`](https://github.com/pangenome/impg) query / [seqwish](https://github.com/pangenome/seqwish) MHC GFA over 5 human genomes (~2 h). That impg-built `mhc.gfa` is **not** the shipped graph for this year; use `mhc.full.gfa.gz` (and the giraffe indexes above) instead.

---

## Pre-built *A. thaliana* datasets (`data/athaliana`)

### Alignments (optional archive)

Optional large download `alignments_athaliana.tar.gz` unpacks to **pairwise** all-vs-all PAFs (one file per genome pair; useful later for synteny viewing):

```text
data/athaliana/alignments/*.paf
```

The corresponding `.impg` index is **not** shipped — build it in Practical 1 with `impg index --alignment-list` over those files (human stays a single `data/human/alignments.paf`). Do not expect a merged `alignments.paf` or a pre-built Ath `.impg` in `course_data`.

### Tool outputs layout

Layout under `data/athaliana/tool_outputs/`:

| Directory | Files |
| --------- | ----- |
| `mumemto/` | `mumemto.bumbl`, `mumemto.bumbl.bi`, `mumemto.lengths` |
| `ropebwt3/` | `rb3.fmd`, `rb3.fmr` |
| `syng/` | `syng.1gbwt`, `syng.1khash`, `syng.1path` |
| `panagram/` | [panagram](https://github.com/kjenike/panagram) run dir without `kmc/` or `FASTAS/` (stage FASTAs from `athaliana_all.agc`; used in different practical) |

Practical 2 points mumemto viz / shredtools extract at `$ATH_OUT/mumemto/…`.

The mumemto collection includes **69** assemblies (Tanz-1 merged in for locus extraction). The ropebwt3 / syng / panagram / impg builds used **68** assemblies with Tanz-1 held out. Runtimes below used **48 threads** on the EBI codon cluster.


| Tool / step           | Wall time                | Approx. memory                                | Notes                                             |
| --------------------- | ------------------------ | --------------------------------------------- | ------------------------------------------------- |
| mumemto + shredtools  | **23 min**               | **~25 GB / batch** (~150 GB if 8 run at once) | 8 parallel batches, one CPU per batch; index → `.bumbl.bi` |
| ropebwt3              | **43 min**               | **~4 GB**                                     | `build` → `.fmr` / `.fmd`                         |
| syng + syngpath2gbwt  | **6.7 min**              | **~3 GB**                                     | syncmer dict + GBWT                               |
| panagram              | **10 min**               | **~10 GB**                                    | prepare + snakemake                               |
| impg all-vs-all align | **~263 h** pair-job time | **~5 GB / pair**                              | 2,346 [wfmash](https://github.com/waveygang/wfmash) pairs @ 12 CPUs each (~7 min / pair) |

---

## References

### Assembly datasets

- Lian Q, Huettel B, Walkemeier B, et al. A pan-genome of 69 *Arabidopsis thaliana* accessions reveals a conserved genome structure throughout the global species range. *Nat Genet*. 2024;56(5):982-991. doi:[10.1038/s41588-024-01715-9](https://doi.org/10.1038/s41588-024-01715-9)
- Lucas JK, Hebbar P, Liao W-W, et al. HPRC2: A human pangenome reference with near-complete coverage of common genetic variation. *bioRxiv*. 2026. doi:[10.64898/2026.07.21.739710](https://doi.org/10.64898/2026.07.21.739710)
- O'Donnell S, Yue J-X, Abou Saada O, et al. Telomere-to-telomere assemblies of 142 strains characterize the genome structural landscape in *Saccharomyces cerevisiae*. *Nat Genet*. 2023;55(8):1390-1399. doi:[10.1038/s41588-023-01459-y](https://doi.org/10.1038/s41588-023-01459-y)

### Tools and methods

- Deorowicz S, Danek A, Li H. AGC: compact representation of assembled genomes with fast queries and updates. *Bioinformatics*. 2023;39(3):btad097. doi:[10.1093/bioinformatics/btad097](https://doi.org/10.1093/bioinformatics/btad097)
- Shivakumar VS, Langmead B. Mumemto: efficient maximal matching across pangenomes. *Genome Biol*. 2025;26:169. doi:[10.1186/s13059-025-03644-0](https://doi.org/10.1186/s13059-025-03644-0)
- Shivakumar VS, Langmead B. Navigating the pangenome coordinate system with Shredtools. *bioRxiv*. 2026. doi:[10.64898/2026.07.03.736354](https://doi.org/10.64898/2026.07.03.736354)
- Li H. BWT construction and search at the terabase scale. *Bioinformatics*. 2024;40(12):btae717. doi:[10.1093/bioinformatics/btae717](https://doi.org/10.1093/bioinformatics/btae717) ([ropebwt3](https://github.com/lh3/ropebwt3))
- Durbin R. A run-length-compressed skiplist data structure for dynamic GBWTs supports time and space efficient pangenome operations over syncmers. *bioRxiv*. 2026. doi:[10.64898/2026.03.26.714584](https://doi.org/10.64898/2026.03.26.714584) ([syng](https://github.com/richarddurbin/syng))
- [impg](https://github.com/pangenome/impg) — interval projection over pangenome alignments (pangenome/impg)
- Garrison E, Sirén J, Novak AM, et al. Variation graph toolkit improves read mapping by representing genetic variation in the reference. *Nat Biotechnol*. 2018;36(9):875-879. doi:[10.1038/nbt.4227](https://doi.org/10.1038/nbt.4227) ([vg](https://github.com/vgteam/vg))
- Sirén J, Monlong J, Chang X, et al. Pangenomics enables genotyping of known structural variants in 5,202 diverse genomes. *Science*. 2021;374(6574):abg8871. doi:[10.1126/science.abg8871](https://doi.org/10.1126/science.abg8871) (Giraffe)
- Chang X, Novak AM, Eizenga JM, et al. Rapid, accurate long- and short-read mapping to large pangenome graphs with vg Giraffe. *bioRxiv*. 2025. doi:[10.1101/2025.09.29.678807](https://doi.org/10.1101/2025.09.29.678807)
- Hickey G, Monlong J, Ebler J, et al. Pangenome graph construction from genome alignments with Minigraph-Cactus. *Nat Biotechnol*. 2024;42(4):663-673. doi:[10.1038/s41587-023-01793-w](https://doi.org/10.1038/s41587-023-01793-w)
- Wick RR, Schultz MB, Zobel J, Holt KE. Bandage: interactive visualization of de novo genome assemblies. *Bioinformatics*. 2015;31(20):3350-3352. doi:[10.1093/bioinformatics/btv383](https://doi.org/10.1093/bioinformatics/btv383)
- [BandageNG](https://github.com/asl/BandageNG) — graph visualisation (asl/BandageNG)
- Parmigiani L, Garrison E, Stoye J, Marschall T, Doerr D. Panacus: fast and exact pangenome growth and core size estimation. *Bioinformatics*. 2024;40(12):btae720. doi:[10.1093/bioinformatics/btae720](https://doi.org/10.1093/bioinformatics/btae720)
- Benoit M, Jenike KM, Satterlee J, et al. Solanum pan-genetics reveals paralogues as contingencies in crop engineering. *Nature*. 2025;640(8057):135-145. doi:[10.1038/s41586-025-08619-6](https://doi.org/10.1038/s41586-025-08619-6) ([panagram](https://github.com/kjenike/panagram))
- Li H. Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics*. 2018;34(18):3094-3100. doi:[10.1093/bioinformatics/bty101](https://doi.org/10.1093/bioinformatics/bty101)
- Garrison EP, Guarracino A. Unbiased pangenome graphs. *Bioinformatics*. 2023;39(1):btac743. doi:[10.1093/bioinformatics/btac743](https://doi.org/10.1093/bioinformatics/btac743) ([seqwish](https://github.com/pangenome/seqwish))
- Guarracino A, Mwaniki N, Marco-Sola S, Garrison E. wfmash: whole-chromosome pairwise alignment using the hierarchical wavefront algorithm. *Zenodo* / [GitHub](https://github.com/waveygang/wfmash).
