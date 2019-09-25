#!/bin/bash

SN_PATH=$(which snakemake)
if [ -z "$SN_PATH"] ; then
  source $HOME/miniconda3/bin/activate
  conda activate snakemake
fi

snakemake --jobs 4 --use-singularity --use-conda --cluster-config cluster.yaml --cluster "sbatch -J {cluster.name} -e {cluster.error} -o {cluster.output} --mem {cluster.memory} -c {cluster.nCPUs}"