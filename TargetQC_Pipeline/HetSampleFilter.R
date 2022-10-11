#!/usr/bin/env Rscript

# === About === 
# Filter out samples with heterozygosity above
# To be run in GWAS QC snakemake pipeline (SA)
# Based on: https://choishingwan.github.io/PRS-Tutorial/


# === Load libraries === 
library(tidyverse)
library(argparse)



# === Args === 
#create parser object
parser <- ArgumentParser()
parser$add_argument("-f", "--file", default = "none", help = "Full file path for heterozygosity rate file.")
parser$add_argument("-e", "--export", default = "none", help = "Full directory path for export folder")


#Store args
args <- parser$parse_args()

# === Pre-run Unit tests === 
#Check if required args are given 
if(args$file == "none"){
	stop("Heterozygosity file not provided")
}

if(args$export == "none"){
	stop("Export directory path missing")
}

print("Running heterozygosity filter")

# === Run === 
#Import data
dat <- read.table(paste(args$file), header = T)

#Calculate mean and SD 
m <- mean(dat$F)
s <- sd(dat$F)

#Subset samples
valid <- subset(dat, F <= m+3*s & F >= m-3*s) 
valid.samples <- valid %>% pull(IID)
print(paste(length(valid.samples), "valid samples"))

invalid <- dat %>% filter(!(IID %in% valid.samples))
print(paste(nrow(invalid), "invalid samples"))

# === Export === 
#Invalid 
write.table(invalid %>% select(FID, IID), paste0(args$export, "/het.invalid.samples"), quote = F, row.names = F) 

#Valid
write.table(valid %>% select(FID, IID), paste0(args$export, "/het.valid.samples"), quote = F, row.names = F)

#Success message
print("Heterozygosity filter file export successful")
