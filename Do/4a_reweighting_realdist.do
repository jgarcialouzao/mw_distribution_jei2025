


** Stata 18
*  Fortin et al (2021) approach -- weighting schemes to produce counterfactual distributions 

foreach deflator of global deflateby  {	
global deflator = "`deflator'"
use ${path}\Dta\sample_${deflator}.dta, clear 

qui sum bins
local max_bin = (`r(max)'+2)

** Create minimum wage bins based on the start of the period
keep if year == 2010 | year == 2019
qui sum mincat if year==2010,d
gen mincat_start = round(`r(p50)',1)

qui sum mincat_half if year==2010,d
gen mincat_half_start = round(`r(p50)',1)


* Additional variables
qui gen rural = nuts3!=11 & nuts3!=22 & nuts3!=23
qui gen linccat= inccat - 1
qui gen time_trend = monthly - mofd(mdy(1,1,2010))
qui gen services = nace_gr==2 | nace_gr==4 | nace_gr==6 | nace_gr==7 | nace_gr==8 | nace_gr==9 | nace_gr==10

* Expand 
keep inccat mincat* year month monthly idw female income nmw sizecat agecat isco_skill nace_gr publicsector nuts3 rural linccat services 

disp in red "Expand"
qui gen pid=_n 
qui fillin pid inccat

 
foreach v in mincat mincat_half mincat_start mincat_half_start  year month monthly idw female income nmw sizecat agecat isco_skill nace_gr publicsector nuts3 rural linccat services  {
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
qui gen cdiff=inccat-mincat_start
qui gen cdiff_2 = inccat - mincat_half_start

drop pid _fillin wagein 

* Minimum wage effects and spillovers 

* At MW
qui gen min=diff<=0
qui gen cmin=cdiff<=0
 
** Below MW dummies 
 local Nb = 1
 forvalues nb=1(1)`Nb' {
  qui gen minb`nb' = diff<=-`nb'    
  qui gen cminb`nb' = cdiff<=-`nb'  
 }
 
** Spillover effects above MW
local Na =${spillovers}
forvalues na=1(1)`Na' {
 qui gen mina`na' = diff<=`na'     
 qui gen cmina`na' = cdiff<=`na'   
 }
 
 
** Bunching at half of the MW
qui gen min_half = diff_2<=0
qui gen cmin_half = cdiff_2<=0

qui compress 
sort monthly idw inccat

est use ${path}\Results\reg_${deflator}
                
 
 disp in red "Predict"
** CF distribution -- predicted from model estimates
predict p_cumwage

 
** CF distribution with: no spillovers
local Na = ${spillovers}
  forvalues n=1(1)`Na' {
 replace mina`n' = 0     if diff>0
 }
 predict pn_cumwage
 
** CF distribution with initial MW
* At MW (and half of it)
replace min=cmin
replace min_half = cmin_half 
 
** Below MW dummies 
local Nb = 1
 forvalues n=1(1)`Nb' {
 replace minb`n' = cminb`n'      
 }
 
** Spillover effects above MW
 local Na = ${spillovers}
 forvalues n=1(1)`Na' {
 replace mina`n' = cmina`n'      
  }
 predict c_cumwage
 

label var cumwage    "Actual distr"
label var p_cumwage  "Predicted distr"
label var pn_cumwage "Predicted distr: no spillover"
label var c_cumwage  "Predicted distr: intial MW"

**  Set predicted to actual for income bins without estimates
qui sum inccat
replace p_cumwage=cumwage   if inccat==1 
replace pn_cumwage=cumwage  if inccat==1 
replace c_cumwage=cumwage   if inccat==1 


** Collapse data
collapse cumwage p_cumwage c_cumwage pn_cumwage , by(monthly inccat) 

** Compute probabilities by wage bin 
bys monthly (inccat): gen prw=cumwage-cumwage[_n+1]
bys monthly (inccat): gen p_prw=p_cumwage-p_cumwage[_n+1]
bys monthly (inccat): gen c_prw=c_cumwage-c_cumwage[_n+1]
bys monthly (inccat): gen pn_prw=pn_cumwage-pn_cumwage[_n+1]

replace prw=cumwage         if inccat==`max_bin'
replace p_prw=p_cumwage     if inccat==`max_bin'
replace c_prw=c_cumwage     if inccat==`max_bin'
replace pn_prw=pn_cumwage   if inccat==`max_bin'

** Reweighting factors
gen rw_ns=pn_prw/p_prw 
label var rw_ns "Reweighting factor: no spillover"
gen rw_mwc=c_prw/p_prw 
label var rw_mwc "Reweighting factor: initial MW"

assert rw_mwc>0
sort monthly inccat
keep monthly inccat *cumwage* rw* *prw*

save ${path}\Results\rwgt_${deflator}_real.dta, replace

}


