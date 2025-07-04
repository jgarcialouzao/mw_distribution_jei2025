

** Stata 18
*  Fortin et al (2021) approach -- counterfactual distributions
set scheme stcolor, permanently
qui grstyle init
qui grstyle set symbol
qui grstyle set lpattern


foreach deflator of global deflateby  {	
	
global deflator = "`deflator'"
use ${path}\Dta\MWsample.dta, clear

* Deflate monetary variables 
merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator})

assert _m == 3
foreach x in income nmw  {
qui replace `x' = (`x'/${deflator})
qui replace `x' = round(`x',1)
recast float `x', force
format `x' %9.0g
}
qui replace income = round(ln(income), 0.01)
qui replace nmw = round(ln(nmw), 0.01)

qui sum income, d
local min = `r(p1)'
local max =  `r(p99)'
local diff = `max' - `min'
local bins = int(`diff'/${step})
disp in red "`bins'"


qui sum year
loc year_start = r(min)
loc year_end = r(max)
keep if year == `year_start' | year ==`year_end'
gen year_start = `year_start' 
gen year_end = `year_end' 
qui gen inccat=0
qui replace inccat=1 if income<=`min'

local i=1
while `i'<=`bins'{
	qui replace inccat=1+`i' if income>`min'+(`i'-1)*${step} & income<=`min'+`i'*${step}
	local i=`i'+1
}

qui replace inccat=`bins'+2 if income>`min'+(`bins')*${step}

sort monthly inccat
merge m:1 monthly inccat using ${path}\Results\rwgt_${deflator}_real.dta, keep(match) nogen

qui sum income if year == `year_end' & month>=10, d
global median = "`r(p50)'"

qui sum income if year == `year_end' & month>=10, d
global p75= "`r(p75)'"

qui sum nmw if year == `year_start' 
global  mw2010 = "`r(mean)'"

qui sum nmw if year == `year_end' 
global mw2019 = "`r(mean)'"

** Plot distributions
qui sum income, d
keep if income>=0.95*r(p1) & income<=1.05*r(p99)
qui sum income, d
gen xstep=(r(max)-r(min))/200
gen kwage=r(min)+(_n-1)*xstep if _n<=200

* Actual distribution at the start of the period

kdensity income if year==`year_start', at(kwage) gauss bwidth($step) generate(w1 fd1) nograph 
		
* Actual distribution at the end of the period
kdensity income if year==`year_end', at(kwage) gauss bwidth($step) generate(w2 fd2) nograph 

* Counterfactual distribution: income distribution of the end period with the 
* mimimum wage from the start of the period
kdensity income [aweight=rw_mwc] if year==`year_end', at(kwage) gauss bwidth($step) generate(w2mw fd2mw) nograph 

* Counterfactual distribution: income distribution of the end period with 
* no spill over effects
kdensity income [aweight=rw_ns] if year==`year_end', at(kwage) gauss bwidth($step) generate(w2ns fd2ns) nograph 


keep if kwage!=.

* No MW
tw (connect fd1 kwage,  msymbol(i) clwidth(medthick)) (connect fd2 kwage,  msymbol(i) clwidth(medthick) ) (connected fd2mw kwage, msize(vsmall) msymbol(Plus)), legend(order(1 "2010" 2 "2019" 3 "2019, {&Delta}MW=0") col(1) ring(0) pos(2) size(small) ) ytitle("Density")  xtitle("Monthly earnings, in logs") ylabel(0(0.2)1) xline($median, lcolor(black%50) lpattern(solid)) xline($p75, lcolor(black) lpattern(dot)) xline($mw2010, lcolor(stblue)) xline($mw2019, lcolor(stred) lpattern(dash_dot))  aspect(0.7) xlabel(4(1)9)
qui graph export ${path}\Figures\counterfactual_mw_${deflator}_real.pdf, as(pdf) replace

*No spillovers
tw (connect fd1 kwage,  msymbol(i) clwidth(medthick))  (connect fd2 kwage,  msymbol(i) clwidth(medthick)) (connect fd2ns kwage,  msize(vsmall) msymbol(Plus) ), legend(order(1 "2010" 2 "2019" 3 "2019, No spillovers" ) col(1) ring(0) pos(2) size(small) ) ytitle("Density")  xtitle("Monthly earnings, in logs") /*ylabel(0(0.4)2)*/ xline($median, lcolor(black%50) lpattern(solid)) xline($p75, lcolor(black) lpattern(dot)) xline($mw2010, lcolor(stblue)) xline($mw2019, lcolor(stred) lpattern(dash_dot))   aspect(0.7) xlabel(4(1)9)
qui graph export ${path}\Figures\counterfactual_ns_${deflator}_real.pdf, as(pdf) replace
}



