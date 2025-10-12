#!/usr/bin/env python3


import jinja2
from time import sleep

def main():

    # The sleep is necessary to bypass a clock skew problem on HPC filesystems.
    # See
    # https://github.com/snakemake/snakemake/issues/3261#issuecomment-2663727316
    # and
    # https://github.com/snakemake/snakemake/issues/3254#issuecomment-2598641487.
    sleep(10)

    params = snakemake.params

    with open(snakemake.input["template"], "r") as infile:
        template = jinja2.Template(infile.read())

    with open(snakemake.output[0], "w") as outfile:
        outfile.write(template.render(params))


if __name__ == "__main__":
    main()
