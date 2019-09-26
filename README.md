#### Demo of running centrifuge and kraken2 using snakemake

This requires Snakemake, so following the installation instructions for [bioconda](https://bioconda.github.io/user/install.html)
and [snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

The `snakemake` command is in the [run_snakemake.sh] script. That runs with up to 4 jobs in parallel, change
the `--jobs` parameter to change that.

It processes samples by listing the contigs of `config['patric_dir']` (defined in [config.yaml]) using the function
`reports()`.

On the SANBI cluster this repository can be found in `/usr/people/pvh/southafrica_patric/snakemake_it`.

TODO: add benchamrking as per [Snakmake benchmarking](https://snakemake.readthedocs.io/en/stable/tutorial/additional_features.html).