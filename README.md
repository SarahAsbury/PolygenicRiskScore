# PolygenicRiskScore
Snakemake pipelines for GWAS target data quality control and polygenic risk score calculation of the CAN-BIND GWAS dataset is provided in this repository. 

The uploaded Snakefiles do not have access to any restricted access datasets and will not run in their current form. Input and output file path should be updated for application to other datasets.

Snakemake is a workflow management system designed for bioinformatics analyses. Installation documentation is available at the following [link](https://snakemake.readthedocs.io/en/stable/index.html).

## Pipeline Overview
![Pipline overview flowchart](Images/pipeline_overview.png)

**Orange** = Accessory files
**Pink** = Target data
**Blue** = Base data
**Green** = Polygenic Risk Score

> **Note**
> Before using the PRS pipeline, the user must have clean base data summary statistics. The user should also confirm that the genome build of the base summary statistics are the same between the base and target data. This can be done by searching a few SNP rsIDs in the base and target data in the [NIH database](https://www.ncbi.nlm.nih.gov/snp/) and comparing the chromosomal location of the base/target data SNPs with the NIH database GRCh38 and GRCh37 build chromosomal locations. 

First use the TargetQC snakemake pipeline to peform GWAS quality control steps on raw target genome data. The TargetQC snakefile requires HetSampleFilter.R script to run sucessfully, and will output the clean target data. 

Next, input the clean heritable mbGWAS base data summary statistics (provided separately) and clean target genome data to the PRS snakemake pipeline. The PRS snakefile requires the range_list text file and FixMisMatchSNP.R script to run successfully. The range_list file states the p-value threshold used to filter which SNPs are used to calculate the microbial PRS. Currently, the p-value threshold is arbritarily set to discovery threshold of 0.1, however future pipeline iterations that use PRSice2 or other methods to select the optimal p-value threhsold may change this. The PRS snakefile will output sample polygenic risk scores in a file containig the microbial taxon name and .PRS0.1.profile suffix. 

> **Warning**
> Failure to run TargetQC pipeline may cause PRS pipeline mismatch repair R scripts to fail. 

## Dependencies
Snakemake<br/>
PLINK<br/>
R<br/>

## Required Data and Files
### Data
- [ ] Raw target genome data in PLINK bim/bed/fam format
- [ ] Cleaned base data summary statistics stored as compressed text files (.txt.gz) _(i.e. quality-controlled heritable taxa summary statistics from Kurilshikov mbGWAS)__

### TargetQC Pipline Files
- [ ] TargetQC Pipeline Snakefile
- [ ] HetSampleFilter R script

### PRS Pipline Files
- [ ] PRS Pipeline Snakefile
- [ ] FixMisMatchSNP R script
- [ ] range_list text file

## TargetQC Pipeline Instructions
### Preparation 
1. Create a new directory and add raw target data to the directory (e.g UKBiobank bed/bim/fam files)
2. Move the TargetQC Snakefile and HetSampleFilter.R to the new directory


### Edit Snakefile Rules
1. For all rules, **replace GRCh37-canbind-noqc** with the prefix of the input target database. It is suggested to retain the -noqc suffix to indicate these are the raw files. 
2. For all rules, **replace GRCh37-canbind-qc** with the prefix of the input target database. It is suggested to retain the -qc suffix to indicate that these are files used in the qc pipeline. 

Specific rules require additional edits. 

#### HeterozygosityFilter 
- Change **/home/fosterlab/SA/GWAS/canbind/CBN_GWAS_files/GRCh37-run2** to the new directory containing the raw target data. This will need to be replaced for both the -f and -r flags.

#### FinalizeQC
- Change **canbind-qc** after the --out flag to the name of the target database and provide indication that this is the final QCed target database.


## PRS Pipeline Instructions
### Preparation 
1. Create a directory named plink-prs
2. Create a plink-prs subdirectory named PipelineFiles

### Edit Snakefile Rules 
#### FixMisMatch
- Change input base file path to location of Kurilshikov summary statistics 




