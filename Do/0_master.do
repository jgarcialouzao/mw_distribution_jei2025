


*** Stata 18
**  Program sequence to replicate results of The Earnings Distribution in Lithuania
*   Jose Garcia-Louzao & Nerijus Cerniauskas


clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13
set cformat %5.4f
set max_memory .
*set scheme stcolor, permanently
qui grstyle init
qui grstyle set symbol
qui grstyle set lpattern

** Set main directory
global path /*"{Replication_files}"*/ "D:\MW_distribution" // main directory here but recall one needs to have the sub-folders within the diretory, i.e., do_files, dta_files, cohorts_2018, tables, figures
global path "C:\Users\nerce\Dropbox\LT_MMW\Do\JGL_final"
cd ${path}

** Define key pieces of the estimation 
global deflateby = "lp_d ngdp_d cpi nominal" // "ngdp_d" "cpi" "lp_d" 
global period = mofd(mdy(1,1,.)) // select period --to consider all the years just set missing year
global step = 0.07 // size of the of each k-bin to partition the empirical distribution 
global spillovers = 20 // number of minimum wage effects above the actual MW 
global samplesize = 15 // size of the random sample for each period



* programs needed
/*
ssc install sample2, replace
ssc install outreg2, replace
ssc install gtools, replace
ssc install ftools, replace
ssc install reghdfe, replace
ssc install splitvallabels, replace
ssc install heatplot, replace
ssc install binscatter, replace
ssc install grstyle, replace
ssc install palettes, replace
ssc install colrspace, replace
ssc install leedtwoway, replace
ssc install ereplace, replace
*/

do ${path}\2_descN.do

/*
do ${path}\Do\1_monthlypanel.do
do ${path}\Do\2_desc.do
do ${path}\Do\2a_desc.do

do ${path}\Do\3_fortin.do
do ${path}\Do\3a_visualeffects_deflator.do
do ${path}\Do\4a_reweighting_realdist.do
do ${path}\Do\4b_counterfactual_realdist.do
do ${path}\Do\6_inequality_measures.do
do ${path}\Do\5a_reweighting_nominaldist.do
do ${path}\Do\5b_counterfactual_nominaldist.do
*do ${path}\Do\6a_inequality_measures_nominal.do
do ${path}\Do\3b_marginal_effects.do
*/