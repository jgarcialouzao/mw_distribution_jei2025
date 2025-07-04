
clear all
capture log close
capture program drop _all

** Stata 18
*  Fortin et al (2021) approach -- estimation


log using "D:\MW_distribution\Results\logresults.log", replace

*ngdp_d lp_d cpi
*forvalues y = 1(1)1 {
foreach deflator of global deflateby  {	
global deflator = "`deflator'"
use ${path}\Dta\MWsample.dta, clear

*drop if inrange(isco2d, 11, 35) & income<1.05*nmw // prediction is too off, probably because these individuals are supposed to be top-tail and are not
/*
qui gen period = .
qui replace period = 1 
*if monthly<mofd(mdy(1,1,2015))
*qui replace period = 2 if monthly>=mofd(mdy(1,1,2015)) 
*/

** Selected period
qui keep if monthly<${period}

* Deflate monetary variables 
merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator})
assert _m == 3
foreach x in income nmw  {
qui replace `x' = (`x'/${deflator})
qui replace `x' = round(`x',1)
recast float `x', force
format `x' %9.0g
}

* Create limits of the distribution based on all periods, consistency across years as Fortin et al. 
qui replace income = round(ln(income), 0.01)

qui sum income, d
local min = `r(p1)'
local max =  `r(p99)'
local diff = `max' - `min'
local bins = int(`diff'/${step})
disp in red "`bins'"

qui set seed 13
qui sample2 ${samplesize}, by(monthly)

** Create grouped variables 

* Skill category based on ISCO-08
qui gen isco_skill = 0 if isco2d>=41
qui replace isco_skill = 1 if inrange(isco2d, 11, 35)
drop isco2d

* Broad industries based on NACE2
qui merge m:1 nace_2 using ${path}\Data\nace.dta, keep(1 3) keepusing(nace_big) nogen 
qui  egen nace_gr = group(nace_big)
qui drop nace_big 

* Lithuanian regions from municipalities
qui merge m:1 fid_municipality using ${path}\Data\municipality_ids.dta, keep(1 3) keepusing(nuts3) nogen 

* Age groups
qui gen agecat = 1 if inrange(age,18,29)
qui replace agecat = 0 if inrange(age,30,.)
drop age 

* Firm size groups
qui replace fsize = 0 if fsize==.
qui gen sizecat = 0 if fsize==0
qui replace sizecat = 1 if inrange(fsize,1,9)
qui replace sizecat = 2 if inrange(fsize,10,49)
qui replace sizecat = 3 if inrange(fsize,50,.)
drop fsize

qui compress

* Create earnings and MW categories -- they need to be period specific

qui gen inccat=0
qui replace inccat=1 if income<=`min'

local i=1
while `i'<=`bins'{
	qui replace inccat=1+`i' if income>`min'+(`i'-1)*${step} & income<=`min'+`i'*${step}
	local i=`i'+1
}

qui replace inccat=`bins'+2 if income>`min'+(`bins')*${step}


* Create minimum wage categories -- where MW belongs in the distribution
qui gen nmw_2 = round(ln(nmw/2), 0.01)
qui replace nmw = round(ln(nmw), 0.01)

qui gen mincat=0
qui replace mincat=1 if nmw <=`min'

local i=1
while `i'<=30 {
	qui replace mincat=1+`i' if nmw>`min'+(`i'-1)*${step} & nmw <=`min'+`i'*${step}
	local i=`i'+1
}

qui gen mincat_half=0
qui replace mincat_half=1 if nmw_2 <=`min'

local i=1
while `i'<=30 {
	qui replace mincat_half=1+`i' if nmw_2>`min'+(`i'-1)*${step} & nmw_2 <= `min'+`i'*${step}
	local i=`i'+1
}


keep inccat mincat* year month monthly idw idjob female income nmw sizecat agecat isco_skill nace_gr publicsector nuts3 lithuanian ${deflator}

gen bins = `bins'
gen min = `min'

save "${path}\Dta\sample_${deflator}.dta", replace

drop bins min

qui gen pid=_n 

qui compress 

qui fillin pid inccat


foreach v in mincat mincat_half year month monthly idw idjob female income nmw sizecat agecat isco_skill nace_gr publicsector nuts3 lithuanian ${deflator}  {
	qui bys pid: gegen `v'1 = mean(`v')
	qui replace `v' = `v'1 if `v'==. 
	drop `v'1

}
qui compress 

** Assign ones to all observation up to the bin where the obs currently belongs
qui gen wagein=1-_fillin 
* =1 if at or below wage bin
qui by pid (inccat): gen cumwage=sum(wagein)
*- 1 if above the bin
qui replace cumwage=1-cumwage
* =1 if at or above the bin
qui replace cumwage=cumwage+1 if wagein==1


* Distance between income category and where the minimum wage is
qui gen diff= inccat - mincat
qui gen diff_2 = inccat - mincat_half
drop pid _fillin wagein 

* Minimum wage effects and spillovers 

* At MW
qui gen min=diff<=0

* Bunching at half of the MW 
qui gen min_half = diff_2<=0

** Below MW dummies 
local Nb = 1
forvalues nb=1(1)`Nb' {
qui gen minb`nb' = diff<=-(`nb')	
}

qui compress
** Spillover effects above MW -- decide N
local Na = $spillovers
forvalues na=1(1)`Na' {
qui gen mina`na' = diff<=`na'	
}
qui compress

* Additional variables
qui gen rural = nuts3!=11 & nuts3!=22 & nuts3!=23
qui gen linccat= inccat - 1
qui gen deccat = . 
forvalues n=1(1)10 {
qui	replace deccat = `n' if inccat>(`n'-1)*10 & inccat<=`n'*10	
}
qui gen time_trend = monthly - mofd(mdy(1,1,2010))
qui gen services = nace_gr==2 | nace_gr==4 | nace_gr==6 | nace_gr==7 | nace_gr==8 | nace_gr==9 | nace_gr==10
*qui keep if inccat>1 & inccat<`bins'+2

qui compress 


** Probit regression 

keep idjob cumwage min minb* mina* min_half* age* female isco_skill nuts3 rural nace_gr services inccat linccat publicsector year month sizecat time_trend deccat ${deflator}

global timevar "i.month i.year i.year#c.linccat"
global wvar    "female i.agecat i.isco_skill  i.female#c.linccat i.agecat#c.linccat"
global fvar    "i.nace_gr i.nuts3 i.sizecat publicsector i.services#c.linccat i.rural#c.linccat i.publicsector#c.linccat"

compress 

if "${deflator}" == "ngdp_d" {
disp in red "${deflator}"
timer clear 1
timer on 1
eststo: probit cumwage min min_half minb* mina1-mina${spillovers} i.inccat $timevar $wvar $fvar if inccat>1 ,   difficult vce(cluster idjob) ltol(1e-7) tol(0) 
estimates save ${path}\Results\reg_${deflator}, replace
timer off 1
timer list 1		
outreg2 using "D:\MW_distribution\Results\reg_cumwage.tex", replace keep(min*)	tex(frag) nocons dec(4) ctitle("${deflator}")  nonotes 


}

if "${deflator}" == "lp_d" {
disp in red "${deflator}"
timer clear 1
timer on 1
eststo: probit cumwage min min_half minb*  mina1-mina${spillovers} i.inccat $timevar $wvar $fvar if inccat>1 ,   difficult vce(cluster idjob) ltol(1e-7) tol(0) 
estimates save ${path}\Results\reg_${deflator}, replace
timer off 1
timer list 1		
outreg2 using "D:\MW_distribution\Results\reg_cumwage.tex", append keep(min*)	tex(frag) nocons dec(4) ctitle("${deflator}")  nonotes 

}

if "${deflator}" == "cpi" {
disp in red "${deflator}"
timer clear 1
timer on 1
eststo: probit cumwage min min_half minb*  mina1-mina${spillovers} i.inccat $timevar $wvar $fvar if inccat>1 ,   difficult vce(cluster idjob) ltol(1e-7) tol(0) 
estimates save ${path}\Results\reg_${deflator}, replace
timer off 1
timer list 1		
outreg2 using "D:\MW_distribution\Results\reg_cumwage.tex", append keep(min*)	tex(frag) nocons dec(4) ctitle("${deflator}")  nonotes 


}

if "${deflator}" == "nominal" {
disp in red "${deflator}"
timer clear 1
timer on 1
eststo: probit cumwage min min_half minb*  mina1-mina${spillovers} i.inccat $timevar $wvar $fvar if inccat>1 ,   difficult vce(cluster idjob) ltol(1e-7) tol(0) 
estimates save ${path}\Results\reg_${deflator}, replace
timer off 1
timer list 1		
outreg2 using "D:\MW_distribution\Results\reg_cumwage.tex", append keep(min*)	tex(frag) nocons dec(4) ctitle("${deflator}")  nonotes 


}

}

log close
