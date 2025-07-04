

* Stata 18
********************************************************************************
** Pooled all the waves together to create a monthly panel for valid workers
/*
forvalues y = 2010(1)2020 {
use ../dta/sodra`y'.dta, clear

*If central bank, fid should be the same -- before 2012, there were several, but it creates artificially different companies 
replace fid = 100045670 if fid_type==13

gen monthly =  mofd(mdy(month,1,year))
format monthly %tm

* compute days worked by spell 
gen first=dofm(monthly)
gen last=dofm(monthly+1)-1
gen 	days = .
replace days = emp_end_date - first + 1 if emp_start_date<=first & emp_end_date<last
replace days = last - emp_start_date + 1  if emp_start_date>first & emp_end_date>=last
replace days = emp_end_date - emp_start_date  + 1  if emp_start_date>first & emp_end_date<last
replace days = 30 if emp_start_date<=first & emp_end_date>=last
drop first last 

* Lithuanian dummy
gen lithuanian = nationality=="LTU"
drop nationality

*Censored spells
gen cens = emp_end_date > mdy(12,31,2020)

gcollapse (sum) income days (firstnm) year month unemp_benefits sickness_benefits incapacity_benefits parenthood_benefits maternity_benefits childcare_allowances other_benefits retirement_pension other_pension emp_start_date_first = emp_start_date (lastnm) female birthdate marital_status marital_status_changedate nb_children lithuanian first_emp_date  pid_location employment_contract oec emp_start_date_last = emp_start_date emp_end_date* status cens isco08code fid_type fid_birthdate fid_municipality nace_full fsize wage_bill , by(pid fid monthly)

qui compress

tempfile year`y'	
save `year`y'', replace 
}

use `year2010', clear
forvalues n = 2011(1)2020 {
append using `year`n''	
}


* Identify anybody with quarterly days at a firm abnormally large: they reflect mostly duplicates
qui sum days, d 
gen flag = 1 if days>`r(p99)'
bys pid fid (flag): replace flag=flag[1] if flag==.
drop if flag==1
drop flag
assert days<=30
qui compress

* Remove workers who never worked between 2010-2020
gen flag = fid==. 
bys pid: egen mean = mean(flag)
drop if mean == 1
drop flag mean

* Remove too old workers, i.e., first observation in the data is 60 or older 
gen age = yofd(dofm(monthly)) - yofd(birthdate)
bys pid: egen min=min(age)
drop if min>=60
drop min

*Location: if missing recover, otherwise discard
**assume same location where most common place of living of workers observed in that firm and working if missing fid_municipality
replace fid_municipality = . if fid_municipality==-1
replace pid_location = . if pid_location==-1
bys fid: egen mode = mode(fid_municipality), maxmode
replace fid_municipality = mode  if fid_municipality!=mode
drop mode
bys fid: egen mode = mode(pid_location), maxmode
replace fid_municipality = mode  if fid_municipality==.
replace fid_municipality = 999   if fid_municipality==.
drop mode
bys pid: egen mode = mode(fid_municipality), maxmode
replace pid_location = mode  if pid_location==.
drop mode

* Remove non-employment observations
drop if fid==.

* Indsutry: homogeneize sectors within firms: firms do not change sectors, is a fixed attribute
g nace_2 = int(nace_full/10000)
drop nace_full
qui do ${path}\Do\xx_aux_recovernace.do
drop type_lab 
bys fid: egen mode = mode(nace_2), maxmode
replace nace_2 = mode 
drop mode

* Isco occupation, 2digits
gen isco2d = int(isco08/100)
drop isco08
bys pid year: egen mode = mode(isco2d), maxmode
replace isco2d = mode if isco2d==.
drop mode 
bys pid fid emp_start_date_first: egen mode = mode(isco2d), maxmode
replace isco2d = mode if isco2d==.
drop mode
gen period = 1 if monthly<mofd(mdy(8,1,2012))
replace period = 2 if monthly>=mofd(mdy(8,1,2012)) & monthly<mofd(mdy(1,1,2015))
replace period = 3 if monthly>=mofd(mdy(1,1,2015)) & monthly<mofd(mdy(7,1,2017))
replace period = 4 if monthly>=mofd(mdy(7,1,2017))
bys pid fid period: egen mode = mode(isco2d), maxmode
replace isco2d = mode if isco2d==.
drop mode period
bys pid fid: egen mode = mode(isco2d), maxmode
replace isco2d = mode if isco2d==.
drop mode
bys pid: egen mode = mode(isco2d), maxmode
replace isco2d = mode if isco2d==.
drop mode

* Adjust type of employment relationship, make it fix within job spells
replace status = 999999 if status==.
bys pid fid: egen mode = mode(status), maxmode
replace status = mode
drop mode 


* Identify public sector 
gen publicsector=0
replace publicsector = 1 if nace_2==84
qui {
gen type_lab = ""
levelsof fid_type, local(range)
foreach n of numlist `range' {
    local type_lab_`n': label (fid_type) `n'
	replace type_lab = "`type_lab_`n'''" if fid_type == `n' 
}
foreach x in public budget central political chamber trade municipal {
    tab type_lab if strpos(lower(type_lab), "`x'")
	replace publicsector = 1 if strpos(lower(type_lab), "`x'")
}
}
drop type_lab 

* Identify state-owned enterprise
gen stateowned = fid_type==52 | fid_type==53

order monthly pid fid emp_start_date* emp_end_date income

save ${path}\Dta\monthly_panel.dta, replace
*/


