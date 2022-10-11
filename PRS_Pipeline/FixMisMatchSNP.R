#!/usr/bin/env Rscript

# === About === 
#Fix mismatched SNPs
#Rscript adapted for bash parallelization 
#Intended as part of plink-prs bash script

#Warning: Built for CANBIND data and Kurilshikov summary statistics. Will need ot be adapted for more general use.

#Based on tutorial: https://choishingwan.github.io/PRS-Tutorial/target/#ambiguous-snps
#However, unlike tutorial, we are building an output file appropriate for --update-alleles flag in PLINK

# === Depenendencies === 
#tidyverse
#argparse




# === Load libraries === 
library(tidyverse)
library(argparse)


# === Args === 
# create parser object
parser <- ArgumentParser()
parser$add_argument("-t", "--target", default = "none",
	help = "Full file path and prefix of target data PLINK binary files (bim/bed/fam). Must not  be named none.")
parser$add_argument("-b", "--base", default = "none", 
	help = "Full file path and file name of base summary statistics file. Must not be named none.")
parser$add_argument("-o", "--output", default = "nomismatch.bim",
	help = "Full path and file name for output file. Output is the target bim with no mismatching SNPs between base and target.")
parser$add_argument("-l", "--log", default = "FixMismatchSNPs_log.txt",
	help = "Full path and file name for log file.")

#Store args
args <- parser$parse_args()


#Open log
if(file.exists(args$log) == FALSE){
	file.create(args$log)
}

sink(args$log, append = TRUE)
print("=========== NEW RUN ===========")
print(Sys.time())


#Check required args given
if(args$target == "none"){
	sink()
	stop("Target file input required.") 
}

if(args$base == "none"){
	sink()
	stop("Base file input required.")
}

# === Custom Functions === 
# Strand flip/complementary base pair
complement <- function(x) {
    recode(
        x,
        "A" = "T",
        "C" = "G",
        "T" = "A",
        "G" = "C"
    )
}

#Merge base and target
#Then check for strand flips and recodes
check.target.base <- function(target, base) {
	merge(target, base, by = c("SNP", "CHR", "BP")) %>%
        mutate(match = ifelse(T.A1 == B.A1 & T.A2 == B.A2, TRUE, FALSE), #already matching SNPs
                C.T.A1 = complement(T.A1), #complement of target effector
                C.T.A2 = complement(T.A2), #complement of target reference
                comp = ifelse(B.A1 == C.T.A1 & B.A2 == C.T.A2, TRUE, FALSE), #mismatch requires strand flip
                recode = ifelse(B.A1 == T.A2 & B.A2 == T.A1, TRUE, FALSE), #mismatch requires recoding
                comp_recode = ifelse(B.A1 == C.T.A2 & B.A2 == C.T.A1, TRUE, FALSE) #mismatch requires strand flip and recoding
        )
}


#=== Import data === 
#== Target == 
target.name <- paste0(args$target, ".bim")
print(paste0("Loading target data:", target.name))
target.bim <- read.table(target.name)
colnames(target.bim) <- c("CHR", "SNP", "CM", "BP", "T.A1", "T.A2")
target.bim <- target.bim %>% mutate(T.A1 = toupper(T.A1), T.A2 = toupper(T.A2)) #alleles to uppercase


#Inspect
print("Target data successfully loaded")
head(target.bim) %>% print
print(paste(nrow(target.bim), "target SNPs"))

#== Base == 
print(paste0("Loading base data:", args$base))
base <- read.table(gzfile(args$base), header = T, stringsAsFactors = F, sep="\t") %>%
	rename(B.A1 = eff.allele, B.A2 = ref.allele, CHR = chr, BP = bp, SNP = rsID) %>% #generalize here
	mutate(B.A1 = toupper(B.A1), B.A2 = toupper(B.A2)) #alleles to uppercase 

#Inspect
print("Base data successfully loaded")
head(base) %>% print
print(paste(nrow(base), "base SNPs"))


# === Identify base and target SNPs requiring strand flip and/or recode === 
#Merge base and target SNPs by SNP ID and location
#Identify number of:
	#A) Already matching SNPs (info$match)
	#B) 
