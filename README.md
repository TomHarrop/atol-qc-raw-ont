# atol-qc-raw-ont

Run short read QC on Nanopore (ONT) reads.

1. Trim adaptors (`porechop`)
2. Filter reads (`filtlong`)
3. Output stats

## Installation: Use the [BioContainer](https://quay.io/repository/biocontainers/atol-qc-raw-ont?tab=tags)

*e.g.* with Apptainer/Singularity:

```bash
apptainer exec \
  docker://quay.io/biocontainers/atol-qc-raw-ont:0.1.0 \
  atol-qc-raw-ont  
  
```

## Usage

> [!TIP]
> 
> **Set your locale e.g. using `--env LC_ALL=C` or `APPTAINERENV_LC_ALL=C`**.
> 
> Otherwise filtlong [segfaults](https://github.com/rrwick/Filtlong/issues/48)
> with an error like `locale::facet::_S_create_c_locale name not valid`.
> 

TODO

```bash
atol-qc-raw-ont \
```

### Full usage

TODO

```
```
