import pandas as pd


def get_logfile(wildcards):
    if wildcards.step == "collect_reads":
        return Path(logs_directory, "collect_reads", "{file_name}.log")
    if wildcards.step == "compress_output":
        return Path(logs_directory, "compress_output", "{file_name}.log")


def get_processed_step_logs(wildcards):
    all_names = get_all_names(wildcards)

    processed_step_logs = expand(
        Path(workingdir, "from_logs", "collect_reads", "{file_name}.csv"),
        file_name=all_names,
    )
    return processed_step_logs


def get_stats_params(wildcards, input):

    collect_stats = pd.read_csv(input.collect_stats)
    compress_stats = pd.read_csv(
        input.compress_stats, header=None, names=["read_file", "type", "reads", "bases"]
    )
    length_stats = pd.read_csv(input.length_stats)

    input_bases = int(collect_stats["bases"].sum())
    base_count = int(
        compress_stats.loc[compress_stats["type"] == "Input", "bases"].iloc[0]
    )
    read_count = int(
        compress_stats.loc[compress_stats["type"] == "Input", "reads"].iloc[0]
    )

    qc_bases_removed = input_bases - base_count

    n50_length = int(
        length_stats.loc[length_stats["type"] == "nfifty", "bases"].iloc[0]
    )

    with open(input.gchist, "r") as f:
        line = ""
        while not line.startswith("#Mean"):
            logger.error(line)
            line = f.readline()

        mean_gc_content = line.split("\t")[1]

    checksums_dict = {}

    for checksum in input.checksums:
        checksum_path = Path(checksum)
        alg = checksum_path.suffix.lstrip(".")
        file = checksum_path.with_suffix("").name

        if file not in checksums_dict:
            checksums_dict[file] = {}

        checksums_dict[file][alg] = read_checksum(checksum_path)

    return {
        "base_count": int(base_count),
        "read_count": int(read_count),
        "mean_gc_content": float(mean_gc_content),
        "qc_bases_removed": int(qc_bases_removed),
        "n50_length": int(n50_length),
        "checksums": checksums_dict,
    }


def read_checksum(checksum_file):
    with open(checksum_file, "rt") as f:
        return f.readline().split()[0]


# Configure log parsing. These fields will be grepped out of the bbduk logs and
# show up in the final CSVs.
log_fields = [
    "Containments:",
    "Duplicates Found:",
    "Duplicates:",
    "Entropy-masked:",
    "FTrimmed:",
    "Input:",
    "KTrimmed:",
    "Pairs:",
    "Reads In:",
    "Result:",
    "Singletons:",
    "nfifty:",
]


log_regex = r"\|".join(log_fields)


rule output_stats:
    input:
        collect_stats=Path(logs_directory, "collect_reads.csv"),
        compress_stats=Path(workingdir, "from_logs", "compress_output", "reformat.csv"),
        length_stats=Path(workingdir, "from_logs", "compress_output", "stats.csv"),
        gchist=Path(logs_directory, "gchist.txt"),
        schema=stats_schema,
        checksums=expand(
            Path(reads_out.as_posix() + ".{checksum}"), checksum=["md5", "sha256"]
        ),
    output:
        stats,
    benchmark:
        Path(logs_directory, "benchmarks", "output_stats.txt")
    params:
        stats=get_stats_params,
    script:
        "../scripts/render_template.py"


rule combine_step_logs:
    input:
        get_processed_step_logs,
    output:
        Path(logs_directory, "collect_reads.csv"),
    benchmark:
        Path(logs_directory, "benchmarks", "combine_step_logs.txt")
    shell:
        "gawk '(NR == 1) || (FNR > 1)' {input} > {output}"


rule process_step_logs:
    input:
        Path(workingdir, "from_logs", "{step}", "{file_name}.txt"),
    output:
        temp(Path(workingdir, "from_logs", "{step}", "{file_name}.csv")),
    benchmark:
        Path(
            logs_directory, "benchmarks", "process_step_logs", "{step}.{file_name}.txt"
        )
    shell:
        "process_step_logs {wildcards.file_name} < {input} > {output} "


rule grep_logs:
    input:
        get_logfile,
    output:
        temp(Path(workingdir, "from_logs", "{step}", "{file_name}.txt")),
    benchmark:
        Path(logs_directory, "benchmarks", "grep_logs", "{step}.{file_name}.txt")
    shell:
        # awk -F '[[:space:]]{2,}' means separated by two or more spaces
        "grep '^\\({log_regex}\\)' {input} "
        "| "
        "gawk -F '[[:space:]]{{2,}}' "
        "'{{print $1, $2, $3}}' "
        "OFS='\t' "
        "> {output} "


rule stats_sh:
    input:
        reads_out,
    output:
        Path(logs_directory, "compress_output", "stats.log"),
    params:
        mem_mb=lambda wildcards, resources: int(resources.mem_gb * 1024 * 0.9),
    log:
        Path(logs_directory, "compress_output", "stats.err"),
    benchmark:
        Path(logs_directory, "benchmarks", "compress_output", "stats.txt")
    threads: workflow.cores - 1
    resources:
        mem_gb=mem_gb - 1,
    shell:
        "echo -n 'nfifty:\t' > {output} ; "
        "stats.sh "
        "-Xmx{params.mem_mb}m "
        "in={input} "
        "format=3 "
        "2> {log} "
        "| "
        "cut -f8,9 | tail -n1 >> {output} "


rule checksum:
    wildcard_constraints:
        checksum="|".join(["md5", "sha256"]),
    input:
        Path("{file}"),
    output:
        Path("{file}.{checksum}"),
    shell:
        "{wildcards.checksum}sum "
        "{input} "
        "> {output}"
