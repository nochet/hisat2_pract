# Evaluation of human X rna-seq data analyzed with new Tuxedo Suite
# Ref:adapted from Pertea et al, (2016)

# Run differential expression analysis protocol in Ballgown
library(ballgown)
# library(RSkittleBrewer)
library(genefilter)
library(dplyr)
library(devtools)

# Load phenotype data for samples
pheno_data = read.csv("chrX_data/geuvadis_phenodata.csv")

# Read in the expression data that we calculated by StringTie
bg_chrX = ballgown(dataDir = "ballgown", samplePattern = "ERR", pData=pheno_data)


# Filter to remove low-abundance genes - apply a variance filter (remove all transcripts with a variance across samples less than one)
bg_chrX_filt = subset(bg_chrX, "rowVars(texpr(bg_chrX)) >1", genomesubset=TRUE)

# Identify transcripts that show statistically significant differences between groups 
results_transcripts = stattest(bg_chrX_filt,
feature="transcript", covariate="sex", adjustvars = c("population"), getFC=TRUE, meas="FPKM")

# Identify genes statistically significant differences between groups
results_genes = stattest(bg_chrX_filt, feature="gene", covariate="sex", 
adjustvars = c("population"), getFC=TRUE, meas="FPKM")


# Add gene names and gene IDs to the results_transcripts data frame
results_transcripts = 
data.frame(geneNames=ballgown::geneNames(bg_chrX_filt),
geneIDs=ballgown::geneIDs(bg_chrX_filt), results_transcripts)

# Sort the results from the smallest P value to the largest
results_transcripts = arrange(results_transcripts,pval)
results_genes = arrange(results_genes,pval)

# Write results to a csv file that can be shared
write.csv(results_transcripts, "chrX_transcript_results.csv", row.names=FALSE)
write.csv(results_genes, "chrX_gene_results.csv", row.names=FALSE)


# Identify transcripts and genes with a q value < 0.05
subset(results_transcripts, results_transcripts$qval<0.05)
subset(results_genes, results_genes$qval<0.05)


# Data visualization
# Make the plots pretty
tropical = c('darkorange', 'dodgerblue', 'hotpink', 'limegreen', 'yellow')
palette(tropical)

# Show the distribution of gene abundances (measured as FPKM values) across samples, colored by sex 
fpkm = texpr(bg_chrX, meas="FPKM")
fpkm = log2(fpkm+1)
boxplot(fpkm, col=as.numeric(pheno_data$sex), las=2, ylab='log2(FPKM+1)')

# Make plots of individual transcripts across samples
ballgown::transcriptNames(bg_chrX) [12]
ballgown::geneNames(bg_chrX)[12]

plot(fpkm[12,] ~ pheno_data$sex, border=c(1,2), main=paste(ballgown::geneNames(bg_chrX)[12],':',
ballgown::transcriptNames(bg_chrX)[12]), pch=19, xlab="sex", ylab='log2(FPKM+1)')
points(fpkm[12,] ~ jitter(as.numeric(pheno_data$sex)), col=as.numeric(pheno_data$sex))

# Plot the structure and expression levels in a sample of all transcripts that share the same gene locus
plotTranscripts(ballgown::geneIDs(bg_chrX)[1729], bg_chrX, main=c('Gene XIST in sample ERR188234'), sample=c('ERR188234'))

# plot average expression levels for all transcripts of a gene within different groups using the plotMeans function
plotMeans('MSTRG.531', bg_chrX_filt, groupvar="sex", legend=FALSE)

