


** Stata 18
*  Descriptive statistucs

use ${path}\Dta\MWsample.dta, clear

gen bigcity = fid_municipality==13 | fid_municipality==19 | fid_municipality==21  // keep only big cities: as non-rural Vilnius, Kaunas, Klaipeda
label var bigcity "Vilnius; Kaunas; Klaipeda"

gen highskill = isco2d<40
label var highskill "High-skilled occupation"
gen services = nace_2>47
label var services "Service sector"

gen young = age<30
label var young "Age < 30 years"


estpost summarize female young lithuanian highskill publicsector bigcity services  if year==2010
est store desc1

estpost summarize female young lithuanian highskill publicsector bigcity services   if year==2019
est store desc2

esttab desc1 desc2 using "${path}\Results\desc.tex", replace cells("mean(fmt(a3))") label nonum gaps f compress

** Dynamics of monthly earnings and minimum wage over 2010 and 2019
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


gen lnw = ln(income)
qui replace income = round(ln(income), 0.01)
gcollapse (mean) lnw nmw (sd) SD = lnw (p90) p90income = lnw (p50) p50income = lnw (p10) p10income = lnw, by(monthly)

* Dispersion of wages and the minimum wage
tw  (lpoly SD monthly, degree(0) lwidth(medthick)) (connect SD monthly, mcolor(%34) lwidth(vthin) msize(vsmall))  (connect nmw monthly, mcolor(%34) yaxis(2) ) , ytitle("SD of log real monthly earnings") ytitle("Real monthly minimum wage", axis(2)) xlabel(600(12)720, alternate) xtitle("Monthly") legend(order(2 "SD" 3 "NMW") col(3) ring(0) pos(4) size(small) ) aspect(0.7) ylabel(425(75)650, axis(2))
qui graph export ${path}\Figures\inequality_mw.pdf, as(pdf) replace


lpoly SD monthly, gen(SD_smooth) at(monthly)


* Lower and upper-tail inequality
gen p5010 = p50income -  p10income
gen p9050 = p90income - p50income

qui  lpoly p9050 monthly, gen(p9050_smooth) at(monthly)
qui  lpoly p5010 monthly, gen(p5010_smooth) at(monthly)

foreach v in p9050 p9050_smooth p5010 p5010_smooth {
sort monthly 
qui sum `v' if _n==1
replace `v' = `v' / r(mean)
	
}


tw (connect  p9050 monthly, mcolor(%34) lwidth(vthin) msize(vsmall)) (line p5010_smooth  monthly,  lwidth(medthick)) (connect p5010 monthly, mcolor(%34) lwidth(vthin) msize(vsmall)) (line p9050_smooth  monthly,  lwidth(medthick) lcolor(orange)) , legend(order(1 "P90-P50" 3 "P50-P10") col(2) ring(0) pos(7) size(small) )  ytitle("Normalized monthly earnings percentile ratio") xlabel(600(12)720, alternate) xtitle("Monthly")  aspect(0.7) ylabel(0.6(0.1)1.1)
qui graph export ${path}\Figures\inequality_tails.pdf, as(pdf) replace


** Densities of log monthly earnings, 2010 vs 2019
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

keep if year==2010 | year==2019
gen inc_mult = ln(income) - ln(nmw) 
replace inc_mult = round(inc_mult, 0.01)

tw(hist inc_mult if year==2010, lcolor(none) fcolor(orange%34) bins(60)) (hist inc_mult if year==2019, lwidth(medium) fcolor(none)  bins(60)),  legend(order(1 "2010" 2 "2019") col(1) ring(0) pos(2) ) xlabel(-1.5(0.5)6) ylabel(0(0.2)1.2) xline(0,lcolor(red) lpattern(dash) lwidth(medthick)) xtitle("Earnings as log multiples of the MW") aspect(0.7)
qui graph export ${path}\Figures\dist_20102019.pdf, as(pdf) replace

tw (hist inc_mult if year==2010, lcolor(none) fcolor(orange%34) w(0.01)) (hist inc_mult if year==2019, lwidth(medium) fcolor(none) w(0.01) ) if inc_mult>=-0.10 & inc_mult<=0.10,  legend(order(1 "2010" 2 "2019") col(1) ring(0) pos(2) ) xlabel(-.10(0.02).10) ylabel(0(20)80) xline(0,lcolor(red) lpattern(dot) lwidth(medthick)) xtitle("Earnings as log multiples of the MW") aspect(0.7)
qui graph export ${path}\Figures\dist_aroundMW.pdf, as(pdf) replace


