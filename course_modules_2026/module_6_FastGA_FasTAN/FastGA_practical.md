# FastGA and FasTAN practical

Richard Durbin 15 October 2026

## Aims

1. Align two whole genomes with **FastGA** and look at the result as a standard PAF file.
2. Run the pipeline step by step, keeping the intermediate files, and look inside each one (`.1gdb`, `.gix`, `.1aln`) with the FastGA and ONEcode tools.
3. Find tandem repeats, and candidate centromeres, with **FasTAN**.
4. Optionally, see how alignment changes with evolutionary distance, using precomputed human comparisons.

## Reminder of how FastGA works (see the lecture)

* **Seeds** are semi-maximal exact matches found by merging two sorted k-mer indices (MSD radix sort, which is cache local). There is no repeat masking: seeds come from unique(ish) sequence and alignments then extend through repeats.
* **Extension** uses the O(Nd) wavefront algorithm with Levenshtein distance (linear indel cost), requiring >70% match over the last 100 bp.
* Alignments are stored as **trace points** every 100 bp, which is very fast and compact, in a **`.1aln`** ONEcode file. Long-range chaining is a separate step (`ALNchain`).
* Coordinates in `.1aln` are at **contig** level: scaffolds are split into contigs at runs of Ns. The `.1gdb` information that maps contigs back to scaffolds is embedded in the `.1aln` header.

We will examine files with `GDBshow`, `GDBstat`, `GIXshow`, `ALNshow`, `ALNplot`, `ALNview` (Mac), and `ONEview` for any ONEcode file.

## Setup

Start in the course data directory (the one containing `athaliana/`). Make a clean subdirectory called `fast`, move into it, and copy in the two Arabidopsis genomes:

```bash
mkdir fast
cd fast
cp ../athaliana/col0.fa ../athaliana/cvi1.fa .
```

| File | What it is |
|---|---|
| `col0.fa` | *Arabidopsis thaliana* Col-0, 5 chromosomes, 129 Mb |
| `cvi1.fa` | *A. thaliana* Cvi-0, 5 chromosomes, 134 Mb |

Three more *A. thaliana* accessions are in `../athaliana` (`est1.fa`, `rab_r1.fa`, `tanz1.fa`).

All the commands below are run inside `fast/`.

## Part 1: FastGA straight to PAF

```bash
FastGA -v col0 cvi1 > col0-cvi1.paf
```

With no other options FastGA builds what it needs from `col0.fa` and `cvi1.fa`, writes PAF to standard output, and removes its temporary files. `-v` reports progress and resources; add `-T<n>` to set the number of threads.

You should see output like this (this run used 4 cores on a Linux machine, so your times will differ):

```
  Creating genome data base (GDB) col0.1gdb in the current directory
  Total Resources:  0.383u  0.047s  0.442w  97.5%  0MB
  Creating genome index (GIX) col0.gix in the current directory
  Partitioning K-mers via pos-lists into 8 parts
  Resources for phase:  2.935u  1.106s  1.121w  360.5%
  Starting sort & index output of each part
    Done
  Sampled:      97774989 ( 75.6%) kmers/positions
  Resources for phase:  12.497u  7.852s  10.192w  199.7%
  Total Resources:  15.432u  8.958s  11.313w  215.6%  0MB
  Creating genome data base (GDB) cvi1.1gdb in the current directory
  Total Resources:  0.315u  0.067s  0.383w  99.7%  0MB
  Creating genome index (GIX) cvi1.gix in the current directory
  Partitioning K-mers via pos-lists into 8 parts
  Resources for phase:  2.593u  0.147s  0.721w  380.0%
  Starting sort & index output of each part
    Done
  Sampled:     101274880 ( 75.5%) kmers/positions
  Resources for phase:  12.659u  7.387s  10.420w  192.4%
  Total Resources:  15.253u  7.535s  11.141w  204.5%  0MB
  Using 8 threads
  Starting adaptive seed merge for G1
    Completed 100%
  Total seeds = 60476935, ave. len = 31.9, seeds per genome position = 0.5
  Resources for phase:  7.555u  16.065s  7.595w  311.0%
  Starting seed sort and alignment search, 16 parts
    Done
  Total hits over 85bp = 167249, 182305 aln's, 139757 non-redundant aln's of ave len 4802
  Sorting and merging alignments
  Resources for phase:  1:04.284u  1.143s  19.167w  341.3%
  Converting aln's to PAF-format
  Resources for phase:  0.000u  0.010s  0.216w  4.9%
  Total Resources:  1:11.840u  17.218s  26.979w  330.1%  0MB
```

