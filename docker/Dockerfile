# Scalable Genomics course image: pangenome tools on PATH
# Build from this directory (linux/amd64 for Docker Hub + Singularity/HPC):
#   docker build --platform linux/amd64 -t YOUR_DOCKERHUB_USER/scalable-course:latest .

FROM mambaorg/micromamba:2.0.5

ARG MAMBA_DOCKERFILE_ACTIVATE=1
ARG SYNG_COMMIT=a4ed6bac0e562f23b400836a60d78ba893fd5045
ARG PANAGRAM_TAG=v1.0.0
ARG ALNTOOLS_COMMIT=87a135e31f18b2b388ab70ca8abb23b8679ad544
ARG GENOMESCOPE2_TAG=v2.1.0
ARG SMUDGEPLOT_TAG=v0.5.4
ARG GENESPACE_COMMIT=7561036be821e333c1dfb52461ccec7222e95582
ARG SVBYEYE_COMMIT=5866e7f198b7827628aa95ea3bfa421986a0bbd8
ARG DASHING2_COMMIT=8b124f690d278e241f46908e8c8c4fe4d2a9a9f6

USER root
# System toolchain for syng; less for interactive paging
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      git \
      ca-certificates \
      time \
      less \
      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/tools/bin /opt/tools/src /data/datasets /data/work \
    && chown -R $MAMBA_USER:$MAMBA_USER /opt/tools /data

USER $MAMBA_USER
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml

# Conda packages; vg is linux-only on bioconda (course image target).
RUN micromamba create -y -n scalable_course -f /tmp/environment.yml \
    && micromamba install -y -n scalable_course -c conda-forge -c bioconda \
         vg=1.76.1 \
    && micromamba clean --all --yes

WORKDIR /opt/tools/src

# --- panagram (v1.0.0) ---
# Upstream setup omits package_data for assets/; view needs panagram/assets/*.
RUN git clone --recursive --depth 1 --branch ${PANAGRAM_TAG} \
      https://github.com/kjenike/panagram.git \
    && cd panagram \
    && micromamba run -n scalable_course pip install --no-cache-dir --upgrade pip setuptools \
    && micromamba run -n scalable_course pip install --no-cache-dir . \
    && cd / \
    && DEST="$(micromamba run -n scalable_course python -c 'import panagram, pathlib; print(pathlib.Path(panagram.__file__).resolve().parent)')" \
    && cp -a /opt/tools/src/panagram/panagram/assets "$DEST/" \
    && test -f "$DEST/assets/panagram.png"

# --- syng (exact commit a4ed6bac…) ---
RUN git clone https://github.com/richarddurbin/syng.git \
    && cd syng \
    && git checkout ${SYNG_COMMIT} \
    && make -j"$(nproc)" \
    && cp -f syng syngmap syngstat syngpath2gbwt ONEview k31type /opt/tools/bin/

# --- smudgeplot (GitHub v0.5.4; PyPI and bioconda still at 0.5.3) ---
RUN git clone --depth 1 --branch ${SMUDGEPLOT_TAG} \
      https://github.com/KamilSJaron/smudgeplot.git \
    && cd smudgeplot \
    && micromamba run -n scalable_course pip install --no-cache-dir .

# --- alntools (.1aln helpers for FastGA / FasTAN; not on bioconda) ---
# Skip ONEview: syng already installs one into /opt/tools/bin.
RUN git clone https://github.com/richarddurbin/alntools.git \
    && cd alntools \
    && git checkout ${ALNTOOLS_COMMIT} \
    && make -j"$(nproc)" \
    && cp -f tanbed gdbmask svfind taco tancons satmatch /opt/tools/bin/

# --- genomescope2 (GitHub v2.1.0; bioconda 2.1.0 is py313-only) ---
# R deps (argparse, minpack.lm, jsonlite) come from conda; do not run upstream install.R (CRAN).
RUN git clone --depth 1 --branch ${GENOMESCOPE2_TAG} \
      https://github.com/tbenavi1/genomescope2.0.git \
    && cd genomescope2.0 \
    && micromamba run -n scalable_course Rscript -e 'install.packages(".", repos=NULL, type="source")' \
    && cp -f genomescope.R /opt/tools/bin/genomescope2 \
    && chmod +x /opt/tools/bin/genomescope2

# --- GENESPACE (GitHub 1.3.1; OrthoFinder 2.5.5 + MCScanX_h from conda) ---
RUN micromamba run -n scalable_course Rscript -e \
      "remotes::install_github('jtlovell/GENESPACE@${GENESPACE_COMMIT}', upgrade='never', dependencies=FALSE); stopifnot(requireNamespace('GENESPACE', quietly=TRUE))"

# --- SVbyEye (GitHub) ---
RUN micromamba run -n scalable_course Rscript -e \
      "remotes::install_github('daewoooo/SVbyEye@${SVBYEYE_COMMIT}', upgrade='never', dependencies=FALSE); stopifnot(requireNamespace('SVbyEye', quietly=TRUE))"

# --- dashing2 (BenLangmead fork branch test/all-fixes; pinned commit 8b124f6) ---
# Build: make GIT_VERSION=v2.1.20-allfixes-$(git rev-parse --short HEAD) dashing2
RUN git clone --recurse-submodules -b test/all-fixes \
      https://github.com/BenLangmead/dashing2.git dashing2-allfixes \
    && cd dashing2-allfixes \
    && git checkout ${DASHING2_COMMIT} \
    && git submodule update --init --recursive \
    && make -j"$(nproc)" GIT_VERSION=v2.1.20-allfixes-$(git rev-parse --short HEAD) dashing2 \
    && cp -f dashing2 /opt/tools/bin/

USER root
COPY entrypoint.sh /usr/local/bin/course-entrypoint.sh
COPY smoke_test.sh /opt/tools/bin/smoke_test.sh
RUN chmod +x /usr/local/bin/course-entrypoint.sh \
      /opt/tools/bin/smoke_test.sh \
    && chown $MAMBA_USER:$MAMBA_USER /opt/tools/bin/smoke_test.sh

USER $MAMBA_USER
# Interactive bash sources ~/.bashrc → _activate_current_env.sh, which activates ENV_NAME.
# Must be scalable_course (image default is base), or tools vanish from PATH.
ENV ENV_NAME=scalable_course
ENV MAMBA_ROOT_PREFIX=/opt/conda
ENV PATH="/opt/tools/bin:/opt/conda/envs/scalable_course/bin:${PATH}"
WORKDIR /data

ENTRYPOINT ["/usr/local/bin/course-entrypoint.sh"]
CMD ["bash"]
