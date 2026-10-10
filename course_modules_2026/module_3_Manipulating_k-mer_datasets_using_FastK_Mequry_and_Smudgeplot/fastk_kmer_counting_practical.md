# Practical: K-mer Counting and Operations Using FastK

## Prerequisites

This practical introduces k-mer counting with **FastK**, inspecting the resulting k-mer database, viewing k-mer histograms and read profiles, and combining k-mer tables with **Logex**.

You should have access to:
- FastK and its companion tools (`Histex`, `Tabex`, `Profex`, and `Logex`)
- The course dataset, including the main trio dataset if supplied
- A terminal in the environment where the FastK tools are installed

## 1. Inspect the input data

Before counting k-mers, download the input files and check that they contain sequence data.

```bash
mkdir -p course_data_2026/trio && cd course_data_2026/trio
wget https://kj11.cog.sanger.ac.uk/kmer_course_data/kmer_course_data/{Child,Father,Mother}.Reads.fasta
wget https://kj11.cog.sanger.ac.uk/kmer_course_data/kmer_course_data/Hap{1,2}.fasta
cd ../..
```

these are uncompressed sequences, you can check what is in those files:

```bash
head course_data_2026/trio/Child.Reads.fasta
```


## 2. Build k-mer tables with FastK

FastK counts k-mers and produces a histogram by default. The `-k` option sets the k-mer length, `-t` sets the minimum count to retain in the table, `-T` sets the number of threads, and `-M` sets the memory limit. The `-N` option specifies the output root.

Run FastK on the child reads using 21-mers, retaining k-mers with count at least 1 and requesting profiles:

```bash
FastK -v -k21 -t1 -p -T4 course_data_2025/trio.5.40x/Child.Reads.fasta -NChild
```

Repeat for the mother and father reads:

```bash
FastK -v -k21 -t1 -p -T4 course_data_2025/trio.5.40x/Mother.Reads.fasta -NMother
FastK -v -k21 -t1 -p -T4 course_data_2025/trio.5.40x/Father.Reads.fasta -NFather
```

If the course dataset uses different filenames, substitute the actual paths. FastK accepts FASTA, FASTQ, SAM, BAM, and CRAM inputs; input files in a single run must be of the same type.

Inspect the output files:

```bash
ls -lh Child*
```

### Task 2.1
Run FastK on the child reads with `-k21`, `-t1`, and `-p`. Record the output files created.

**Answer**

ANSWER

### Task 2.2
What do the `.hist`, `.ktab`, and `.prof` outputs represent?

**Answer**

ANSWER

### Task 2.3
Explain the purpose of each option in the command: `-k21`, `-t1`, `-p`, `-T4`, and `-NChild`.

**Answer**

ANSWER

### Task 2.4
What does FastK do with a k-mer that contains a base other than A, C, G, or T (for example, `N`)?

**Answer**

ANSWER

## 3. Inspect k-mer histograms with Histex

Use `Histex` to print the histogram. Redirect the output to a tab-delimited file:

```bash
Histex -G Child > Child.hist
head Child.hist
```

The histogram has two columns: k-mer coverage/count and the number of distinct k-mers observed at that count (frequency). The `-G` option produces a GenomeScope-ready histogram. The `-A` option requests tab-delimited ASCII output, while `-k` reports k-mer instances rather than the number of unique k-mers.

Examples:

```bash
Histex Child
Histex -h1:100 Child
Histex -A Child > Child_ascii.hist
Histex -k Child
Histex -G -h1000 Child > Child_genomescope.hist
```

### Task 3.1
Generate a histogram for the child table and inspect the first few lines. What does each column represent?

**Answer**

ANSWER

### Task 3.2
Run `Histex Child` and `Histex -k Child`. Explain the difference between a histogram of unique k-mers and a histogram of k-mer instances.

**Answer**

ANSWER

### Task 3.3
Use `Histex -h1:100 Child` to display a restricted coverage range. What does the `-h` option control?

**Answer**

ANSWER

### Task 3.4
Why might low-coverage k-mers be abundant in a sequencing dataset? What feature of the histogram can help distinguish these from higher-coverage genomic k-mers?

**Answer**

ANSWER

### Task 3.5
Explain why the final histogram bin can represent an accumulated range of counts rather than only k-mers with exactly that count.

**Answer**

ANSWER

## 4. Inspect k-mer tables with Tabex

`Tabex` can list entries in a k-mer table, check that the table is ordered correctly, or look up a particular k-mer.

```bash
Tabex Child CHECK
Tabex Child LIST
```

To suppress entries whose counts are below a threshold:

```bash
Tabex -t10 Child LIST
```

To look up a particular k-mer, provide a sequence of the correct k-mer length for the table:

```bash
Tabex Child AAAAAAAAAAAAAAAAAAAAA
```

The exact result depends on the dataset. A k-mer that is absent from the table is reported as not found. FastK tables contain canonical k-mers.

### Task 4.1
Run `Tabex Child CHECK`. What does the tool report, and what is it checking?

**Answer**

ANSWER

### Task 4.2
List the table entries with `Tabex Child LIST`. Describe how the entries are ordered.

**Answer**

ANSWER

### Task 4.3
Run `Tabex -t10 Child LIST`. What does the threshold change about the displayed output?

**Answer**

ANSWER

### Task 4.4
Look up one 21-mer from your data using `Tabex`. Record whether it is found and, if found, its count.

**Answer**

ANSWER

### Task 4.5
What does it mean for a k-mer to be canonical, and why might a sequence that you expect not appear as a separate table entry?

**Answer**

ANSWER

## 5. Inspect read profiles with Profex