The run took about 51 s wall time. It produced 139,757 alignments, one per line of `col0-cvi1.paf`, which is 15 MB. Now look at the file:

```bash
less col0-cvi1.paf
```

(press `q` to quit `less`). The top few lines are:

```
CP138171.1	32215923	0	1017	+	CP138178.1	26955220	37094	38092	977	1007	255	dv:f:0.0393	df:i:61
CP138171.1	32215923	0	1017	-	CP138179.1	20800751	20799678	20800678	971	1008	255	dv:f:0.0452	df:i:74
CP138171.1	32215923	0	1017	-	CP138179.1	20800751	20797862	20798856	968	1005	255	dv:f:0.0481	df:i:75
CP138171.1	32215923	0	1017	-	CP138179.1	20800751	20797792	20798786	967	1005	255	dv:f:0.0491	df:i:77
CP138171.1	32215923	0	1017	-	CP138179.1	20800751	20797771	20798765	970	1005	255	dv:f:0.0462	df:i:70
```

**Explore**

* How long did each phase take? Which phase dominates?
* How many alignments are there? Look at the first few lines. What are the columns?
* What is the distribution of alignment lengths? Of identities (column 10 divided by column 11)?
* How much of each Col-0 chromosome is covered by alignments to Cvi-0? Where are the biggest gaps? (Hint: centromeres.)

## Part 2: Step by step, keeping the intermediate files

We will now do this in a more sophisticated way.

```bash
FastGA -vk -1:col0-cvi1 col0 cvi1
```

The output is:

```
  Creating genome data base (GDB) col0.1gdb in the current directory
  Total Resources:  0.306u  0.060s  0.373w  98.5%  0MB
  Creating genome index (GIX) col0.gix in the current directory
  Partitioning K-mers via pos-lists into 8 parts
  Resources for phase:  2.381u  0.119s  0.702w  356.1%
  Starting sort & index output of each part
    Done
  Sampled:      97774989 ( 75.6%) kmers/positions
  Resources for phase:  10.993u  1.556s  4.406w  284.8%
  Total Resources:  13.374u  1.675s  5.109w  294.6%  0MB
  Creating genome data base (GDB) cvi1.1gdb in the current directory
  Total Resources:  0.318u  0.048s  0.376w  97.5%  0MB
  Creating genome index (GIX) cvi1.gix in the current directory
  Partitioning K-mers via pos-lists into 8 parts
  Resources for phase:  2.308u  0.123s  0.676w  359.6%
  Starting sort & index output of each part
    Done
  Sampled:     101274880 ( 75.5%) kmers/positions
  Resources for phase:  12.345u  4.444s  7.602w  220.8%
  Total Resources:  14.654u  4.568s  8.279w  232.2%  0MB
  Using 8 threads
  Starting adaptive seed merge for G1
    Completed 100%
  Total seeds = 60476935, ave. len = 31.9, seeds per genome position = 0.5
  Resources for phase:  6.422u  14.937s  6.880w  310.5%
  Starting seed sort and alignment search, 16 parts
    Done
  Total hits over 85bp = 167249, 182305 aln's, 139757 non-redundant aln's of ave len 4802
  Sorting and merging alignments
  Resources for phase:  1:03.075u  1.286s  18.475w  348.4%
  Total Resources:  1:09.498u  16.229s  25.361w  338.0%  0MB
```

Now list the directory:

```bash
ls -l
```

