



    
// use fid_types to infer nace_1 code

// take out text from value labels
gen type_lab = ""
levelsof fid_type, local(range)
foreach n of numlist `range' {
    local type_lab_`n': label (fid_type) `n'
	replace type_lab = "`type_lab_`n'''" if fid_type == `n' 
}

// public bodies
foreach x in public budget central political chamber trade municipal {
    tab type_lab if strpos(lower(type_lab), "`x'")
    *replace nace_1 = 15 if strpos(lower(type_lab), "`x'") & nace_1==.
	replace nace_2 = 84 if strpos(lower(type_lab), "`x'") & nace_2==.

}

// agriculture
foreach x in agricul farmer gardener {
    tab type_lab if strpos(lower(type_lab), "`x'")
    *replace nace_1 = 1 if strpos(lower(type_lab), "`x'") & nace_1==.
	replace nace_2 = 1 if strpos(lower(type_lab), "`x'") & nace_2==.
}

// lawyers
*replace nace_1 = 13 if strpos(lower(type_lab), "lawyer") & nace_1==.
replace nace_2 = 69 if strpos(lower(type_lab), "lawyer") & nace_2==.




// extraterritori org __
foreach x in embassy foreign {
    tab type_lab if strpos(lower(type_lab), "`x'")
    *replace nace_1 = 21 if strpos(lower(type_lab), "`x'") & nace_1==.
	replace nace_2 = 99 if strpos(lower(type_lab), "`x'") & nace_2==.
}
	
	
	/*
	g nace_1 = .
replace nace_1 = 1 if inrange(nace_2, 1, 3)
replace nace_1 = 2 if inrange(nace_2, 5, 9)
replace nace_1 = 3 if inrange(nace_2, 10, 33)
replace nace_1 = 4 if inrange(nace_2, 35, 35)
replace nace_1 = 5 if inrange(nace_2, 36, 39)
replace nace_1 = 6 if inrange(nace_2, 41, 43)
replace nace_1 = 7 if inrange(nace_2, 45, 47)
replace nace_1 = 8 if inrange(nace_2, 49, 53)
replace nace_1 = 9 if inrange(nace_2, 55, 56)
replace nace_1 = 10 if inrange(nace_2, 58, 63)
replace nace_1 = 11 if inrange(nace_2, 64, 66)
replace nace_1 = 12 if inrange(nace_2, 68, 68)
replace nace_1 = 13 if inrange(nace_2, 69, 74)
replace nace_1 = 14 if inrange(nace_2, 77, 82)
replace nace_1 = 15 if inrange(nace_2, 84, 84)
replace nace_1 = 16 if inrange(nace_2, 85, 85)
replace nace_1 = 17 if inrange(nace_2, 86, 88)
replace nace_1 = 18 if inrange(nace_2, 90, 93)
replace nace_1 = 19 if inrange(nace_2, 94, 96)
replace nace_1 = 20 if inrange(nace_2, 97, 98)
replace nace_1 = 21 if inrange(nace_2, 99, 99)
label define nace_1lb 1 "Agriculture, forestry and fishing" ///
	2 "Mining and quarrying " ///
	3 "Manufacturing" ///
	4 "Electricity, gas, steam and air conditioning supply" ///
	5 "Water supply; sewerage; waste management and remediation activities" /// 
	6 "Construction" ///
	7 "Wholesale and retail trade; repair of motor vehicles and motorcycles" ///
	8 "Transporting and storage" ///
	9 "Accommodation and food service activities" ///
	10 "Information and communication" ///
	11 "Financial and insurance activities" ///
	12 "Real estate activities " ///
	13 "Professional, scientific and technical activities" ///
	14 "Administrative and support service activities" ///
	15 "Public administration and defense; compulsatory social security" ///
	16 "Education" ///
	17 "Human health and social work activities" ///
	18 "Arts, entertainment and recreation" ///
	19 "Other services activities" ///
	20 "Activities of hoseholds as employers" ///
	21 "Activities of extraterritorial organisations and bodies"
label values nace_1 nace_1lb
label var nace_full "NACE-09 full code"
label var nace_1 "NACE-09 1-digit code"
	
	