** Minimum wage workers
use ${path}\Dta\MWsample.dta, clear
qui grstyle init
qui grstyle set symbol
qui grstyle set lpattern

* Deflate monetary variables 
merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator})
assert _m == 3
foreach x in income nmw  {
replace `x' = (`x'/${deflator})
replace `x' = round(`x',1)
recast float `x', force
format `x' %9.0g
}

gen inc_mult = ln(income) - ln(nmw) + 1
replace inc_mult = round(inc_mult, 0.01)
gen exact = inc_mult==1
gen atbelow = inc_mult<=1
gen around = inrange(inc_mult, 0.9, 1.10)


gcollapse (mean) atbelow exact around , by(monthly)
tw  (connect exact monthly, mcolor(%34)) (connect around monthly, mcolor(%34)) (connect atbelow monthly,  mcolor(%34)) , legend(order(1 "Exactly MW" 3 "At or below MW" 2 "Within 10% of MW" ) col(1) ring(0) pos(1) size(vsmall) symxsize(*.5)) xlabel(600(12)720, alternate) xtitle("Monthly")  aspect(0.7) ytitle("Share of jobs") ylabel(0(0.05)0.3)
qui graph export ${path}\Figures\mw_jobs.pdf, as(pdf) replace


** Bite of minimum wage
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

gen diff = nmw - income
replace diff = 0 if diff<=0
bys year month: egen sumdiff = sum(diff)
bys year month: egen sumincome = sum(income)
gen exposuremw =  sumdiff/sumincome

gcollapse (mean) average = income nmw exposure (p50) median = income, by(monthly)

gen kaitz_median = nmw/median 
gen kaitz_average = nmw/average


tw (connect kaitz_average monthly, mcolor(%34)) (connect kaitz_median monthly, mcolor(%34)) , legend(order(1 "MW to average earnings" 2 "MW to median earnings") col(1) ring(0) pos(4) size(small) symxsize(*.5)) xlabel(600(12)720, alternate) xtitle("Monthly")  aspect(0.7) ytitle("Kaitz index") ylabel(0.3(0.1)0.7)
qui graph export ${path}\Figures\kaitz.pdf, as(pdf) replace


** Share of workers affected by the minimum wage, following Engbom and Moser (2022)
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

gen inc_mult = ln(income) - ln(nmw) + 1
replace inc_mult = round(inc_mult, 0.01)
gen mw_now = inc_mult==1
gen mw_yr = monthly if mw_now==1
bys idw: egen min_mw_yr = min(mw_yr)
bys idw: egen max_mw_year = max(mw_yr)

* ever-minimum-wage earners
gen mw_ever = (min_mw_yr < .)

* past minimum-wage earners
gen byte mw_past = (monthly > min_mw_yr)

* future minimum-wage earners
gen byte mw_future = (monthly  < max_mw_year & max_mw_year< .)

* mark past minimum-wage earners currently not employed at minimum wage
gen byte mw_past_not_current = (mw_past == 1 & mw_now == 0)

* mark future minimum-wage earners not currently or in the past employed at minimum wage
gen byte mw_future_not_current_not_past = (mw_future == 1 & mw_now == 0 & mw_past == 0)
drop mw_past mw_future

gen young = age<30
gen bigcity = fid_municipality==13 | fid_municipality==19 | fid_municipality==21  // keep only big cities: as non-rural Vilnius, Kaunas, Klaipeda
gen highskill = isco2d<40
gen services = nace_2>47

bys monthly: quantiles income, n(100) gen(inc_q)
collapse (mean) mw_ever_share=mw_ever mw_current_share=mw_now mw_past_not_current_share=mw_past_not_current mw_future_not_current_not_past_s=mw_future_not_current_not_past young bigcity highskill service, by(inc_q)
*collapse (mean) mw_ever_share mw_current_share mw_past_not_current_share mw_future_not_current_not_past_s young bigcity highskill service, by(inc_q)

tw (connect mw_ever_share  inc_q, mcolor(%34)) (connect mw_current_share inc_q, mcolor(%34)) (connect mw_past_not_current_share inc_q, mcolor(%34)) (connect mw_future_not_current_not_past_s inc_q, mcolor(%34)), legen(order(1 "Ever" 2 "Present" 3 "Past, not present" 4 "Future, not present or past")  pos(2) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100)
qui graph export ${path}\Figures\mw_jobs_dist.pdf, as(pdf) replace

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

gen inc_mult = ln(income) - ln(nmw) + 1
replace inc_mult = round(inc_mult, 0.01)
gen mw_now = inc_mult<=1
gen mw_yr = monthly if mw_now==1
bys idw: egen min_mw_yr = min(mw_yr)
bys idw: egen max_mw_year = max(mw_yr)