```
total 549772
-rw-r--r-- 1 user user  12332802 Oct 15 09:09 col0-cvi1.1aln
-rw-r--r-- 1 user user  15403187 Oct 15 09:09 col0-cvi1.paf
-rw-r--r-- 1 user user      1361 Oct 15 09:09 col0.1gdb
-r--r--r-- 1 user user 130872559 Oct 15 09:08 col0.fa
-rw-r--r-- 1 user user 134218008 Oct 15 09:09 col0.gix
-rw-r--r-- 1 user user      1490 Oct 15 09:09 cvi1.1gdb
-r--r--r-- 1 user user 135884971 Oct 15 09:08 cvi1.fa
-rw-r--r-- 1 user user 134218068 Oct 15 09:09 cvi1.gix
```

Now look inside the `.1aln` file with ONEview (use the arrow keys to scroll sideways, `q` to quit):

```bash
ONEview col0-cvi1.1aln | less -S
```

The top of the output looks like this (`...` marks lines skipped here):

```
1 3 aln 2 1
! 4 6 FastGA 3 0.1 33 FastGA -vk -1:col0-cvi1 col0 cvi1 19 2026-10-15_09:09:51
! 4 7 ONEview 3 0.0 22 ONEview col0-cvi1.1aln 19 2026-10-15_09:10:54
.
< 11 ./col0.1gdb 1
< 11 ./cvi1.1gdb 2
< 15 /home/user/fast 3
.
~ D t 1 3 INT                 trace point spacing in a - global
~ O g 0                       groups scaffolds into a GDB skeleton
~ G S 0                         collection of scaffolds constituting a GDB
~ O S 1 6 STRING              id for a scaffold
~ D G 1 3 INT                 gap of given length
~ D C 1 3 INT                 contig of given length
~ O a 0                       groups A's into a colinear chain
~ G A 0                         chains (a) group alignment objects (A)
~ D p 2 3 INT 3 INT           spacing in a,b between end of previous alignment and start of next
~ O A 6 3 INT 3 INT 3 INT 3 INT 3 INT 3 INT
~ D L 2 3 INT 3 INT           lengths of sequences a and b
~ D R 0                       flag: reverse-complement sequence b
~ D D 1 3 INT                 differences: number of diffs = substitions + indels
~ D T 1 8 INT_LIST            trace points in b
~ D X 1 8 INT_LIST            number of differences in alignment per trace interval
~ D Q 1 3 INT                 quality: alignment confidence in phred units (currently unused)
~ D E 1 3 INT                 match: number of equal bases (currently unused)
~ D Z 1 6 STRING              cigar string: encodes precise alignment (currently unused)
~ D U 1 3 INT                 putative unit size of a TR alignment (FASTAN)
.
# t 1
# g 2
% g # C 72
% g # G 67
% g # S 5
% g + S 335
# S 10
@ S 67
+ S 670
% S # C 21
% S # G 20
# G 119
# C 129
# A 139757
% A # D 1
% A # R 1
% A # T 1
% A + T 6469
% A # X 1
% A + X 6469
# R 63270
# D 139757
# T 139757
@ T 6469
+ T 6850215
# X 139757
@ X 6469
+ X 6850215
.
t 100
g
S 67 CP138171.1 Arabidopsis thaliana ecotype Col-0 chromosome 1 sequence
C 1017
G 100
C 15548559
G 100
C 787
G 100
...
A 0 0 1017 21 37094 38092
D 61
T 11 100 94 90 97 99 100 100 100 102 100 16
X 11 4 17 18 5 4 0 2 1 6 1 3
A 0 0 1017 51 73 1073
R
D 74
T 11 100 94 88 97 99 104 100 99 103 100 16
X 11 4 13 12 5 5 5 3 7 12 5 3
A 0 0 1017 51 1895 2889
R
D 75
```

* `-k` keeps the genome databases (`.1gdb`) and indices (`.gix`) for reuse.
* `-1:col0-cvi1` writes the alignments as `col0-cvi1.1aln` instead of PAF.

**Explore the files**

```bash
ls -la                       # note the hidden .col0.bps and .col0.ktab.* files
GDBstat col0                 # sequence, scaffold and contig statistics
GDBshow col0 | head
GIXshow col0 | head          # the k-mer index
ALNshow col0-cvi1 | head     # the alignments
ALNplot col0-cvi1            # dot plot
ONEview -H col0-cvi1.1aln    # ONEcode header: provenance, schema, counts
ONEview col0-cvi1.1aln | head -40   # the data, in ascii
ALNtoPAF col0-cvi1 > col0-cvi1.2.paf
ALNtoPSL col0-cvi1 > col0-cvi1.psl
ALNchain col0-cvi1           # long-range chaining
```

