#!/usr/bin/env Rscript
# p4_svbyeye.R — minimal SVbyEye plotAVA from pairwise PAFs (Practical 4).
#
# Each chr14 FASTA is one contig, so we just rename q/t to genome labels.
# Build --order from mumemto.lengths (* lines → FASTA basename without .fa):
#   awk '/ \* /{ n=$1; sub(/^.*\//,"",n); sub(/\.fa$/,"",n); print n }' \
#     mumemto.lengths > genome_order.txt
#
# PAF names: GenomeA__GenomeB.paf with A = target, B = query.

suppressPackageStartupMessages({
  library(SVbyEye)
  library(argparse)
  library(ggplot2)
})

parser <- ArgumentParser(description = "SVbyEye AVA plot from pairwise PAFs.")
parser$add_argument("--paf-dir", required = TRUE, help = "Directory of A__B.paf files")
parser$add_argument("--out", required = TRUE, help = "Output .pdf (PNG sidecar written too)")
parser$add_argument("--order", required = TRUE, help = "Text file: one genome stem per line")
parser$add_argument(
  "--max-genomes", type = "integer", default = NULL,
  help = "Optional truncate of --order (default: all lines)"
)
args <- parser$parse_args()

stems <- readLines(args$order, warn = FALSE)
stems <- stems[nzchar(trimws(stems))]
if (!is.null(args$max_genomes)) {
  stems <- head(stems, as.integer(args$max_genomes))
}
if (length(stems) < 2L) stop("Need >= 2 genomes in --order", call. = FALSE)

# Short plot labels: R64, ScRAP code (AGK), or ASM…
short_label <- function(stem) {
  if (grepl("R64", stem, fixed = TRUE)) return("R64")
  m <- regmatches(stem, regexpr("(?<=_)[A-Za-z0-9_]+(?=\\.nuclear)", stem, perl = TRUE))
  if (length(m) == 1L && nzchar(m)) return(m)
  m <- regmatches(stem, regexpr("ASM[0-9]+v[0-9]+", stem))
  if (length(m) == 1L && nzchar(m)) return(m)
  sub("_genomic$", "", sub("^GCA_[0-9]+\\.[0-9]+_", "", stem))
}
labels <- setNames(vapply(stems, short_label, character(1)), stems)

parts <- list()
for (i in seq_len(length(stems) - 1L)) {
  a <- stems[[i]]
  b <- stems[[i + 1L]]
  f1 <- file.path(args$paf_dir, paste0(a, "__", b, ".paf"))
  f2 <- file.path(args$paf_dir, paste0(b, "__", a, ".paf"))
  if (file.exists(f1)) {
    path <- f1
    query <- b
    target <- a
  } else if (file.exists(f2)) {
    path <- f2
    query <- a
    target <- b
  } else {
    stop("No PAF for ", a, " / ", b, call. = FALSE)
  }
  paf <- readPaf(paf.file = path, include.paf.tags = TRUE, restrict.paf.tags = "cg")
  paf <- filterPaf(paf.table = paf, min.mapq = 0, min.align.len = 1000)
  if (!nrow(paf)) stop("Empty PAF after filter: ", path, call. = FALSE)
  paf$q.name <- labels[[query]]
  paf$t.name <- labels[[target]]
  parts[[i]] <- paf
}
paf_table <- do.call(rbind, parts)

plt <- plotAVA(
  paf.table = paf_table,
  seqnames.order = unname(labels),
  color.by = "direction",
  outline.alignments = TRUE
)

out <- args$out
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
h <- max(4, 0.85 * length(stems) + 1.5)
ggsave(out, plot = plt, width = 12, height = h, limitsize = FALSE)
if (grepl("\\.pdf$", out, ignore.case = TRUE)) {
  ggsave(sub("\\.pdf$", ".png", out, ignore.case = TRUE),
         plot = plt, width = 12, height = h, dpi = 150, limitsize = FALSE)
}
message("Wrote ", out)
