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

## Required Data and Files

### Data
- [ ] Raw target genome data in PLINK bim/bed/fam format
- [ ] Cleaned base data summary statistics stored as compressed text files (.txt.gz)_(i.e. quality-controlled heritable taxa summary statistics from Kurilshikov mbGWAS)__

### TargetQC Pipline Files
- [ ] TargetQC Pipeline Snakefile
- [ ] HetSampleFilter R script

### PRS Pipline Files
- [ ] PRS Pipeline Snakefile
- [ ] FixMisMatchSNP R script
- [ ] range_list text file





