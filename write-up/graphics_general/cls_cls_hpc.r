# script to produce a 3D graphic of the hippocampus in detail

library(rgl);
library(misc3d);
library(neurobase);
library(aal);
library(MNITemplate);

img = aal_image();
template = readMNI(res = "2mm");
cut <- 4500;
dtemp <- dim(template);

labs = aal_get_labels();
hpc = labs$index[grep("Hippocampus_L|Hippocampus_R", labs$name)];
neocortex = labs$index[grep("Temporal_Sup_L|Temporal_Sup_R|Angular_L|Angular_R|Heschl_L|Heschl_R|Frontal_Mid_L|Frontal_Mid_R", labs$name)];
mask_hpc = remake_img(vec = img %in% hpc, img = img);
mask_neocortex = remake_img(vec = img %in% neocortex, img = img);
contour3d(template, x=1:dtemp[1], y=1:dtemp[2], z=1:dtemp[3], level = cut, alpha = 0.2, draw = TRUE)
contour3d(mask_hpc, level = c(0.5), alpha = c(0.5), add = TRUE, color=c("red") )
contour3d(mask_neocortex, level = c(0.5), alpha = c(0.1), add = TRUE, color=c("blue") )