info <- check.target.base(target = target.bim, base = base)

print(head(info))
print(paste(nrow(info), "shared SNPs (by location and ID)  between base and target data"))
print(paste(info %>% filter(match == TRUE) %>% nrow, "matching SNPs between base and target"))
print(paste(info %>% filter(comp == TRUE) %>% nrow, "SNPs require strand flip"))
print(paste(info %>% filter(recode == TRUE) %>% nrow, "SNPs require recoding"))
print(paste(info %>% filter(comp_recode == TRUE) %>% nrow, "SNPs require strand flip and recode"))



#Unit test: If match is TRUE, all fixes should be FALSE and vise versa
qc <- info %>% mutate(qc = ifelse(match == TRUE & comp == FALSE & recode == FALSE & comp_recode == FALSE | match == FALSE & comp == TRUE | match == FALSE & recode == TRUE | match == FALSE & comp_recode == TRUE | match == FALSE & comp == FALSE & recode == FALSE & comp_recode == FALSE, TRUE, FALSE)) %>% pull(qc)

if(all(qc) == FALSE){
	sink()
	stop("Info match does not align with comp, recode, or comp_recode results")
}


# === Strandflip and recode target data  ===
print("Performing strand flips and recodings")
target.fix <- target.bim %>% filter(SNP %in% info$SNP) %>% 
	left_join(info %>% select(SNP, CHR, BP, T.A1, T.A2, C.T.A1, C.T.A2, match, comp, recode, comp_recode), by = c("CHR", "SNP", "BP"), suffix = c("", ".info")) %>%
	mutate(T.A1 = ifelse(comp == TRUE, C.T.A1, T.A1), T.A2 = ifelse(comp == TRUE, C.T.A2, T.A2)) %>% #strand flip
	mutate(T.A1 = ifelse(recode == TRUE, T.A2.info, T.A1), T.A2 = ifelse(recode == TRUE, T.A1.info, T.A2)) %>% #recode 
	mutate(T.A1 = ifelse(comp_recode == TRUE, C.T.A2, T.A1), T.A2 = ifelse(comp_recode == TRUE, C.T.A1, T.A2)) #strand flip and recode 

print("Target database after mismtach fix (head):")
print(head(target.fix))
print("Example of strand flip fix:")
print(head(target.fix %>% filter(comp == TRUE)))
print("Example of recode fix:")
print(head(target.fix %>% filter(recode == TRUE)))
print("Example of strand flip and recode fix:")
print(head(target.fix %>% filter(comp_recode == TRUE)))



# == Check fixes were successful ==
qc <- check.target.base(target = target.fix, base = base)

# Unit tests #1: No more strand flips/recodes required

print(paste(nrow(qc), "shared SNPs (by location and ID)  between base and target data"))
print(paste(qc %>% filter(match == TRUE) %>% nrow, "matching SNPs between base and target"))
print(paste(qc %>% filter(comp == TRUE) %>% nrow, "SNPs require strand flip"))
print(paste(qc %>% filter(recode == TRUE) %>% nrow, "SNPs require recoding"))
print(paste(qc %>% filter(comp_recode == TRUE) %>% nrow, "SNPs require strand flip and recode"))

if(nrow(qc %>% filter(comp == TRUE)) > 0){
	sink()
	stop(paste(nrow(qc %>% filter(comp == TRUE)), "SNPs still require strand flip"))
}

if(nrow(qc %>% filter(recode == TRUE)) > 0){
	sink()
	stop(paste(nrow(qc %>% filter(recode == TRUE)), "SNPs still require recode"))
}



if(nrow(qc %>% filter(comp_recode == TRUE)) > 0){
	sink()
	stop(paste0(nrow(qc %>% filter(comp_recode == TRUE)), "SNPs still require strand flip and recode"))
}



#Unit test #2: A1 is a different base from A2
qc.u2 <- qc %>% mutate(A1_A2 = ifelse(T.A1 != T.A2, TRUE, FALSE))

