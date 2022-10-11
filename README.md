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
<br/>
<br/>

First use the TargetQC snakemake pipeline to peform GWAS quality control steps on raw target genome data. The TargetQC snakefile requires HetSampleFilter.R script to run sucessfully, and will output the clean target data. 

Next, input the clean heritable mbGWAS base data summary statistics (provided separately) and clean target genome data to the PRS snakemake pipeline. The PRS snakefile requires the range_list text file and FixMisMatchSNP.R script to run successfully. The range_list file states the p-value threshold used to filter which SNPs are used to calculate the microbial PRS. Currently, the p-value threshold is arbritarily set to discovery threshold of 0.1, however future pipeline iterations that use PRSice2 or other methods to select the optimal p-value threhsold may change this. The PRS snakefile will output sample polygenic risk scores in a file containig the microbial taxon name and .PRS0.1.profile suffix. 
<br/>
<br/>

> **Note**
> Before using the PRS pipeline, the user must have clean base data summary statistics. The user should also confirm that the genome build of the base summary statistics are the same between the base and target data. This can be done by searching a few SNP rsIDs in the base and target data in the [NIH database](https://www.ncbi.nlm.nih.gov/snp/) and comparing the chromosomal location of the base/target data SNPs with the NIH database GRCh38 and GRCh37 build chromosomal locations. 

<br/>

> **Warning**
> Failure to run TargetQC pipeline may cause PRS pipeline mismatch repair R scripts to fail. 

<br/>

## Dependencies
Snakemake<br/>
PLINK<br/>
R<br/>
<br/>

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
<br/>

## TargetQC Pipeline Instructions
### Preparation 
1. Create a new directory and add raw target data to the directory (e.g UKBiobank bed/bim/fam files)
2. Move the TargetQC Snakefile and HetSampleFilter.R to the new directory


### Edit Snakefile Rules
**For all rules: **
1.Replace **GRCh37-canbind-noqc** with the prefix of the input target database. It is suggested to retain the -noqc suffix to indicate these are the raw files. 
2. Replace **GRCh37-canbind-qc** with the prefix of the input target database. It is suggested to retain the -qc suffix to indicate that these are files used in the qc pipeline. 

Specific Snakefile rules require additional edits. 

#### Rule: HeterozygosityFilter 
- Change **/home/fosterlab/SA/GWAS/canbind/CBN_GWAS_files/GRCh37-run2** to the new directory containing the raw target data. This will need to be replaced for both the -f and -r flags.

#### Rule: FinalizeQC
- Change **canbind-qc** after the --out flag to the name of the target database. It is suggested this new name provides some indication that this is the final QCed target database.

<br/>

## PRS Pipeline Instructions
### Preparation 
1. Create a directory named plink-prs
2. Add the PRS pipeline Snakefile and FixMisMatchSNP.R to plink-prs 
3. Create a plink-prs subdirectory named PipelineFiles
4. Add range_list to PipelineFiles
5. Create a PipelineFiles subdirectory named bed
6. Create a PipelineFiles subdirectory named prs
7. Create a PipelineFiles subdirectory named MismatchFixed
8. Create a MismatchFixed subdirectory named ROutput


### Edit Snakefile Rules 
**For all rules:**
1. Replace **/home/fosterlab/SA/GWAS/Kurilshikov/summarystats_clean/heritable** with the directory path for the cleaned base data summary statistics
2. Replace **/home/fosterlab/SA/GWAS/canbind/CBN_GWAS_files/GRCh37/final-qc/canbind-qc** with the directory of the target database. Additionally, replace canbind-qc wih the new prefix created in the Rule: FinalizeQC step of the TargetQC pipeline. 
3. Replace **/home/fosterlab/SA/GWAS/prs/plink-prs/PipelineFiles/bed/canbind-qc** with the directory path for the plink-prs/PipelineFiles/bed directory. Additionally, replace canbind-qc wih the new prefix created in the Rule: FinalizeQC step of the TargetQC pipeline. 
4. Replace **/home/fosterlab/SA/GWAS/prs/plink-prs** with the directory path for the plink-prs directory. 

> **Note**
> If edits are executed in the given order, Find and Replace and be used. 


## Running Snakefiles

### TargetQC Pipeline
```
mamba activate prsenv #actiavte your environment containing Snakemake
cd ~/SA/GWAS/canbind/CBN_GWAS_files/GRCh37-run2 #change to directory containing Snakefile
snakemake --cores 1 canbind-qc.bed #run Snakefile
```
#### User Edits
- replace ~/SA/GWAS/canbind/CBN_GWAS_files/GRCh37-run2 with the directory path for TargetQC Snakefile and raw target genome data
- replace canbind-qc of canbind-qc.bed with the new QC'ed target database prefix created in the TargetQC pipeline Rule: FinalizeQC


### PRS Pipeline
The PRS pipeline snakefile can be run in parallel for all 25 heritable taxa.
```
mamba activate prsenv #actiavte your environment containing Snakemake
cd /home/fosterlab/SA/GWAS/prs/plink-prs-run2 #change to directory containing Snakefile
cat ~/SA/GWAS/Kurilshikov/heritability_files/heritable.taxa.names | parallel -j 10 snakemake --cores 1 /home/fosterlab/SA/GWAS/prs/plink-prs-run2/PipelineFiles/prs/canbind-qc-{}.PRS0.1.profile #Run Snakefile parallel inputing 25 heritable taxa names as wildcard. Output PRS files.
```
#### User Edits
- /home/fosterlab/SA/GWAS/prs/plink-prs-run2 should be replaced with the path for the plink-prs directory
- ~/SA/GWAS/Kurilshikov/heritability_files/heritable.taxa.names should be replaced with the path to a file containing the names of all 25 heritable taxa (heritable.taxa.names file provided in PRS_Pipeline)
- canbind-qc of canbind-qc-{}.PRS0.1.profile{} should be replaced with the new QC'ed target database prefix created in the TargetQC pipeline Rule: FinalizeQC

## PRS Sample Matrix
Once polygenic risk scores have been calculated for all 25 taxa, a matrix can be created. An example is given below: 
``` 
cd /home/fosterlab/SA/GWAS/prs/plink-prs-run2/PipelineFiles/prs #change to directory containing PRS files output from PRS pipeline.
find *.profile | xargs -I input awk 'NR!=1 {print "input", $0}' input | sed '1i FILE FID IID PHENO CNT CNT2 SCORE' > canbind-prs-run2.tsv
```
#### User Edits
- /home/fosterlab/SA/GWAS/prs/plink-prs-run2 should be replaced with the path for the plink-prs directory
- canbind-prs-run2.tsv should be replaced with the desired name of the PRS sample matrix.
