shell=/bin/bash

local_version := $(shell python3 -m setuptools_scm)
tmpdir := $(shell mktemp -d)

test_local:
	atol-qc-raw-ont \
		--in \
			test-data/reads2/PBE32261_pass_1cb0c50e_6d3d5e3e_129.fastq.gz \
			test-data/reads2/PBE32261_pass_1cb0c50e_6d3d5e3e_55.fastq.gz \
			test-data/reads2/PBE32261_pass_1cb0c50e_6d3d5e3e_269.fastq.gz \
		--out test-output/reads.fastq.gz \
		--stats test-output/stats.json \
		--logs test-output/logs \
		--min-length 1000
