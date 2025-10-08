# atol-qc-raw-ont

Run short read QC on Nanopore (ONT) reads.

1. Trim adaptors (`porechop`)
2. Filter reads (`filtlong`)
3. Output stats

## Installation: Use the [BioContainer](https://quay.io/repository/biocontainers/atol-qc-raw-ont?tab=tags)

*e.g.* with Apptainer/Singularity:

```bash
apptainer exec \
  docker://quay.io/biocontainers/atol-qc-raw-ont:0.1.3--pyhdfd78af_0 \
  atol-qc-raw-ont  
  
```

## Usage

> [!TIP]
> 
> **Set your locale e.g. using `--env LC_ALL=C` or `APPTAINERENV_LC_ALL=C`**.
> 
> Otherwise filtlong [crashes](https://github.com/rrwick/Filtlong/issues/48)
> with an error like `locale::facet::_S_create_c_locale name not valid`.
> 

### With a single tar file containing `*.fastq.gz` read files

**The current version of `atol-qc-raw-ont` uses `find -name "*.fastq.gz"` to
find read files, so anything named differently will be missed.**

```bash
atol-qc-raw-ont \
		--tarfile data/reads_in_directory.tar \
		--out results/reads.fastq.gz \
		--stats results/stats.json \
		--logs results/logs \
		--min-length 1000
```

### Directly input a list of `*.fastq.gz` readfiles

```bash
atol-qc-raw-ont \
		--fastqfiles \
			data/PBE32261_pass_1cb0c50e_6d3d5e3e_129.fastq.gz \
			data/PBE32261_pass_1cb0c50e_6d3d5e3e_55.fastq.gz \
			data/PBE32261_pass_1cb0c50e_6d3d5e3e_269.fastq.gz \
		--out results/reads.fastq.gz \
		--stats results/stats.json \
		--logs results/logs \
		--min-length 1000
```

### Full usage

```
usage: atol-qc-raw-ont [-h] [--min-length MIN_LENGTH] [-t THREADS] [-n]
                       (--tarfile READS_TARFILE | --fastqfiles READS [READS ...]) --out READS_OUT
                       --stats STATS [--logs LOGS_DIRECTORY]

options:
  -h, --help            show this help message and exit
  --min-length MIN_LENGTH
                        Minimum length read to output. Default is 1, i.e. keep all reads.
  -t THREADS, --threads THREADS
  -n                    Dry run

Input:
  --tarfile READS_TARFILE
                        Reads in a single tarfile. Will be searched for filenames ending in fastq.gz.
  --fastqfiles READS [READS ...]
                        Reads in fastq.gz. Multiple files are accepted.

Output:
  --out READS_OUT       Combined output in fastq.gz
  --stats STATS         Stats output (json)
  --logs LOGS_DIRECTORY
                        Log output directory. Default: logs are discarded.
```