if(all(qc.u2 %>% pull(A1_A2)) == FALSE){
	print(qc %>% filter(A1_A2 == FALSE))
	sink()
	stop(paste(nrow(qc %>% filter(A1_A2 == FALSE)), "SNPs have the same base in A1 and A2"))
}


#Unit test #3: A1 and A2 are not complementary
	#This only creates a warning because in some cases users may keep ambigious SNPs
	#comp_SNPs = FALSE if SNPs are actually complementary (i.e. fail QC).

#A) Identify SNPs that are complementary 
qc.u3 <- qc %>% mutate(comp_SNPs = ifelse(T.A1 == "C" & T.A2 == "G" | T.A1 == "G" & T.A2 == "C" | T.A1 == "A" & T.A2 == "T" | T.A1 == "T" & T.A2 == "A", FALSE, TRUE))

#B) Identify whether complementary SNPs were identified as being fixable by strand flip and/or recode
qc.u3.SNPs <- qc.u3 %>% filter(comp_SNPs == FALSE) %>% pull(SNP)
qc.u3b <- target.fix %>% filter(SNP %in% qc.u3.SNPs) %>% mutate(unfixable = ifelse(comp == TRUE | recode == TRUE | comp_recode == TRUE, FALSE, TRUE))

print("Test 5")  

if(all(qc.u3 %>% pull(comp_SNPs)) == FALSE){
	warning(paste(nrow(qc.u3 %>% filter(comp_SNPs == FALSE)), "SNPs are complementary base pairs. These could indicate an error in mismatch processing. Please review logs."))
	print(paste(nrow(qc.u3b %>% filter(unfixable == TRUE)), "complementary SNPs were not identified as fixable, and therefore unedited. They do not represent an error in mismatch processing. They represent ambiguous SNPs that have not been removed from target database."))

	if(all(qc.u3b %>% pull(unfixable)) == FALSE){
		print(qc.u3b %>% filter(unfixable == FALSE))
		warning(paste(nrow(qc.u3b %>% filter(unfixable == FALSE)), "fixable SNPs that have complementary base pairs. If complementary base pairs were removed, this indicates an error is mismatch fixes."))
	}


} 


# === Clean-up target data for output === 
# == Target == 
target.out <- qc %>% filter(match == TRUE) %>% select(CHR, SNP, CM, BP, T.A1, T.A2) %>% arrange(CHR, BP)


# == Mismatched SNPs == 
mismatch.out <- qc %>% filter(match == FALSE) %>% select(CHR, SNP, CM, BP, T.A1, T.A2)


# == All SNPs - Fixed Mismatches - PLINK format == 
#Formatted for --update-alleles 
#Columns:
#1. Variant ID
#2. One of the old allele codes
#3. The other old allele code
#4. New code for the first named allele
#5. New code for the second named allele 
plink.format.out <- qc %>% select(SNP, T.A1.info, T.A2.info, T.A1, T.A2)
print("Plink output format: 1. Variant ID, 2. One of the old allele codes, 3. The other old allele code, 4. New code for the first named allele, 5. New code for the second named allele")
print(head(plink.format.out))



# === Output files ===
print(paste(nrow(target.bim), "SNPs in unedited target data"))
print(paste(nrow(base), "SNPs in unedited base data"))
print(paste(nrow(qc), "shared SNPs (by location and ID)  between base and target data"))
print(paste(target.out %>% nrow, "matching SNPs between base and target after mismatch fixes"))
print(paste(mismatch.out %>% nrow, "mismatched SNPs remaining."))

print(paste0("Output file:", args$out, ".bim")) 
write.table(target.out, paste0(args$out, ".bim"),  quote = F, row.names = F, col.names = F, sep="\t")

print(paste0("Output file:", args$out, "_MISMATCHED_SNPs.bim"))
write.table(mismatch.out, paste0(args$out, "_MISMATCHED_SNPs.bim"), quote = F, row.names = F, col.names = F, sep="\t")

print(paste0("Output file:", args$out, "plink-format.tsv"))
write.table(plink.format.out, paste0(args$out, "_plink-format.tsv"), quote = F, row.names = F, col.names = F, sep="\t")

# === Close log === 
sink()