* ever-minimum-wage earners
gen mw_ever = (min_mw_yr < .)

* past minimum-wage earners
gen byte mw_past = (monthly > min_mw_yr)

* future minimum-wage earners
gen byte mw_future = (monthly  < max_mw_year & max_mw_year< .)

* mark past minimum-wage earners currently not employed at minimum wage
gen byte mw_past_not_current = (mw_past == 1 & mw_now == 0)

* mark future minimum-wage earners not currently or in the past employed at minimum wage
gen byte mw_future_not_current_not_past = (mw_future == 1 & mw_now == 0 & mw_past == 0)
drop mw_past mw_future

bys year month: quantiles income, n(100) gen(inc_q)


collapse (mean) mw_ever_share=mw_ever mw_current_share=mw_now mw_past_not_current_share=mw_past_not_current mw_future_not_current_not_past_s=mw_future_not_current_not_past, by(inc_q)
*collapse (mean) mw_ever_share mw_current_share mw_past_not_current_share mw_future_not_current_not_past_s young bigcity highskill service, by(inc_q)
tw (connect mw_ever_share  inc_q, mcolor(%34)) (connect mw_current_share inc_q, mcolor(%34)) (connect mw_past_not_current_share inc_q, mcolor(%34)) (connect mw_future_not_current_not_past_s inc_q, mcolor(%34)), legen(order(1 "Ever" 2 "Present" 3 "Past, not present" 4 "Future, not present or past")  pos(2) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100)

qui graph export ${path}\Figures\lowwage_jobs_dist.pdf, as(pdf) replace


** Worker/firm types along the distribution: distinguish those who ever lowwage from those who only ever MW
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

gen young = age<30
gen bigcity = fid_municipality==13 | fid_municipality==19 | fid_municipality==21  // keep only big cities: as non-rural Vilnius, Kaunas, Klaipeda
gen highskill = isco2d<40
gen services = nace_2>47

keep if year==2010 | year==2019
bys year month: quantiles income, n(100) gen(inc_q)

gen inc_mult = ln(income) - ln(nmw) + 1
replace inc_mult = round(inc_mult, 0.01)
gen mw_now = inc_mult==1

collapse (mean) female lithuanian young bigcity highskill service public state mw_now, by(inc_q year)

gen upper = 0.9

** 2010
qui sum inc_q if mw_now!=0 & year==2010

tw  (connect female inc_q, mcolor(%34)) (connect young  inc_q, mcolor(%34)) (connect highskill inc_q, mcolor(%34))  (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2010 , legen(order(1 "Women" 2  "Young" 3 "High-skill" )  pos(11) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100) ylabel(0(0.2)1) 
qui graph export ${path}\Figures\worker_types_2010.pdf, as(pdf) replace

qui sum inc_q if mw_now!=0 & year==2010
tw (connect bigcity inc_q, mcolor(%34)) (connect service inc_q, mcolor(%34)) (connect public inc_q, mcolor(%34)) (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2010, legen(order(1 "Vilnius; Kaunas: Klaipeda" 2 "Services" 3 "Public sector" )  pos(11) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100) ylabel(0(0.2)1) 
qui graph export ${path}\Figures\firm_types_2010.pdf, as(pdf) replace

** 2019
qui sum inc_q if mw_now!=0 & year==2019

tw (connect female  inc_q, mcolor(%34)) (connect young  inc_q, mcolor(%34)) (connect highskill inc_q, mcolor(%34)) (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2019 , legen(order(1 "Women" 2  "Young" 3 "High-skill" )  pos(11) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100) ylabel(0(0.2)1)
qui graph export ${path}\Figures\worker_types_2019.pdf, as(pdf) replace

qui sum inc_q if mw_now!=0 & year==2019
tw (connect bigcity inc_q, mcolor(%34)) (connect service inc_q, mcolor(%34)) (connect public inc_q, mcolor(%34)) (area upper inc_q if inrange(inc_q, `r(min)', `r(max)'), bcolor(black%10) lwidth(none)) if year==2019, legen(order(1 "Vilnius; Kaunas: Klaipeda" 2 "Services" 3 "Public sector" )  pos(11) col(1) ring(0))  xtitle("Monthly earnings percentiles") ytitle("Share of all jobs") aspect(0.7) xlabel(0(10)100) ylabel(0(0.2)1)
qui graph export ${path}\Figures\firm_types_2019.pdf, as(pdf) replace
