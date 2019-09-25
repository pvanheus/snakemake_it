#### Demo of running centrifuge and kraken2 using snakemake

This requires Snakemake, so following the installation instructions for [bioconda](https://bioconda.github.io/user/install.html)
and [snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

The `snakemake` command is in the [run_snakemake.sh] script. That runs with up to 4 jobs in parallel, change
the `--jobs` parameter to change that.

It processes samples as according to the list `sample_names` in [config.yaml]. Expand that list (e.g. with contents from
[samples.txt]) to process more samples.
