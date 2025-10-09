import pandas as pd


def get_logfile(wildcards):
    if wildcards.step == "collect_reads":
        return Path(logs_directory, "collect_reads", "{file_name}.log")
    if wildcards.step == "compress_output":
        return Path(logs_directory, "compress_output", "reformat.log")


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

    input_bases = int(collect_stats["bases"].sum())
    base_count = int(
        compress_stats.loc[compress_stats["type"] == "Input", "bases"].iloc[0]
    )
    read_count = int(
        compress_stats.loc[compress_stats["type"] == "Input", "reads"].iloc[0]
    )

    qc_bases_removed = input_bases - base_count

    with open(input.gchist, "r") as f:
        line = ""
        while not line.startswith("#Mean"):
            logger.error(line)
            line = f.readline()

        mean_gc_content = line.split("\t")[1]

    return {
        "base_count": int(base_count),
        "read_count": int(read_count),
        "mean_gc_content": float(mean_gc_content),
        "qc_bases_removed": int(qc_bases_removed),
    }


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
]


log_regex = "\|".join(log_fields)


rule output_stats:
    input:
        collect_stats=Path(logs_directory, "collect_reads.csv"),
        compress_stats=Path(workingdir, "from_logs", "compress_output", "reformat.csv"),
        gchist=Path(logs_directory, "gchist.txt"),
        template=stats_template,
    output:
        stats,
    params:
        stats=get_stats_params,
    template_engine:
        "jinja2"


rule combine_step_logs:
    input:
        get_processed_step_logs,
    output:
        Path(logs_directory, "collect_reads.csv"),
    shell:
        # From https://unix.stackexchange.com/a/558965. Takes the header from
        # the first file and skips subsequent headers.
        "sleep 10 ; "
        "gawk '(NR == 1) || (FNR > 1)' {input} > {output}"


rule process_step_logs:
    input:
        Path(workingdir, "from_logs", "{step}", "{file_name}.txt"),
    output:
        temp(Path(workingdir, "from_logs", "{step}", "{file_name}.csv")),
    shell:
        "process_step_logs {wildcards.file_name} < {input} > {output} "


rule grep_logs:
    input:
        get_logfile,
    output:
        temp(Path(workingdir, "from_logs", "{step}", "{file_name}.txt")),
    shell:
        # awk -F '[[:space:]]{2,}' means separated by two or more spaces
        "grep '^\({log_regex}\)' {input} "
        "| "
        "gawk -F '[[:space:]]{{2,}}' "
        "'{{print $1, $2, $3}}' "
        "OFS='\t' "
        "> {output} "
