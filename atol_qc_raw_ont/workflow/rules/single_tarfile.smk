import tempfile


def get_readfile(wildcards):
    return Path(workingdir, "readfiles", "{read_file}.fastq.gz")


def get_readfile_names(wildcards):
    read_dir = checkpoints.expand_tarfile.get().output["read_dir"]

    all_names = [x.name.split(".")[0] for x in Path(read_dir).glob("*.fastq.gz")]

    wildcard_constraints:
        read_file="|".join(all_names),

    return all_names


checkpoint expand_tarfile:
    input:
        reads_tarfile,
    output:
        read_dir=directory(Path(workingdir, "readfiles")),
    params:
        tmpdir=lambda wildcards: tempfile.mkdtemp(),
    shell:
        "mkdir -p {output.read_dir}/ && "
        "tar -xpf {input} -C {params.tmpdir} && "
        'find {params.tmpdir}/ -type f -name "*.fastq.gz" -print0 | '
        "xargs -0 -I {{}} ln -P {{}} {output.read_dir}/"
