# Scalable Genomics and Pangenomics Informatics Guide

### Laptop Specifications and Informatics Setup

Please bring your personal laptop to the course.

Your laptop should have:

- At least 100 GB of available storage.
- Administrator access, as you may need to install software during the course.
- At least 8 GB of RAM.

There is no specific operating system requirement.

If you have questions about your computer’s compatibility, please post your query in the [Questions and Comments section](https://lms.sanger.ac.uk/mod/forum/view.php?id=12430), and a member of the Training Team will respond.

## Informatics setup options

You have two options for setting up your computer for the informatics sessions.

#### Option 1: Use Docker

We recommend using the Docker solution. Docker provides a controlled environment containing the software required for the course, so you do not need to install each software package individually.

#### Option 2: Install the software individually

You can download and install the required software directly on your computer. A list of the software and installation instructions will be provided separately.

The Training Team will support you with either setup option.

> **Important:** Regardless of which setup option you choose, you must download and install ALNview separately. ALNview is a graphical alignment viewer and is not included in the course Docker environment.

## Installing ALNview (needs to be installed irrespective of informatics option)

ALNview is a graphical alignment viewer for `.1aln` files. It must be installed separately, regardless of whether you use Docker or install the course software individually.

The [ALNview GitHub repository](https://github.com/thegenemyers/ALNVIEW) currently provides a pre-built `.dmg` installer for Apple computers.

### macOS

1. Open the [ALNview GitHub repository](https://github.com/thegenemyers/ALNVIEW).
2. Download the `ALNview.dmg` file.
3. Open the downloaded `.dmg` file.
4. Drag the ALNview application to the **Applications** folder.
5. Open ALNview from the Applications folder.
6. If macOS displays a security warning, open **System Settings**, select **Privacy & Security**, and allow ALNview to open.
7. Test the installation by opening an example `.1aln` file.

### Windows and Linux

A pre-built installer is not currently available for Windows or Linux.

If you are using Windows or Linux, you can either:

- Build ALNview from the source files using Qt 6.9.0 or later.
- Contact the Training Team for further guidance.

For more information, visit the [ALNview GitHub repository](https://github.com/thegenemyers/ALNVIEW).

---

### Option 1: Installing Docker 

### a) Windows

1. Download [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/).
2. Run `Docker Desktop Installer.exe`.
3. Select **Use WSL 2 instead of Hyper-V** when prompted.
4. Complete the installation and restart your computer if requested.
5. Open Docker Desktop and accept the terms.
6. Keep Docker Desktop running when using the course software.

Docker Desktop for Windows requires a supported 64-bit version of Windows, WSL 2, hardware virtualisation, and at least 8 GB of RAM.

### b) macOS

1. Check whether your Mac has an Apple silicon or Intel processor.
2. Download the appropriate version from [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/).
3. Open `Docker.dmg`.
4. Drag Docker to the Applications folder.
5. Open Docker from Applications.
6. Accept the terms and select the recommended settings.
7. Keep Docker Desktop running when using the course software.

### c) Ubuntu Linux

Follow the [official Docker Engine installation instructions for Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

After installation, test Docker by running:

```bash
sudo docker run hello-world
```

### Setting up Course Docker / Singularity image 

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

> Use `singularity` in place of `apptainer` if that is what your cluster provides. Full recipes and smoke tests are in the course repository README.

> You can also install most of the tools with Conda/Mamba via [`environment.yml`](environment.yml) (`conda env create -f environment.yml`). That env includes `panacus`, OrthoFinder 2.5.5, MCScanX, and the R dependencies for GENESPACE / SVbyEye. The course image additionally installs `vg` (linux-only), GENESPACE, and SVbyEye.

---

## Option 2: Software used during the course

> Versions below match the course container image [`vikshiv/scalable-course:latest`](https://hub.docker.com/r/vikshiv/scalable-course) (`linux/amd64`).

| Software | Link | Version | Notes |
|-------------|-------------|--------------|-------------|
| AGC | https://github.com/refresh-bio/agc | 3.2.4 | Compressed multi-genome archive format |
| ropebwt3 | https://github.com/lh3/ropebwt3 | 3.10 | BWT construction and matching for collections of genomes |
| mumemto | https://github.com/vikshiv/mumemto | 1.4.1 | Multi-MUM discovery across genomes |
| shredtools | https://github.com/vikshiv/shredtools | 0.1.0 | Query and extract multi-MUMs from mumemto output |
| impg | https://github.com/pangenome/impg | 0.5.0 | Interval mapping over all-vs-all PAF alignments |
| panacus | https://github.com/codialab/panacus | 0.5.3 | Pangenome graph / VCF counting statistics |
| vg | https://github.com/vgteam/vg | 1.76.1 | Variation graphs; includes `vg giraffe` (linux/amd64 image only) |
| GENESPACE | https://github.com/jtlovell/GENESPACE | 1.3.1 (`7561036`) | Synteny-constrained comparative genomics (R; needs OrthoFinder 2.5.5 + MCScanX) |
| SVbyEye | https://github.com/daewoooo/SVbyEye | `5866e7f` | Visualize structural variation from PAF alignments (R) |
| OrthoFinder | https://github.com/OrthoFinder/OrthoFinder | 2.5.5 | Orthology inference for GENESPACE (not 3.x) |
| MCScanX | https://github.com/wyp1125/MCScanX | 1.0.0 | Collinearity scan (`MCScanX_h`) for GENESPACE |
| Bandage NG | https://github.com/asl/BandageNG | 2026.9.1 | Visualisation of assembly / pangenome graphs |
| minimap2 | https://github.com/lh3/minimap2 | 2.31 | Fast alignment (all-vs-all PAFs for impg) |
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

---

If you have questions about your computer’s compatibility, please post your query in the [Questions and Comments section](https://lms.sanger.ac.uk/mod/forum/view.php?id=12430), and a member of the Training Team will respond.

---

