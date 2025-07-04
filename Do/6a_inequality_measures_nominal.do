



** Stata 18
*  Fortin et al (2021) approach -- quantification of MW on inequality


** General trends 
putexcel set inequality_table_nominal, modify
loc round = 1
foreach deflator of global deflateby  {	
	
	global deflator = "`deflator'"
	** This part until line 47 is not needed when using ${path}\Dta\sample_${deflator}
    use ${path}\Dta\MWsample.dta, clear
	* Deflate monetary variables 
	merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator}) 
	assert _m == 3
	drop _m
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
	keep if year == `year_start'  | year ==`year_end'
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
	* use ${path}\Dta\sample_${deflator}.dta, clear
	merge m:1 monthly inccat using ${path}\Results\rwgt_${deflator}_nominal.dta, keep(match) nogen


	foreach x in income nmw  {
	replace `x' = exp(`x')
	qui replace `x' = (`x'*${deflator})
	replace `x' = round(ln(`x'),0.01)
	}

	** Distribution details
	est clear
	qui estpost tabstat income if year ==`year_start', statistics(mean sd p10 p50 p90) columns(statistics)
	qui esttab, cells("mean sd p10 p50 p90") noobs label nonum gaps f
	matrix A = r(coefs)
	matrix colnames A = _:
	
	est clear
	qui estpost tabstat income if year == `year_end', statistics(mean sd p10 p50 p90) columns(statistics)
	qui esttab, cells("mean sd p10 p50 p90") noobs label nonum gaps f
	matrix A = A \ r(coefs)
	
	est clear
	qui estpost tabstat income [aw=rw_mwc] if year == `year_end', statistics(mean sd p10 p50 p90) columns(statistics)
	qui esttab, cells("mean sd p10 p50 p90") noobs label nonum gaps f
	matrix A = A \ r(coefs)


	matrix rownames A = "`year_start'" "`year_end'" "`year_end' w/MW of `year_start'"


	loc place = 2 + (`round'-1)*5
	putexcel B`place'= matrix(A), names
	
	** Earnings gaps across groups
	* Lithuanian regions from municipalities
	qui merge m:1 fid_municipality using ${path}\Data\municipality_ids.dta, keep(1 3) keepusing(nuts3) nogen 
	gen top3 = 0
	replace top3 = 1 if inlist(nuts3, 11, 22, 23)

	* Skill category based on ISCO-08
	qui gen isco_skill = 0 if isco2d>41
	qui replace isco_skill = 1 if inrange(isco2d, 11, 35)
	drop isco2d
	
	* Age groups
	qui gen agecat = 1 if inrange(age,18,29)
	qui replace agecat = 0 if inrange(age,30,.)
	drop age 


	* Define variable names for subgroups
	local subgroups "female publicsector top3 isco_skill agecat"
	local subgroup_number : word count `subgroups'
	di `num'
	* Create a matrix
	matrix define mean_diffs = J(3, `subgroup_number', .)
	

	forvalues subgroup_nr = 1(1)`subgroup_number' {
	
		local subgroup: word `subgroup_nr' of `subgroups'

		* Start period
		qui summarize income if year == `year_start' & `subgroup' == 1, meanonly
		local mean_group1 = r(mean)

		qui summarize income if year == `year_start' &  `subgroup' == 0, meanonly
		local mean_group2 = r(mean)

		* Calculate difference of means
		matrix mean_diffs[1,`subgroup_nr'] = `mean_group1' - `mean_group2'

		* End period
		qui summarize income if year == `year_end' & `subgroup' == 1, meanonly
		local mean_group1 = r(mean)

		qui summarize income if year == `year_end' & `subgroup' == 0, meanonly
		local mean_group2 = r(mean)

		* Calculate difference of means
		matrix mean_diffs[2,`subgroup_nr'] =  `mean_group1' - `mean_group2'


		* Counterfactual
		qui summarize income [aw=rw_mwc] if year == `year_end' & `subgroup' == 1, meanonly
		local mean_group1 = r(mean)

		qui summarize income [aw=rw_mwc] if year == `year_end' & `subgroup' == 0, meanonly
		local mean_group2 = r(mean)

		* Calculate difference of means
		matrix mean_diffs[3,`subgroup_nr'] = `mean_group1' - `mean_group2'
	}
	
	loc place = 40 + (`round'-1)*5 
	putexcel B`place'= matrix(mean_diffs), names
	
	loc round = `round' + 1
}



putexcel save


