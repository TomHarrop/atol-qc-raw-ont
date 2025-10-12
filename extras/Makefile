shell=/bin/bash

local_version := $(shell python3 -m setuptools_scm)
tmpdir := $(shell mktemp -d)
branch := $(shell git rev-parse --abbrev-ref HEAD)


test_tarfile:
	python3 -m cProfile -o "test-output/profiling/tarfile.cProfile.stats" \
	-m  atol_qc_raw_ont.__main__ \
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


changelog: CHANGELOG.md

CHANGELOG.md: .git/index
	gitchangelog > $(tmpdir)/CHANGELOG.md
	apptainer exec docker://davidanson/markdownlint-cli2:v0.13.0 \
	markdownlint-cli2 \
	--fix \
	:$(tmpdir)/CHANGELOG.md || true
	mv $(tmpdir)/CHANGELOG.md ./CHANGELOG.md
	git add CHANGELOG.md
	git commit -m 'changelog !cosmetic'
	git push origin $(branch)