Run each command with no arguments to see its options.

**Questions**

* Run the `FastGA -vk` command a second time. What is different, and why?
* What fraction of k-mer positions ended up in the index? Why not all of them?
* Compare the sizes of the `.1aln`, `.paf` and `.psl` files. Why is the `.1aln` so much smaller?
* In the ONEview output, find the `A`, `R`, `D`, `T` and `X` lines for one alignment. What does each one hold?
* Look at the dot plot. Can you see inversions or other rearrangements between Col-0 and Cvi-0?
* How many chains does `ALNchain` produce, compared with the number of alignments?
* **If you are on a Mac**, open `col0-cvi1.1aln` in **ALNview** and zoom in on a centromere.

## Part 3: Tandem repeats with FasTAN

FasTAN looks for off-diagonal self-alignments that indicate tandem repeats, with unit sizes up to 30 kb and up to ~20 to 25% divergence. The options `-vamp` mean: verbose, write the alignments to a `.1aln` file (`-a`), write the tandem array intervals to a `.1ano` annotation file (`-m`), and parse each array into units (`-p`). `-o` sets the output name.

```bash
FasTAN -vamp -ocol0-tan col0
```

It reuses `col0.1gdb` from Part 2, and takes about 20 s on 4 cores. With progress lines removed, the output is:

```
  Database loaded, begin scan of 57 contigs
  Resources for phase:  1:13.770u  0.069s  20.945w  352.5%
  Total Resources:  1:13.770u  0.069s  20.945w  352.5%  0MB
```

and it writes `col0-tan.1aln` and `col0-tan.1ano`.

We will now run a set of tools from the **alntools** repository, <https://github.com/richarddurbin/alntools>, which has documentation for each of them. First convert the FasTAN alignments into a BED file with `tanbed`:

```bash
tanbed col0-tan.1aln > col0-tan.bed
```

```
read GDB from col0-tan.1aln : 5 seqs 57 contigs (52 gaps), totSeq 129256504 totCtg 129249752 (99.995%)
processed 17332 alignments total length 14574609 from col0-tan.1aln length 129256504 (11.3 %)
```

Each line of the BED file is one tandem array: sequence, start, end, unit size, and identity between adjacent units (per thousand):

```bash
head col0-tan.bed
```

```
CP138171.1	0	1017	7	957
CP138171.1	1140	2982	7	942
CP138171.1	7203	7241	2	894
CP138171.1	9483	9586	31	883
CP138171.1	10904	10930	2	961
CP138171.1	11582	11613	2	1000
CP138171.1	14830	14874	9	886
CP138171.1	19949	20392	220	993
CP138171.1	21477	21571	20	797
CP138171.1	23423	23450	2	962
```

To total the bases in arrays by unit size:

```bash
awk '{n[$4] += $3-$2} END {for (u in n) print n[u], u}' col0-tan.bed | sort -nr | head
```

**Explore**

* How much of the Col-0 genome is in tandem repeats? (Across 577 VGP assemblies this ranged from 0.8% to 29.5%, mean 8.5%.)
* What are the commonest repeat unit sizes? Is there a dominant unit size forming a large array on each chromosome? That is your candidate centromere repeat. (The Arabidopsis centromere repeat, CEN180, is about 178 bp.)
* Where are those arrays? Do they coincide with the gaps in Col-0 vs Cvi-0 alignment coverage from Part 1?
* Try the same on `cvi1`. Are the centromere arrays the same size?

### Consensus sequences of the repeat units

Now run `tancons` with its default settings. This builds a consensus sequence for each tandem repeat array that has more than 100 copies of exactly the unit length, using the parse in the `.1ano` file:

```bash
tancons col0-tan.1ano > col0-tan-cons.fa
grep -c '>' col0-tan-cons.fa
grep '>' col0-tan-cons.fa | less
```

