

** Stata 18
*  Supplementary descriptive statistics 



** Number of employers by skill group and income percentile
global deflator = "lp_d"
use ${path}\Dta\MWsample.dta, clear


* Deflate monetary variables 
merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator})
assert _m == 3
foreach x in income nmw  {
replace `x' = (`x'/${deflator})
replace `x' = round(`x',1)
recast float `x', force
format `x' %9.0g
}

gen isco_skill = 1 if isco2d>83
replace isco_skill = 2 if inrange(isco2d, 41, 83)
replace isco_skill = 3 if inrange(isco2d, 11, 35)

bys idw month year: gen noemployers = _N

keep if year==2010 | year==2019
bys year month: quantiles income, n(100) gen(inc_q)


gen inc_mult = ln(income) - ln(nmw) + 1
replace inc_mult = round(inc_mult, 0.01)
gen mw_now = inc_mult==1

collapse (mean) noemployers mw_now, by(inc_q year isco_skill)
gen upper=2.5

qui sum inc_q if mw_now!=0 & year==2010
tw  (connect noemployers inc_q if isco_skill==3, mcolor(%34)) (connect noemployers inc_q if isco_skill==2, mcolor(%34)) (connect noemployers inc_q if isco_skill==1, mcolor(%34))  (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2010 , legen(order(1 "High-skill" 2 "Middle-skill" 3 "Low-skill" )  pos(2) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Number of employers per month") aspect(0.7) xlabel(0(10)100) ylabel(1(0.5)2.5)

qui graph export ${path}\Figures\skill_jobs_2010.pdf, as(pdf) replace


qui sum inc_q if mw_now!=0 & year==2019
tw  (connect noemployers inc_q if isco_skill==3, mcolor(%34)) (connect noemployers inc_q if isco_skill==2, mcolor(%34)) (connect noemployers inc_q if isco_skill==1, mcolor(%34))  (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2019 , legen(order(1 "High-skill" 2 "Middle-skill" 3 "Low-skill" )  pos(2) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Number of employers per month") aspect(0.7) xlabel(0(10)100)  ylabel(1(0.5)2.5)
qui graph export ${path}\Figures\skill_jobs_2019.pdf, as(pdf) replace


** Drop in women at p30 related to overrepresentation of a male-dominated sector in that part of the distribution: wholesale, transport, storage
use ${path}\Dta\MWsample.dta, clear

* Deflate monetary variables 
merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator})
assert _m == 3
foreach x in income nmw  {
replace `x' = (`x'/${deflator})
replace `x' = round(`x',1)
recast float `x', force
format `x' %9.0g
}

merge m:1 nace_2 using ${path}\Data\nace.dta, keep(1 3) keepusing(nace_big) nogen 
egen nace_gr = group(nace_big)

gen wholesale = nace_gr==10 

gen highskill = isco2d<40
keep if year==2010 | year==2019
bys year month: quantiles income, n(100) gen(inc_q)


gen inc_mult = ln(income) - ln(nmw) + 1
replace inc_mult = round(inc_mult, 0.01)
gen mw_now = inc_mult==1

collapse (mean) female wholesale mw_now, by(inc_q year)

gen upper=1


qui sum inc_q if mw_now!=0 & year==2010
tw  (connect female inc_q, mcolor(%34)) (connect wholesale  inc_q, mcolor(%34)) (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2010 , legen(order(1 "Women" 2  "Wholesale, transport, and storage")  pos(2) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100) ylabel(0(0.2)1) 
qui graph export ${path}\Figures\wholesale_gender2010.pdf, as(pdf) replace


qui sum inc_q if mw_now!=0 & year==2019
tw  (connect female inc_q, mcolor(%34)) (connect wholesale  inc_q, mcolor(%34)) (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2019 , legen(order(1 "Women" 2  "Wholesale, transport, and storage")  pos(2) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100) ylabel(0(0.2)1) 
qui graph export ${path}\Figures\wholesale_gender2019.pdf, as(pdf) replace




** Earnings distribution by skill and public sector 
global deflator = "lp_d"
use ${path}\Dta\MWsample.dta, clear

* Deflate monetary variables 
merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator})
assert _m == 3
foreach x in income nmw  {
replace `x' = (`x'/${deflator})
replace `x' = round(`x',1)
recast float `x', force
format `x' %9.0g
}

gen isco_skill = 1 if isco2d>83
replace isco_skill = 2 if inrange(isco2d, 41, 83)
replace isco_skill = 3 if inrange(isco2d, 11, 35)


keep if year==2010 | year==2019
replace income = round(ln(income), .01)
replace nmw = round(ln(nmw), .01)

qui sum nmw if year == 2010 & month<=3
global  mw2010 = "`r(mean)'"

qui sum nmw if year == 2019 & month>=10
global mw2019 = "`r(mean)'"

twoway (kdensity income if year==2010 &  isco_skill !=3 & publicsector==0, gauss bwidth(${step}) ) (kdensity income if year==2010 &  isco_skill ==3 & publicsector==0, gauss bwidth(${step}) ), legend(order(1 "Low-skill" 2  "High-skill")  pos(2) col(1) ring(0)) xtitle("Real monthly earnings, in logs")  ytitle("Density") aspect(0.7)  xline($mw2010, lcolor(black%50) lpattern(dash))
qui graph export ${path}\Figures\skill_private_2010.pdf, as(pdf) replace

twoway (kdensity income if year==2010 &  isco_skill !=3 & publicsector==1, gauss bwidth(${step}) ) (kdensity income if year==2010 &  isco_skill ==3 & publicsector==1, gauss bwidth(${step}) ), legend(order(1 "Low-skill" 2  "High-skill")  pos(2) col(1) ring(0)) xtitle("Real monthly earnings, in logs")  ytitle("Density") aspect(0.7)  xline($mw2010, lcolor(black%50) lpattern(dash))
qui graph export ${path}\Figures\skill_public_2010.pdf, as(pdf) replace

twoway (kdensity income if year==2019 &  isco_skill !=3 & publicsector==0, gauss bwidth(${step}) ) (kdensity income if year==2019 &  isco_skill ==3 & publicsector==0, gauss bwidth(${step}) ), legend(order(1 "Low-skill" 2  "High-skill")  pos(2) col(1) ring(0)) xtitle("Real monthly earnings, in logs")  ytitle("Density") aspect(0.7)  xline($mw2019, lcolor(black%50) lpattern(dash))

twoway (kdensity income if year==2019 &  isco_skill !=3 & publicsector==1, gauss bwidth(${step}) ) (kdensity income if year==2019 &  isco_skill ==3 & publicsector==1, gauss bwidth(${step}) ), legend(order(1 "Low-skill" 2  "High-skill")  pos(2) col(1) ring(0)) xtitle("Real monthly earnings, in logs")  ytitle("Density") aspect(0.7)  xline($mw2019, lcolor(black%50) lpattern(dash))
qui graph export ${path}\Figures\skill_public_2019.pdf, as(pdf) replace