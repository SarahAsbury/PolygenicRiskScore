#! /bin/bash
cat ../input/heritable.taxa.names | parallel -j 3 snakemake --cores 5 prs-{}.prsice #Run prsice Snakefile in parallel inputing 25 heritable taxa names as wildcard.


