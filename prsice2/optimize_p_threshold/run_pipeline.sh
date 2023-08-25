#! /bin/bash
nohup cat ../input/heritable.taxa.names | parallel -j 3 snakemake --nolock --cores 5 prs-{}.best #Run prsice Snakefile in parallel inputing 25 heritable taxa names as wildcard.


