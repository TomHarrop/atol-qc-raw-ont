#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from importlib import resources
from importlib.metadata import metadata, files
from pathlib import Path
from snakemake.logging import logger
import argparse
from snakemake.api import (
    SnakemakeApi,
    ResourceSettings,
    ConfigSettings,
    ExecutionSettings,
    OutputSettings,
    StorageSettings,
    DAGSettings,
)
from snakemake.settings.enums import Quietness, RerunTrigger


def parse_arguments():
    parser = argparse.ArgumentParser()

    # options
    parser.add_argument(
        "--min-length",
        type=int,
        default=1,
        dest="min_length",
        help="Minimum length read to output. Default is 1, i.e. keep all reads.",
    )

    parser.add_argument("-t", "--threads", type=int, default=16, dest="threads")
    parser.add_argument(
        "-m",
        "--mem",
        help=(
            "Intended maximum RAM in GB. "
            "NOTE: some steps (e.g. filtlong) "
            "don't allow memory usage to be specified by the user."
        ),
        type=int,
        default=32,
        dest="mem_gb",
    )
    parser.add_argument("-n", help="Dry run", dest="dry_run", action="store_true")

    # inputs
    input_group = parser.add_argument_group("Input")

    # test data look to be about 30,000 reads per fastq file
    reads_group = input_group.add_mutually_exclusive_group(required=True)

    reads_group.add_argument(
        "--tarfile",
        type=Path,
        help="Reads in a single tarfile. Will be searched for filenames ending in fastq.gz.",
        dest="reads_tarfile",
    )

    reads_group.add_argument(
        "--fastqfiles",
        type=Path,
        help="Reads in fastq.gz. Multiple files are accepted.",
        dest="reads",
        nargs="+",  # should always be a list of Path objects
    )

    # outputs
    output_group = parser.add_argument_group("Output")

    output_group.add_argument(
        "--out",
        required=True,
        type=Path,
        help="Combined output in fastq.gz",
        dest="reads_out",
    )
    output_group.add_argument(
        "--stats", required=True, type=Path, help="Stats output (json)", dest="stats"
    )
    output_group.add_argument(
        "--logs",
        required=False,
        type=Path,
        help="Log output directory. Default: logs are discarded.",
        dest="logs_directory",
    )

    return parser.parse_args()


def main():
    # print version info
    pkg_metadata = metadata(__package__)

    pkg_name = pkg_metadata.get("Name")
    pkg_version = pkg_metadata.get("Version")

    logger.warning(f"{pkg_name} version {pkg_version}")

    # get the snakefile
    snakefile = Path(resources.files(__package__), "workflow", "Snakefile")
    if snakefile.is_file():
        logger.debug(f"Using snakefile {snakefile}")
    else:
        raise FileNotFoundError("Could not find a Snakefile")

    stats_template = Path(
        resources.files(__package__), "workflow", "report", "stats.json"
    )
    if stats_template.is_file():
        logger.debug(f"Using stats_template {stats_template}")
    else:
        raise FileNotFoundError("Could not find a stats_template")

    # get arguments
    args = parse_arguments()
    logger.debug(f"Entrypoint args:\n    {args}")
    args.stats_template = stats_template

    # control output
    output_settings = OutputSettings(
        quiet={
            Quietness.HOST,
            Quietness.REASON,
            Quietness.PROGRESS,
        },
        printshellcmds=True,
    )

    # set cores.
    resource_settings = ResourceSettings(
        cores=args.threads,
        resources={"mem_mb": int(args.mem_gb * 1024)},
        overwrite_resource_scopes={
            "mem": "global",
            "threads": "global",
        },
    )

    # control rerun triggers
    dag_settings = DAGSettings(rerun_triggers={RerunTrigger.INPUT})

    # other settings
    config_settings = ConfigSettings(config=args.__dict__)
    execution_settings = ExecutionSettings(lock=False)
    storage_settings = StorageSettings(
        # notemp=True
    )

    with SnakemakeApi(output_settings) as snakemake_api:
        workflow_api = snakemake_api.workflow(
            snakefile=snakefile,
            resource_settings=resource_settings,
            config_settings=config_settings,
            storage_settings=storage_settings,
        )
        dag = workflow_api.dag(dag_settings=dag_settings)

        dag.execute_workflow(
            executor="dryrun" if args.dry_run else "local",
            execution_settings=execution_settings,
        )


if __name__ == "__main__":
    main()