*********************** SAMPLE SELECTION
use ${path}\Dta\monthly_panel.dta, clear

* Age group
keep if age>=18 & age<=65

* Exclude covid year
drop if year==2020

* only wage-employment and full-month employees
keep if status==999999 

* remove missing location, sector, occupation 
** fix isco 
drop if fid_municipality==999 | pid_location==999 | isco==. | isco==1 | nace_2==.

* working full-month 
keep if days==30 

* remove situations when the worker is receiven social benefits, given the status==999999, this implies the worker is not working full-time (hours or days)
foreach x in unemp_benefits sickness_benefits incapacity_benefits parenthood_benefits maternity_benefits retirement_pension other_pension {
drop if `x'>0 & `x'<.
}

* remove last observation of the spell -> exclude severance and other payments at termination
gen tenure = monthly - mofd(emp_start_date_first) + 1
drop if mofd(emp_end_date)==monthly &  cens==0

* Add minimum wage
merge m:1 year month using ${path}\Dta\NMW.dta, keep(1 3)
replace nmw = 1.289*nmw if year<2019 // adjust minimum wage to 2019 reform of SS
replace nmw = round(nmw,1)
assert _m==3 
drop _m 

*only monthly income above 1/4 monthly mw  -> reduce employees working very few hours or large non-compliance
replace income = round(income,1)
keep if income>=nmw/4 & income<.
drop if income>500*nmw

* keep workers main job 
*bys pid monthly (income): keep if _n == _N

* relevant variables 
egen idjob = group(pid fid emp_start_date_first)
keep year month* pid fid idjob female lithuanian age income* fid_municipality nace_2 tenure isco2d publicsector stateowned fsize nmw 

* double anonymization of ids
egen idw = group(pid)
drop pid 
egen idf = group(fid)
drop fid 

* label variables 
label var year  "Year of observation"
label var month "Month of observation"
label var idw   "Worker ID"
label var idf   "Firm ID"
label var idjob "Firm-worker-start ID"
label var female "Female = 1"
label var lithuanian "Lithuanian = 1"
label var age    "Age in years"
label var income "Monthly earnings"
label var tenure "Tenure (in months)"
label var nace   "NACE2 (2-digits sector)"
label var isco   "ISCO-08 (2-digit occupation)"
label var publicsector "Public sector = 1"
label var fsize "Firm size end of the year"
label var stateowned "State-owned firm"
label var fid_municipality "Firm's location"
label var nmw     "Monthly minium wage"

order year month monthly idw idf idjob female lithuanian age income fid_municipality nace_2 isco2d publicsector stateowned fsize nmw
compress

save ${path}\Dta\MWsample.dta, replace


