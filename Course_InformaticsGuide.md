# <img src="https://coursesandconferences.wellcomeconnectingscience.org/wp-content/themes/wcc_courses_and_conferences/dist/assets/svg/logo.svg" width="300" height="50"> 

# Scalable Genomics and Pangenomics Informatics Guide

## Software used during the course

Versions below match the course container image [`vikshiv/scalable-course:latest`](https://hub.docker.com/r/vikshiv/scalable-course) (`linux/amd64`).

| Software | Link | Version | Notes |
|-------------|-------------|--------------|-------------|
| AGC | https://github.com/refresh-bio/agc | 3.2.4 | Compressed multi-genome archive format |
| ropebwt3 | https://github.com/lh3/ropebwt3 | 3.10 | BWT construction and matching for collections of genomes |
| mumemto | https://github.com/vikshiv/mumemto | 1.4.1 | Multi-MUM discovery across genomes |
| shredtools | https://github.com/vikshiv/shredtools | 0.1.0 | Query and extract multi-MUMs from mumemto output |
| impg | https://github.com/pangenome/impg | 0.5.0 | Interval mapping over all-vs-all PAF alignments |
| PGGB | https://github.com/pangenome/pggb | 0.7.4 | PanGenome Graph Builder |
| Bandage NG | https://github.com/asl/BandageNG | 2026.9.1 | Visualisation of assembly / pangenome graphs |
| minimap2 | https://github.com/lh3/minimap2 | 2.31 | Fast alignment (all-vs-all PAFs for impg / pggb) |
| GenomeScope2 | https://github.com/tbenavi1/genomescope2.0 | v2.1.0 | Estimates genome size, heterozygosity, and repeat content |
| Smudgeplot | https://github.com/KamilSJaron/smudgeplot | v0.5.4 | Infers ploidy and genome structure using k-mer pairs |
| FastK | https://github.com/thegenemyers/FASTK | 1.2 | High-performance k-mer counting toolkit |
| MerquryFK | https://github.com/thegenemyers/MERQURY.FK | 1.2 | Assembly QC with FastK k-mers |
| sourmash | https://github.com/sourmash-bio/sourmash | 4.9.4 | Sketching and comparison of genomic datasets |
| FastGA | https://github.com/thegenemyers/FASTGA | 1.5.20260729 | Fast genome–genome alignment |
| FasTAN | https://github.com/thegenemyers/FasTAN | 0.8 | Tandem / local alignment helpers (bioconda `fastan`) |
| panagram | https://github.com/kjenike/panagram | v1.0.0 | Interactive pangenome / k-mer visualisation |
| syng | https://github.com/richarddurbin/syng | commit `a4ed6bac` | Syncmer graph construction (`syng`, `syngpath2gbwt`, …) |
| alntools | https://github.com/richarddurbin/alntools | commit `87a135e` | Helpers for FastGA / FasTAN (`.1aln` utilities) |
| AWS CLI | https://aws.amazon.com/cli/ | Latest | Command-line tool for interacting with AWS services, used for downloading datasets |

### Course Docker / Singularity image

Pull the pre-built image from Docker Hub: [`vikshiv/scalable-course:latest`](https://hub.docker.com/r/vikshiv/scalable-course).

Mount a local data directory (and an optional writable work directory) so tools can read inputs and write outputs outside the container.

**Docker** (interactive shell; adjust host paths as needed):

```bash
docker pull vikshiv/scalable-course:latest

mkdir -p work
docker run --rm -it \
  --platform linux/amd64 \
  -v "$PWD/datasets:/data/datasets:ro" \
  -v "$PWD/work:/data/work" \
  vikshiv/scalable-course:latest
```

Inside the container, tools are on `PATH`; read data from `/data/datasets` and write under `/data/work`. On Apple Silicon (or other arm64 hosts), keep `--platform linux/amd64`.

**Singularity / Apptainer:**

```bash
apptainer pull scalable-course.sif docker://vikshiv/scalable-course:latest

apptainer shell \
  --bind "$PWD/datasets:/data/datasets:ro,$PWD/work:/data/work" \
  scalable-course.sif
```

Use `singularity` in place of `apptainer` if that is what your cluster provides. Full recipes and smoke tests are in the course repository README.

You can also install most of the tools with Conda/Mamba via [`environment.yml`](environment.yml) (`conda env create -f environment.yml`).

## Informatics Solutions

To ensure flexibility and accessibility for participants, the following approaches are recommended:

### A. Use institutional or cloud-based compute infrastructure (recommended)

Participants can connect to a pre-configured compute environment hosted on an institutional cluster or cloud platform.  
This setup ensures that all required software and databases are installed and tested in advance.

**Advantages:**
- Handles large datasets efficiently  
- Ensures consistent software environments across users  
- Reduces local installation issues  

**Requirements:**
- Stable internet connection  
- Access via SSH, VPN, or web portal  
- User accounts created and tested before the course  

---

### B. Local installation on participant machines

Participants install all required software locally using Conda, Docker, or a virtual machine.  

**Advantages:**
- Works without internet once set up  
- Full control over the environment  

**Limitations:**
- Requires sufficient hardware resources  
- Installation and dependency conflicts may occur  
- Variability between systems can affect reproducibility  

---

### C. Use Galaxy (browser-based platform)

Galaxy provides a web-based interface where users can run bioinformatics tools without local installation.

**Advantages:**
- No installation required  
- Standardised workflows and user-friendly interface  
- Suitable for teaching and beginners  

**Considerations:**
- Limited computational resources depending on the server  
- Tool availability must be confirmed in advance  
- Data upload and transfer can be time-consuming for large datasets  

---

## Citing and Re-using Course Material

The course data are free to reuse and adapt with appropriate attribution. All course data in these repositories are licensed under the <a rel="license" href="https://creativecommons.org/licenses/by-nc-sa/4.0/">Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)</a>. <a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons Licence" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br /> 

Each course landing page is assigned a DOI via Zenodo, providing a stable and citable reference.

---

## Interested in attending a course?

Explore upcoming events at:  
https://coursesandconferences.wellcomeconnectingscience.org/our-events/

---

Wellcome Connecting Science GitHub:  
https://github.com/WCSCourses  

For enquiries:  
https://coursesandconferences.wellcomeconnectingscience.org  

Social links:  
https://linktr.ee/eventswcs  

---
