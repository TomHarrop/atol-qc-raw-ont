#!/usr/bin/env python3

import sys
import pandas as pd


def main():
    # read from stdin
    df = pd.read_csv(sys.stdin, delimiter="\t", header=None)

    # mung the columns
    df.columns = ["V1", "V2", "V3"]
    df["type"] = df["V1"].str.replace(r"[^a-zA-Z]", "", regex=True)

    # if we get an attribute error, it's probably because the values are
    # already numeric
    try:
        df["reads"] = pd.to_numeric(df["V2"].str.split().str[0])
    except AttributeError:
        df["reads"] = pd.to_numeric(df["V2"])

    try:
        df["bases"] = pd.to_numeric(df["V3"].str.split().str[0])
    except AttributeError:
        df["bases"] = pd.to_numeric(df["V3"])

    # Add the sample name as an extra column
    df["read_file"] = sys.argv[1]

    # write to stdout
    df[["read_file", "type", "reads", "bases"]].to_csv(
        sys.stdout, index=False, header=True
    )


if __name__ == "__main__":
    main()
