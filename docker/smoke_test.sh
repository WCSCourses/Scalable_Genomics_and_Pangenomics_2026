#!/usr/bin/env bash
# Comprehensive smoke test: every course tool is on PATH and executes.
# Intended to run inside the scalable-course container/image.
set -uo pipefail

fail=0
ok_count=0
fail_count=0

pass() {
  echo "OK   $*"
  ok_count=$((ok_count + 1))
}

fail_msg() {
  echo "FAIL $*"
  fail=1
  fail_count=$((fail_count + 1))
}

# Binary on PATH, executable, and probe stdout/stderr matches EXPECT_REGEX.
# Probe exit status is ignored (many tools exit non-zero when printing usage).
require_runs() {
  local name="$1"
  local expect="$2"
  shift 2
  if ! command -v "$name" >/dev/null 2>&1; then
    fail_msg "$name  (not on PATH)"
    return
  fi
  local out
  out="$("$@" 2>&1)" || true
  if printf '%s\n' "$out" | grep -Eqi -- "$expect"; then
    pass "$name  -> $(command -v "$name")"
  else
    fail_msg "$name  (unexpected output for: $*)"
    printf '%s\n' "$out" | head -n 10 | sed 's/^/       /'
  fi
}

# Binary on PATH and runnable (does not crash with signal). Some helpers print nothing.
require_exec() {
  local name="$1"
  shift
  if ! command -v "$name" >/dev/null 2>&1; then
    fail_msg "$name  (not on PATH)"
    return
  fi
  local path rc
  path="$(command -v "$name")"
  if [ ! -x "$path" ]; then
    fail_msg "$name  (not executable: $path)"
    return
  fi
  set +e
  "$@" >/dev/null 2>&1
  rc=$?
  set -u
  # 0–125 = normal process exit; 126/127 = invoke errors; >=128 often signal
  if [ "$rc" -ge 126 ] && [ "$rc" -le 127 ]; then
    fail_msg "$name  (could not invoke, exit $rc)"
  elif [ "$rc" -ge 128 ]; then
    fail_msg "$name  (crashed, exit $rc)"
  else
    pass "$name  -> $path"
  fi
}

echo "=== scalable-course smoke test ==="
echo "date:  $(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
echo "uname: $(uname -a 2>/dev/null || true)"
echo "PATH:  $PATH"
echo

echo "--- bioconda course tools ---"
require_runs agc        "Assembled Genomes Compressor|Usage: agc"     agc
require_runs ropebwt3   "ropebwt3|Usage:"                            ropebwt3
require_runs mumemto    "mumemto|Usage:"                             mumemto -h
require_runs shredtools "shredtools|Manipulate multi-MUMs|usage:"    shredtools -h
require_runs impg       "impg|Usage:|Command-line tool for querying" impg --help
require_runs BandageNG  "Bandage|Version:"                           BandageNG --help
require_runs panacus    "panacus|Usage:|usage:"                      panacus --help
require_runs vg         "vg|Usage:|variation graph"                  vg help
require_runs FastK      "FastK|Usage:"                               FastK
require_runs Histex     "Histex|Usage:"                              Histex
require_runs MerquryFK  "MerquryFK|Usage:"                           MerquryFK
require_runs sourmash   "sourmash|usage:"                            sourmash --help
require_runs dashing2   "dashing2|Usage:|sketch"                     dashing2 --help
require_runs FastGA     "FastGA|Usage:"                              FastGA
require_runs FasTAN     "FasTAN|Usage:"                              FasTAN
require_runs orthofinder "OrthoFinder|orthofinder|Usage:"            orthofinder -h
if command -v MCScanX_h >/dev/null 2>&1 && [ -x "$(command -v MCScanX_h)" ]; then
  pass "MCScanX_h  -> $(command -v MCScanX_h)"
else
  fail_msg "MCScanX_h  (not on PATH)"
fi

