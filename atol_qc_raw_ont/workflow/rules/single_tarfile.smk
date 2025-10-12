import tempfile


def get_tarfile_names(wildcards):
    read_dir = checkpoints.expand_tarfile.get().output["read_dir"]
    tarfile_names = [x.name.split(".")[0] for x in Path(read_dir).glob("*.fastq.gz")]
    return tarfile_names


if reads_tarfile:

    checkpoint expand_tarfile:
        input:
            reads_tarfile,
        output:
            read_dir=directory(Path(workingdir, "readfiles")),
        params:
            tmpdir=lambda wildcards: tempfile.mkdtemp(dir=workingdir),
        benchmark:
            Path(logs_directory, "benchmarks", "expand_tarfile.txt")
        shell:
            "mkdir -p {output.read_dir}/ && "
            "tar -xpf {input} -C {params.tmpdir} && "
            'find {params.tmpdir}/ -type f -name "*.fastq.gz" -print0 | '
            "xargs -0 -I {{}} ln {{}} {output.read_dir}/"