When FastK is run with `-p`, it creates a profile for each sequence. The profile gives the count of each successive k-mer along that sequence. `Profex` can display selected reads; read numbering starts at 1. The `-z` option compresses consecutive runs of equal profile values, and `-A` requests tab-delimited output.

```bash
Profex Child 1
Profex -z Child 1
Profex -A Child 1
Profex Child 1-5
```

### Task 5.1
Display the profile for read 1. What does each profile value describe?

**Answer**

ANSWER

### Task 5.2
Display the same read using `Profex -z Child 1`. How does the output differ, and when is this representation useful?

**Answer**

ANSWER

### Task 5.3
What might a stretch of low or zero profile values indicate? Give a possible reason for zero values based on FastK's handling of invalid or absent k-mers.

**Answer**

ANSWER

## 6. Perform k-mer table operations with Logex

`Logex` combines k-mer tables using logical expressions. In the examples below, `A` refers to the first input table, `B` to the second, and `C` to the third.

| Operator | Meaning |
|---|---|
| `A \| B` | Union: k-mers present in A or B |
| `A & B` | Intersection: k-mers present in both A and B |
| `A - B` | Difference: k-mers present in A but not B |
| `A ^ B` | Exclusive OR: k-mers present in one table but not both |

For union and intersection, count operators specify how counts from k-mers present in both tables are combined. Examples include `|+` (sum), `|<` (minimum), `|>` (maximum), `|*` (average), `|.` (use the left count when present, otherwise the right), and `|-` (left count minus right count, with a minimum of zero). The same count modifiers can be used with intersection.

A postfix range such as `[5-10]` retains k-mers whose counts are in that range. `[-10,20-]` retains counts from 1–10 or 20 and above. The prefix `#` changes all k-mer counts in a table to 1.

Example command structure:

```bash
Logex 'out=(A|+B)' Child Mother
```

This writes a table named `out` using the sum-count union of the `Child` and `Mother` tables. Use quoted expressions so the shell passes the expression to Logex as one argument.

### Task 6.1
Use Logex to create a union table containing k-mers found in either the child or mother table. Choose a count operator and explain what the operator does.

**Answer**

ANSWER

### Task 6.2
Create an intersection table containing only k-mers present in both the child and mother tables.

**Answer**

ANSWER

### Task 6.3
Create a difference table containing k-mers present in the child table but absent from the mother table. Explain what this table represents.

**Answer**

ANSWER

### Task 6.4
What is the difference between `A | B` and `A |+ B`?

**Answer**

ANSWER

### Task 6.5
Write a Logex expression that keeps only k-mers with counts of 10 or higher from table A.

**Answer**

ANSWER

### Task 6.6
What does the prefix operator `#` do? What could be learned from combining `#A` and `#B` with a sum-count union?

**Answer**

ANSWER

## 7. Relative profiles

FastK can profile input sequences using k-mer counts from a different table. This is useful, for example, to profile child reads against a table of k-mers specific to the mother or father.

The `-p:<table>` option specifies the table used for profiling. For example:

```bash
FastK -p:Mother Child.Reads.fasta -NChild_Mother
FastK -p:Father Child.Reads.fasta -NChild_Father
```

Use the actual table roots and input paths in your environment. The resulting profiles report counts from the specified reference table projected onto each input sequence; a profile value may be zero.

### Task 7.1
Generate a relative profile of the child reads against the mother table and against the father table.

**Answer**

ANSWER

### Task 7.2
Use `Profex -z` to inspect several reads in both relative-profile outputs. What pattern might help you decide whether a read is more consistent with the maternal or paternal k-mer set?

**Answer**

ANSWER

### Task 7.3
Why can a relative profile contain zero counts even when the input read itself is valid DNA sequence?

**Answer**

ANSWER

## 8. Homopolymer compression and barcode prefixes

FastK can count in homopolymer-compressed space with `-c`. In homopolymer compression, consecutive repeats of the same base are reduced to a single base; for example, `gtaaaattgccctaatgg` becomes `gtatgctatgg` (illustrative transformation from the lecture's explanation).

The `-bc<n>` option tells FastK to ignore the first *n* bases of each read or sequence, which can be useful when reads begin with barcode sequences.

### Task 8.1
In your own words, describe homopolymer compression and the effect of using FastK's `-c` option.

**Answer**

ANSWER

### Task 8.2
What does `-bc8` instruct FastK to do?

**Answer**

ANSWER

### Task 8.3
Give one situation where ignoring a barcode prefix or counting in homopolymer-compressed space could be useful.

**Answer**

ANSWER

## 9. Practical synthesis

### Task 9.1
Run FastK on one supplied read dataset, produce a histogram with Histex, inspect the table with Tabex, and inspect at least one read profile with Profex. Record the commands you used.

**Answer**

ANSWER

### Task 9.2
Summarise one biological or technical observation you can make from the histogram or read profiles. Refer to the evidence in your own output.

**Answer**

ANSWER

### Task 9.3
A k-mer table can be very large and may rely on hidden companion files in addition to the visible `.ktab` file. Why should you use the FastK companion file-management tools (such as `Fastmv`, `Fastcp`, or `Fastrm`) rather than moving or deleting only the visible table stub?

**Answer**

ANSWER

## Checklist

- [ ] Inspected the input files.
- [ ] Ran FastK and identified the output files.
- [ ] Generated and interpreted a histogram with Histex.
- [ ] Inspected a k-mer table with Tabex.
- [ ] Inspected a read profile with Profex.
- [ ] Practised at least two Logex operations.
- [ ] Generated or interpreted a relative profile.
- [ ] Answered the reflection questions.