There are 75 consensus sequences, in decreasing order of number of copies. Each name gives the unit size, the array location, the number of copies used, and the average percent agreement with the consensus:

```
>cons178#CP138172.1:4018135-4628690#2865#96.6
>cons178#CP138171.1:15765453-16237848#2140#97.0
>cons178#CP138174.1:4323651-4837748#2031#93.4
>cons178#CP138172.1:3609365-3999372#1965#96.0
>cons178#CP138175.1:12697212-13080462#1599#95.1
>cons178#CP138171.1:16335357-16726460#1531#95.4
>cons178#CP138172.1:5201020-5511124#1449#95.7
>cons178#CP138171.1:14925357-15185482#1139#95.0
...
>cons178#CP138175.1:12388576-12410882#111#95.5
>cons159#CP138171.1:14505278-14529810#108#87.4
>cons178#CP138174.1:5484807-5504768#106#96.6
>cons178#CP138171.1:14902620-14923594#100#94.3
```

Many of these arrays are presumably the same repeat. `satmatch` aligns all the consensus sequences against each other, in both orientations and allowing any rotation (`-loop`), clusters them into families, and writes one representative per family to `satfams.fa`:

```bash
satmatch -loop -fa satfams.fa col0-tan-cons.fa > col0-satmatch.txt
```

```
75 sequences, total length 13231
found 1 frequency-based clusters
threshold 0.676
user	0.290742	system	0.000000	elapsed 0.291912	alloc_max 16 MB	max_RSS	8
```

`col0-satmatch.txt` lists the clusters and their members (here shortened, and without the `mark` lines that record clusters being built):

```
cluster 1 count 72 minLen 178 repLen 178 tccatatgagtctttggct...
  cons178#CP138172.1:4018135-4628690#2865#96.6	178	0
  cons178#CP138171.1:15765453-16237848#2140#97.0	178	0
  cons178#CP138174.1:4323651-4837748#2031#93.4	178	0
  ...
cluster 2 count 2 minLen 159 repLen 159 caaaagaggctaaaaccaac...
  cons159#CP138171.1:14452467-14497647#171#84.5	159	0
  cons159#CP138171.1:14505278-14529810#108#87.4	159	0
```

```bash
cat satfams.fa
```

```
>sat-1-178
tccatatgagtctttggctttgtgtcttctaacaaggaaacactacttaggcttttaagatcgggttgcg...
>sat-2-159
caaaagaggctaaaaccaacaaaaaattgcttagaagcagtaaatagctttgttagtgtttttatggtca...
```

(sequences cut short here). The 72 arrays with 178 bp units collapse to a single family, the CEN180 centromere repeat, and a second family of 159 bp units comes from two arrays on chromosome 1. The one 97 bp consensus did not join any cluster, so it has no representative.

## Going further

* Align another accession from `../athaliana` (`est1.fa`, `rab_r1.fa` or `tanz1.fa`) against Col-0. Because you kept `col0.gix`, only the new genome needs indexing.
* Change the minimum alignment length or identity thresholds (see `FastGA` with no arguments) and see how the output changes.
* **Precomputed larger comparisons** are in the `fastga/` directory, made with commands like `FastGA -v -T8 -1:hg002-mMusMus hg002_pat mMusMus`. They are too big to run in class, but you can explore them with `ALNshow`, `ALNplot`, `ONEview` and `ALNtoPAF`:

  | File | Comparison | Reference run (8 threads) |
  |---|---|---|
  | `hg002-mMusMus.1aln` | human (HG002 paternal) vs mouse | 58 s wall, 9.8 GB, 221k non-redundant alignments, average 0.7 kb |
  | `hg002-pan27.1aln` | HG002 paternal vs PAN027 paternal | 2 h 6 min wall, 10.4 GB, 543k non-redundant alignments, average 90 kb |

  Why does the closer comparison take so much longer, even though it found fewer seeds (1.2 billion vs 2.2 billion)? What stops the alignments being chromosome length?

## Links

* FastGA: <https://github.com/thegenemyers/FASTGA>
* FasTAN: <https://github.com/thegenemyers/FASTAN>
* ONEcode: <https://github.com/thegenemyers/ONEcode>
