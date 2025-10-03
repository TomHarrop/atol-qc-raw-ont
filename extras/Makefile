shell=/bin/bash

local_version := $(shell python3 -m setuptools_scm)
tmpdir := $(shell mktemp -d)

test_tarfile:
	atol-qc-raw-ont \
		--tarfile test-data/reads_in_directory.tar \
		--out test-output/tarfile/reads.fastq.gz \
		--stats test-output/tarfile/stats.json \
		--logs test-output/tarfile/logs \
		--min-length 1000

# rule expand_tarfile should fail because the tarfile contains duplicate
# readfiles
test_bad_tarfile:
	atol-qc-raw-ont \
		--tarfile test-data/reads_in_directory_bad.tar \
		--out test-output/reads.fastq.gz \
		--stats test-output/stats.json \
		--logs test-output/logs \
		--min-length 1000


test_local:
	atol-qc-raw-ont \
		--fastqfiles \
			test-data/reads2/PBE32261_pass_1cb0c50e_6d3d5e3e_129.fastq.gz \
			test-data/reads2/PBE32261_pass_1cb0c50e_6d3d5e3e_55.fastq.gz \
			test-data/reads2/PBE32261_pass_1cb0c50e_6d3d5e3e_269.fastq.gz \
		--out test-output/local/reads.fastq.gz \
		--stats test-output/local/stats.json \
		--logs test-output/local/logs \
		--min-length 1000
