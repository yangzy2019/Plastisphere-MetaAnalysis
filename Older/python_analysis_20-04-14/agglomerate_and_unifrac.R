library("ggplot2")
library("phyloseq")
library("ape")
library(microbiome)

#Set the working directory to be the folder containing this script
wd = getwd()
setwd <- (wd)

#Import all of the data (these are large files so this may take a while)
asv_table <- read.csv("feature_table.csv", sep=",", row.names=1)
asv_table = as.matrix(asv_table)
phy_tree <- read_tree("tree.nwk")

#Convert these to phyloseq objects
ASV = otu_table(asv_table, taxa_are_rows = TRUE)

#You can just run the following commands to ensure that all samples and OTUs have the same names in each matrix - you will see that phy_tree also contains other names (these are from the reference database), but don't worry about this - it will sort itself out when you combine the objects
#sample_names(ASV)[1:100]
#sample_names(META)[1:100]

#Now we will add together the OTU data and the tree data and remove those ASVs that are below 1% relative abundance
physeq = phyloseq(ASV,phy_tree)
rel_abun <- transform_sample_counts(physeq, function(x) x/sum(x))
remove_low_abun <- filter_taxa(rel_abun, function(x) max(x) > 0.01, TRUE)

#The following two commands will show you how many taxa there were before and after removing low abundance ASVs. You could choose a lower number for your remove low abundance, but the agglomeration may struggle if this is above ~10,000
#physeq
#remove_low_abun

#You can use the following to plot this before we agglomerate
#plot_tree(remove_low_abun, label.tips="taxa_names")

#Now do the agglomeration - 0.2 will have the least (~2000 from ~6000 for the original data), while 0.05 will keep the most tips (~5000). You can find more information on doing this here: https://www.rdocumentation.org/packages/phyloseq/versions/1.16.2/topics/tip_glom
#0.2 is the default value, but for the analyses shown in the paper we have compromised on 0.1
agglom <- tip_glom(remove_low_abun, h=0.1)

#Check how many tips/unique taxa we now have
agglom

#plot the trees (with abundance) to see what this looks like now (although we really have too many samples for this to be a particularly useful thing to look at)
#plot_tree(agglom_05, label.tips="taxa_names", size="abundance", title="After tip_glom")

#Now we can calculate unifrac distances between samples (I have not normalized here as we already have normalized samples with values account for the removed ASVs that are below a maximum of 1% relative abundance)
w_uf <- UniFrac(agglom, weighted=TRUE, normalized=FALSE, fast=TRUE)
uw_uf <- UniFrac(agglom, weighted=FALSE, normalized=FALSE, fast=TRUE)

#And finally we can write the data to file so that we can continue our analysis in Python
tree = phy_tree(agglom)
write_phyloseq(agglom, type="all")
ape::write.tree(tree, "reduced_tree.tree")
w_uf_df <- as.data.frame(as.matrix(w_uf))
uw_uf_df <- as.data.frame(as.matrix(uw_uf))
write.csv(w_uf_df, "weighted_unifrac.csv")
write.csv(uw_uf_df, "unweighted_unifrac.csv")
