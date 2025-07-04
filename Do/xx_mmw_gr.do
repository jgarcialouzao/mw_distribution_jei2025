



** Stata 18
*  Fortin et al (2021) approach -- quantification of MW on inequality


** General trends 
putexcel set inequality_table, modify
loc round = 1
foreach deflator of global deflateby  {	
	
	global deflator = "`deflator'"
	** This part until line 47 is not needed when using ${path}\Dta\sample_${deflator}
    *use ${path}\Dta\MWsample.dta, clear
	use ${path} MWsample.dta, clear
	* Deflate monetary variables 
	*merge m:1 year month using ${path}\Dta\deflate.dta, keep(1 3) keepusing(${deflator}) 
	merge m:1 year month using ${path} deflate.dta, keep(1 3) keepusing(${deflator}) 
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
	keep if (year == `year_start')  | (year ==`year_end')
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

	** Distribution details
	qui sum nmw if year ==`year_start'
	matrix A = r(mean)
	matrix colnames A = _:
	
	est clear
	qui sum nmw if year == `year_end'
	matrix A = A \ r(mean)
	
	matrix rownames A = "`year_start'" "`year_end'"


	loc place = 2 + (`round'-1)*5
	putexcel J`place'= matrix(A), names

	
	loc round = `round' + 1
}



	
putexcel save

