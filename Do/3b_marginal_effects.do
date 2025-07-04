

set scheme stcolor, permanently
qui grstyle init
qui grstyle set symbol
qui grstyle set lpattern



*foreach y in 2010 2019 {
global deflator = "lp_d"
use ${path}\Dta\sample_${deflator}.dta, clear 

** Create minimum wage bins based on the median of the period
qui sum mincat,d
gen mincat_median = round(`r(p50)',1)

qui sum mincat_half,d
gen mincat_half_median = round(`r(p50)',1)

qui sum mincat_median 
global mw `r(mean)'
qui sum mincat_half_median 
global mw_half `r(mean)'
qui sum income, d
qui sum inccat if income>=`r(p50)'
global median `r(min)'
qui sum income, d
qui sum inccat if income>=`r(p75)'
global p75 `r(min)'

qui sum bins
local max_bin = (`r(max)'+2)


* Additional variables
qui gen rural = nuts3!=11 & nuts3!=22 & nuts3!=23
qui gen linccat= inccat - 1
qui gen time_trend = monthly - mofd(mdy(1,1,2010))
qui gen services = nace_gr==2 | nace_gr==4 | nace_gr==6 | nace_gr==7 | nace_gr==8 | nace_gr==9 | nace_gr==10

* Expand 
keep inccat mincat* year month monthly idw female income nmw sizecat agecat isco_skill nace_gr publicsector nuts3 rural linccat services 
compress 

disp in red "Expand"
qui gen pid=_n 
qui fillin pid inccat

 
foreach v in mincat mincat_half mincat_median mincat_half_median  year month monthly idw female income nmw sizecat agecat isco_skill nace_gr publicsector nuts3 rural linccat services  {
qui bys pid: egen `v'1 = mean(`v')
qui replace `v' = `v'1 if `v'==. 
drop `v'1
 }
 
** Assign ones to all observation up to the bin where the obs currently belongs
qui gen wagein=1-_fillin 
 * =1 if at or below wage bin
qui by pid (inccat): gen cumwage=sum(wagein)
* - 1 if above the bin
qui replace cumwage=1-cumwage
* =1 if at or above the bin
qui replace cumwage=cumwage+1 if wagein==1


* Distance between income category and where the minimum wage is
qui gen diff=inccat-mincat
qui gen diff_2 = inccat - mincat_half
qui gen cdiff=inccat-mincat_median
qui gen cdiff_2 = inccat - mincat_half_median

drop pid _fillin wagein 
* Minimum wage effects and spillovers

* At MW
qui gen min=diff<=0
qui gen cmin=cdiff<=0
 
** Below MW dummies 
 local Nb = 1
 forvalues nb=1(1)`Nb' {
  qui gen minb`nb' = diff<=-`nb'    
 }
 
** Spillover effects above MW
local Na =${spillovers}
forvalues na=1(1)`Na' {
 qui gen mina`na' = diff<=`na'     
 }
 
** Bunching at half of the MW
qui gen min_half = diff_2<=0
qui gen cmin_half = cdiff_2<=0

est use ${path}\Results\reg_${deflator}
                
 
 disp in red "Predict"
** CF distribution -- predicted from model estimates
predict p_cumwage

** CF distribution with: no minw
replace min=0
replace min_half = 0
local Na = ${spillovers}
 forvalues n=1(1)`Na' {
 replace mina`n' = 0    
} 
local Nb = 1
 forvalues n=1(1)`Nb' {
 replace minb`n' = 0    
}
predict n_cumwage


** CF distribution with: median minw
replace min=cdiff<=0
replace min_half = cdiff_2<=0
 local Nb = 1
 forvalues nb=1(1)`Nb' {
 replace  minb`nb' = cdiff<=-`nb'    
 }
local Na =${spillovers}
forvalues na=1(1)`Na' {
replace  mina`na' = cdiff<=`na'     
 }
predict c_cumwage

label var p_cumwage  "Predicted distr"
label var n_cumwage  "Predicted distr: no MW"
label var c_cumwage  "Predicted distr: median MW"


**  Set predicted to actual for income bins without estimates
replace p_cumwage=cumwage   if inccat==1 
replace n_cumwage=cumwage   if inccat==1 
replace c_cumwage=cumwage   if inccat==1 

** Collapse data
collapse p_cumwage c_cumwage n_cumwage , by(monthly inccat) 

** Compute probabilities by wage bin 
bys monthly (inccat): gen p_prw=p_cumwage-p_cumwage[_n+1]
bys monthly (inccat): gen c_prw=c_cumwage-c_cumwage[_n+1]
bys monthly (inccat): gen n_prw=n_cumwage-n_cumwage[_n+1]

replace p_prw=p_cumwage     if inccat==52 //`max_bin'
replace c_prw=c_cumwage     if inccat==52 //`max_bin'
replace n_prw=n_cumwage     if inccat==52 //`max_bin'

collapse (mean) p_prw c_prw n_prw, by(inccat)

gen mar_eff = 100*(c_prw - n_prw)/n_prw



tw (bar mar_eff inccat, sort bcolor(stblue%50) lcolor(stblue%100) barwidth(0.45)), ytitle("Effect on the probability (%)") yline(0,lcolor(black%50)) xline($mw_half, lcolor(stgreen%50) lpattern(dash)) xline($mw, lcolor(stgreen%50) lpattern(solid)) xtitle("Earnings bins") xlabel(1(3)52) xline($median, lcolor(stred) lpattern(dot)) xline($p75, lcolor(stred) lpattern(dot)) ylabel(-100(50)200)
qui graph export ${path}\Figures\ME_lp_d.pdf, as(pdf) replace