echo
echo "--- helpers ---"
require_runs samtools   "samtools|[0-9]+\.[0-9]+"                    samtools --version
require_runs minimap2   "minimap2|[0-9]+\.[0-9]+"                    minimap2 --version
require_runs tabix      "Version:|Usage:"                            tabix
require_runs bgzip      "Version:|Usage:"                            bgzip -h
require_runs snakemake  "snakemake|[0-9]+\.[0-9]+"                   snakemake --version
require_runs python     "Python 3\."                                 python --version
require_runs less       "less|version|[0-9]+\.[0-9]+"                less --version

echo
echo "--- source-built / pip tools ---"
require_runs panagram      "panagram|usage:|Alignment-free|Subcommands" panagram --help
require_runs smudgeplot    "smudgeplot|usage:|Usage:"                   smudgeplot -h
require_runs genomescope2  "GenomeScope|Usage:|usage:|genomescope"     genomescope2 --help
require_runs syng          "Usage: syng|operation"                     syng
require_exec syngmap       syngmap
require_exec syngstat      syngstat
require_exec syngpath2gbwt syngpath2gbwt
require_exec ONEview       ONEview
require_runs tanbed        "tanbed|Usage:|usage:"                      tanbed
require_runs gdbmask       "gdbmask|Usage:|usage:"                     gdbmask
require_runs taco          "taco|Usage:|usage:"                        taco
require_runs tancons       "tancons|Usage:|usage:"                     tancons
require_runs satmatch      "satmatch|Usage:|usage:"                    satmatch
require_runs svfind        "svfind|Usage:|usage:"                      svfind

echo
echo "--- timing helper ---"
if [ -x /usr/bin/time ]; then
  out="$(/usr/bin/time -f 'elapsed_sec=%e max_rss_kb=%M' true 2>&1)" || true
  if printf '%s\n' "$out" | grep -Eq 'elapsed_sec=.*max_rss_kb='; then
    pass "/usr/bin/time  -> /usr/bin/time"
  else
    fail_msg "/usr/bin/time  (unexpected -f output)"
    printf '%s\n' "$out" | head -n 5 | sed 's/^/       /'
  fi
else
  fail_msg "/usr/bin/time  (missing; apt package 'time')"
fi

echo
echo "--- package / import checks ---"
if python -c "import importlib.metadata as m; print(m.version('panagram'))" 2>/dev/null | grep -Eq '^[0-9]'; then
  pass "panagram package installed ($(python -c "import importlib.metadata as m; print(m.version('panagram'))"))"
else
  fail_msg "panagram package metadata"
fi

export NUMBA_CACHE_DIR="${TMPDIR:-/tmp}/numba_cache_smoke"
mkdir -p "$NUMBA_CACHE_DIR"
if python -c "import panagram" 2>/dev/null; then
  pass "import panagram"
else
  fail_msg "import panagram"
fi

if Rscript -e 'quit(status=if (requireNamespace("GENESPACE", quietly=TRUE)) 0 else 1)' >/dev/null 2>&1; then
  ver="$(Rscript -e 'cat(as.character(packageVersion("GENESPACE")))' 2>/dev/null || true)"
  pass "library GENESPACE (${ver:-installed})"
else
  fail_msg "library GENESPACE"
fi

if Rscript -e 'quit(status=if (requireNamespace("SVbyEye", quietly=TRUE)) 0 else 1)' >/dev/null 2>&1; then
  ver="$(Rscript -e 'cat(as.character(packageVersion("SVbyEye")))' 2>/dev/null || true)"
  pass "library SVbyEye (${ver:-installed})"
else
  fail_msg "library SVbyEye"
fi

# vg giraffe is a subcommand of vg (same binary)
out="$(vg giraffe --help 2>&1 || true)"
if printf '%s\n' "$out" | grep -Eqi 'giraffe|Usage:|usage:|MAPPED'; then
  pass "vg giraffe  -> $(command -v vg)"
else
  fail_msg "vg giraffe  (subcommand missing or unexpected output)"
  printf '%s\n' "$out" | head -n 10 | sed 's/^/       /'
fi

echo
echo "=== summary: ${ok_count} OK, ${fail_count} FAIL ==="
if [ "$fail" -ne 0 ]; then
  echo "Smoke test FAILED"
  exit 1
fi
echo "Smoke test PASSED — all course tools present and runnable"
exit 0
