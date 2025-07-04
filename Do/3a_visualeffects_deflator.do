

** Stata 18
*  Fortin et al (2021) approach -- point estimates of minimum wage effects
set scheme stcolor, permanently
qui grstyle init
qui grstyle set symbol
qui grstyle set lpattern

use ${path}\Dta\sample_ngdp_d.dta, clear
keep if _n == 1
est use ${path}\Results\reg_ngdp_d
keep idw
expand 23
gen mweffects = _n 
drop idw 

gen beta   = . 
gen cilow  = . 
gen cihigh = .


sort mweffects
replace beta = _b[min_half] if _n == 1
replace cilow = _b[min_half]  - 1.96*_se[min_half] if _n == 1
replace cihigh  = _b[min_half]  + 1.96*_se[min_half] if _n == 1

sort mweffects 
replace beta = _b[minb] if _n == 2
replace cilow = _b[minb]  - 1.96*_se[minb] if _n == 2
replace cihigh  = _b[minb]  + 1.96*_se[minb] if _n == 2

sort mweffects 
replace beta = _b[min] if _n == 3
replace cilow = _b[min]  - 1.96*_se[min] if _n == 3
replace cihigh  = _b[min]  + 1.96*_se[min] if _n == 3

local Na = $spillovers
forvalues h = 1(1)`Na' {
sort mweffects
replace beta = _b[mina`h'] if _n == 3 + `h'
replace cilow = _b[mina`h']  - 1.96*_se[mina`h'] if _n == 3 + `h'
replace cihigh  = _b[mina`h']  + 1.96*_se[mina`h'] if _n == 3 + `h'	
}
gen group = 1
tempfile PEgroup1
save `PEgroup1'

use ${path}\Dta\sample_lp_d.dta, clear
keep if _n == 1
est use ${path}\Results\reg_lp_d
keep idw
expand 23
gen mweffects = _n 
drop idw 

gen beta   = . 
gen cilow  = . 
gen cihigh = .


sort mweffects
replace beta = _b[min_half] if _n == 1
replace cilow = _b[min_half]  - 1.96*_se[min_half] if _n == 1
replace cihigh  = _b[min_half]  + 1.96*_se[min_half] if _n == 1

sort mweffects 
replace beta = _b[minb] if _n == 2
replace cilow = _b[minb]  - 1.96*_se[minb] if _n == 2
replace cihigh  = _b[minb]  + 1.96*_se[minb] if _n == 2

sort mweffects 
replace beta = _b[min] if _n == 3
replace cilow = _b[min]  - 1.96*_se[min] if _n == 3
replace cihigh  = _b[min]  + 1.96*_se[min] if _n == 3


local Na = $spillovers
forvalues h = 1(1)`Na' {
sort mweffects
replace beta = _b[mina`h'] if _n == 3 + `h'
replace cilow = _b[mina`h']  - 1.96*_se[mina`h'] if _n == 3 + `h'
replace cihigh  = _b[mina`h']  + 1.96*_se[mina`h'] if _n == 3 + `h'	
}
gen group = 2
tempfile PEgroup2
save `PEgroup2'

use ${path}\Dta\sample_cpi.dta, clear
keep if _n == 1
est use ${path}\Results\reg_cpi
keep idw
expand 23
gen mweffects = _n 
drop idw 

gen beta   = . 
gen cilow  = . 
gen cihigh = .


sort mweffects
replace beta = _b[min_half] if _n == 1
replace cilow = _b[min_half]  - 1.96*_se[min_half] if _n == 1
replace cihigh  = _b[min_half]  + 1.96*_se[min_half] if _n == 1

sort mweffects 
replace beta = _b[minb] if _n == 2
replace cilow = _b[minb]  - 1.96*_se[minb] if _n == 2
replace cihigh  = _b[minb]  + 1.96*_se[minb] if _n == 2

sort mweffects 
replace beta = _b[min] if _n == 3
replace cilow = _b[min]  - 1.96*_se[min] if _n == 3
replace cihigh  = _b[min]  + 1.96*_se[min] if _n == 3


local Na = $spillovers
forvalues h = 1(1)`Na' {
sort mweffects
replace beta = _b[mina`h'] if _n == 3 + `h'
replace cilow = _b[mina`h']  - 1.96*_se[mina`h'] if _n == 3 + `h'
replace cihigh  = _b[mina`h']  + 1.96*_se[mina`h'] if _n == 3 + `h'	
}
gen group = 3
tempfile PEgroup3
save `PEgroup3'


use ${path}\Dta\sample_nominal.dta, clear
keep if _n == 1
est use ${path}\Results\reg_nominal
keep idw
expand 23
gen mweffects = _n 
drop idw 

gen beta   = . 
gen cilow  = . 
gen cihigh = .


sort mweffects
replace beta = _b[min_half] if _n == 1
replace cilow = _b[min_half]  - 1.96*_se[min_half] if _n == 1
replace cihigh  = _b[min_half]  + 1.96*_se[min_half] if _n == 1

sort mweffects 
replace beta = _b[minb] if _n == 2
replace cilow = _b[minb]  - 1.96*_se[minb] if _n == 2
replace cihigh  = _b[minb]  + 1.96*_se[minb] if _n == 2

sort mweffects 
replace beta = _b[min] if _n == 3
replace cilow = _b[min]  - 1.96*_se[min] if _n == 3
replace cihigh  = _b[min]  + 1.96*_se[min] if _n == 3


local Na = $spillovers
forvalues h = 1(1)`Na' {
sort mweffects
replace beta = _b[mina`h'] if _n == 3 + `h'
replace cilow = _b[mina`h']  - 1.96*_se[mina`h'] if _n == 3 + `h'
replace cihigh  = _b[mina`h']  + 1.96*_se[mina`h'] if _n == 3 + `h'	
}
gen group = 4
tempfile PEgroup4
save `PEgroup4'

use `PEgroup1', clear 
append using `PEgroup2'
append using `PEgroup3'
append using `PEgroup4'


tw (bar beta mweffects if group==2, bcolor(%85)  ) (rcap cilow cihigh mweffects if group==2, lcolor(stblue)) (bar beta mweffects if group==1, bcolor(stred%34)  ) (rcap cilow cihigh mweffects if group==1, lcolor(stred)) (bar beta mweffects if group==3, bcolor(stgreen%34)  ) (rcap cilow cihigh mweffects if group==3, lcolor(stgreen)), legend(order(1 "LP" 3 "GDP" 5 "CPI" ) col(1) ring(0) pos(2) size(small))  xtitle("Distance to the minimum wage") xlabel(1 "-50%MW"  3 "MW"  5 "+14%MW" 7 "+28%MW"  9 "+42%MW"  11 "+56%MW"   13 "+70%MW"    15 "+84%MW"   17 "+98%MW"    19 "+112%MW"   21 "+126%MW" 23 "+140%MW", angle(45)) ytitle("Point estimates") ylabel(0(0.1)0.5)
qui graph export ${path}\Figures\PE_MW_visual.pdf, as(pdf) replace


tw (bar beta mweffects if group==2, bcolor(%85)  ) (rcap cilow cihigh mweffects if group==2, lcolor(stblue)) (bar beta mweffects if group==1, bcolor(stred%34)  ) (rcap cilow cihigh mweffects if group==1, lcolor(stred)) (bar beta mweffects if group==3, bcolor(stgreen%34)  ) (rcap cilow cihigh mweffects if group==3, lcolor(stgreen)) (bar beta mweffects if group==4, bcolor(stc4%21) ) (rcap cilow cihigh mweffects if group==4, lcolor(stc4)), legend(order(1 "LP" 3 "GDP" 5 "CPI" 7 "Nominal") col(1) ring(0) pos(2) size(small))  xtitle("Distance to the minimum wage") xlabel(1 "-50%MW"  3 "MW"  5 "+14%MW" 7 "+28%MW"  9 "+42%MW"  11 "+56%MW"   13 "+70%MW"    15 "+84%MW"   17 "+98%MW"    19 "+112%MW"   21 "+126%MW" 23 "+140%MW", angle(45)) ytitle("Point estimates") ylabel(0(0.1)0.5)
qui graph export ${path}\Figures\PE_MW_visual_withnominal.pdf, as(pdf) replace


