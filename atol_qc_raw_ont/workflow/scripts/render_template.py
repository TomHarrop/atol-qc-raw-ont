#!/usr/bin/env python3


import json
import jsonschema
from time import sleep


def main():

    # The sleep is necessary to bypass a clock skew problem on HPC filesystems.
    # See
    # https://github.com/snakemake/snakemake/issues/3261#issuecomment-2663727316
    # and
    # https://github.com/snakemake/snakemake/issues/3254#issuecomment-2598641487.
    sleep(5)

    params = snakemake.params
    stats = params["stats"]

    if "n50_length" not in stats:
        stats["n50_length"] = None

    with open(snakemake.input["schema"], "r") as f:
        schema = json.load(f)

    jsonschema.validate(instance=stats, schema=schema)

    with open(snakemake.output[0], "w") as outfile:
        json.dump(stats, outfile)
        outfile.write("\n")


if __name__ == "__main__":
    main()
