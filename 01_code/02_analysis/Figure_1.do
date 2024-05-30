/*************************************
Author: Elliot Motte.
Contact: elliot.motte@upf.edu

Goal: Produce graph for cable TV segments content analysis, i.e. GPT content analysis of MSNBC and FoxNews for questions on guns, immigration, abortion, CC.

Inputs: 
	1. $replicationdir/02_data/01_TV_segments/03_processed/abortion_segments_parsed_answers.csv
	2. $replicationdir/02_data/01_TV_segments/03_processed/immigration_segments_parsed_answers.csv
	3. $replicationdir/02_data/01_TV_segments/03_processed/guns_segments_parsed_answers.csv
	4. $replicationdir/02_data/01_TV_segments/03_processed/climate_segments_parsed_answers.csv

Note: These input CSVs are all produced by the ./01_code/01_data_prep/02_GPT_labelling.py
	
Output: /03_output/Figure_1.eps, which is the file used for Figure 1 of AEA Papers & Proceedings "Media Slant and Public Policy Views".

**************************************/



*********************
/*Abortion*/
import delimited "$replicationdir/02_data/01_TV_segments/03_processed/abortion_segments_parsed_answers.csv", clear varn(1) case(l)
set more off
tab _abortion_about, m
keep if _abortion_about == "a" /*Filter out "No" or "Not sure"*/
tab _abortion_rights station, m col

/*Format values from string GPT answers to numeric*/	
	replace _abortion_rights_for_against = "1" if _abortion_rights_for_against == "a"
	replace _abortion_rights_for_against = "0" if _abortion_rights_for_against == "b"
	replace _abortion_rights_for_against = "" if _abortion_rights_for_against == "x" 
	destring _abortion_rights_for_against, replace
	tab _abortion_rights_for_against, m gen(_abortion_rights_for)
	rename (_abortion_rights_for1 _abortion_rights_for2 _abortion_rights_for3) (_abortion_rights_against _abortion_rights_for _abortion_rights_mis)
	foreach x of varlist _abortion_rights_against _abortion_rights_for _abortion_rights_mis {
	replace `x' = 100*`x'
	}		
	
keep station _abortion_rights_against _abortion_rights_for _abortion_rights_mis

foreach x of varlist _abortion_* {
rename `x' gpt`x'
}

/*Get means, SD and counts by station in order to create error bars later*/
preserve
collapse (mean) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' m`x'
}
tempfile means
save `means', replace
restore

preserve
collapse (sd) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' sd`x'
}
tempfile stdevs
save `stdevs', replace
restore

preserve
collapse (count) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' c`x'
}
tempfile counts
save `counts', replace
restore

use `means', clear
merge 1:1 station using `stdevs'
drop _merge
merge 1:1 station using `counts'
drop _merge

 
 /*Create bounds of CIs*/
gen gpt_abortion_rights_against = .
gen gpt_abortion_rights_for = .
gen gpt_abortion_rights_mis = .
la var gpt_abortion_rights_against "Against stronger abortion rights"
la var gpt_abortion_rights_for "For stronger abortion rights"
la var gpt_abortion_rights_mis "Not sure on stronger abortion rights"

 foreach x of varlist gpt_* {
 capt drop u`x' l`x'
generate u`x' = m`x' + invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
generate l`x' = m`x' - invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
}

tempfile abortion_stations
save `abortion_stations', replace





***********************
/*Guns*/
import delimited "$replicationdir/02_data/01_TV_segments/03_processed/guns_segments_parsed_answers.csv", clear varn(1) case(l)
set more off
tab _guns_about, m
keep if _guns_about == "a" /*Filter out "No" or "Not sure"*/
tab _guns_control station, m col

/*Format values from string GPT answers to numeric*/	
	replace _guns_control_for_against = "1" if _guns_control_for_against == "a"
	replace _guns_control_for_against = "0" if _guns_control_for_against == "b"
	replace _guns_control_for_against = "" if _guns_control_for_against == "x" 
	destring _guns_control_for_against, replace
	tab _guns_control_for_against, m gen(_guns_control_for)
	rename (_guns_control_for1 _guns_control_for2 _guns_control_for3) (_guns_control_against _guns_control_for _guns_control_mis)
	foreach x of varlist _guns_control_against _guns_control_for _guns_control_mis {
	replace `x' = 100*`x'
	}
	
keep station _guns_control_against _guns_control_for _guns_control_mis

foreach x of varlist _guns_* {
rename `x' gpt`x'
}

/*Get means, SD and counts by station in order to create error bars later*/
preserve
collapse (mean) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' m`x'
}
tempfile means
save `means', replace
restore

preserve
collapse (sd) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' sd`x'
}
tempfile stdevs
save `stdevs', replace
restore

preserve
collapse (count) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' c`x'
}
tempfile counts
save `counts', replace
restore

use `means', clear
merge 1:1 station using `stdevs'
drop _merge
merge 1:1 station using `counts'
drop _merge
 
 /*Create bounds of CIs*/
gen gpt_guns_control_against = .
gen gpt_guns_control_for = .
gen gpt_guns_control_mis = .

la var gpt_guns_control_against "Against stronger gun control"
la var gpt_guns_control_for "For stronger gun control"
la var gpt_guns_control_mis "Not sure on stronger gun control"

 foreach x of varlist gpt_* {
 capt drop u`x' l`x'
generate u`x' = m`x' + invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
generate l`x' = m`x' - invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
}

tempfile guns_stations
save `guns_stations', replace




***********************
/*Immigration*/
import delimited "$replicationdir/02_data/01_TV_segments/03_processed/immigration_segments_parsed_answers.csv", clear varn(1) case(l)
set more off
tab _immigration_about, m
keep if _immigration_about == "a" /*Filter out "No" or "Not sure"*/
tab _immigration_restr station, m col

/*Format values from string GPT answers to numeric*/	
	replace _immigration_restr_for_against = "1" if _immigration_restr_for_against == "a"
	replace _immigration_restr_for_against = "0" if _immigration_restr_for_against == "b"
	replace _immigration_restr_for_against = "" if _immigration_restr_for_against == "x" 
	destring _immigration_restr_for_against, replace
	tab _immigration_restr_for_against, m gen(_immigration_restr_for)
	rename (_immigration_restr_for1 _immigration_restr_for2 _immigration_restr_for3) (_immigration_restr_against _immigration_restr_for _immigration_restr_for_mis)
	foreach x of varlist _immigration_restr_against _immigration_restr_for _immigration_restr_for_mis {
	replace `x' = 100*`x'
	}
	
keep station _immigration_restr_against _immigration_restr_for _immigration_restr_for_mis

foreach x of varlist _immigration_* {
rename `x' gpt`x'
}

/*Get means, SD and counts by station in order to create error bars later*/
preserve
collapse (mean) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' m`x'
}
tempfile means
save `means', replace
restore

preserve
collapse (sd) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' sd`x'
}
tempfile stdevs
save `stdevs', replace
restore

preserve
collapse (count) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' c`x'
}
tempfile counts
save `counts', replace
restore

use `means', clear
merge 1:1 station using `stdevs'
drop _merge
merge 1:1 station using `counts'
drop _merge
 
 /*Create bounds of CIs*/ 
gen gpt_immigration_restr_against = .
gen gpt_immigration_restr_for = .
gen gpt_immigration_restr_for_mis = .

la var gpt_immigration_restr_against "Against stronger immigration restrictions"
la var gpt_immigration_restr_for "For stronger immigration restrictions"
la var gpt_immigration_restr_for_mis "Not sure on stronger immigration restrictions"

 foreach x of varlist gpt_* {
 capt drop u`x' l`x'
generate u`x' = m`x' + invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
generate l`x' = m`x' - invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
}

tempfile immigration_stations
save `immigration_stations', replace




*******************************
/*Climate Change*/
import delimited "$replicationdir/02_data/01_TV_segments/03_processed/climate_segments_parsed_answers.csv", clear varn(1) case(l)
set more off
tab _cc_about, m
keep if _cc_about == "a" /*Filter out "No" or "Not sure"*/
tab _cc_policy station, m col

/*Format values from string GPT answers to numeric*/	
replace _cc_policy_for_against = "1" if _cc_policy_for_against == "a"
replace _cc_policy_for_against = "0" if _cc_policy_for_against == "b"
replace _cc_policy_for_against = "" if _cc_policy_for_against == "x"
destring _cc_policy_for_against, replace
tab _cc_policy_for_against, m gen(_cc_pol_for_against)
rename (_cc_pol_for_against1 _cc_pol_for_against2 _cc_pol_for_against3) (_cc_pol_against _cc_pol_for _cc_pol_for_mis) 
foreach x of varlist _cc_pol_against _cc_pol_for _cc_pol_for_mis {
replace `x' = 100*`x'
}

keep station _cc_pol*

foreach x of varlist *_cc_pol_* {
rename `x' gpt`x'
}


/*Get means, SD and counts by station in order to create error bars later*/
preserve
collapse (mean) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' m`x'
}
tempfile means
save `means', replace
restore

preserve
collapse (sd) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' sd`x'
}
tempfile stdevs
save `stdevs', replace
restore

preserve
collapse (count) gpt*, by(station)
foreach x of varlist gpt_* {
rename `x' c`x'
}
tempfile counts
save `counts', replace
restore

use `means', clear
merge 1:1 station using `stdevs'
drop _merge
merge 1:1 station using `counts'
drop _merge
 
 /*Create bounds of CIs*/
gen gpt_cc_pol_against = .
gen gpt_cc_pol_for = .
gen gpt_cc_pol_for_mis = .

la var gpt_cc_pol_against "Against stronger climate change policy"
la var gpt_cc_pol_for "For stronger climate change policy"
la var gpt_cc_pol_for_mis "Not sure about stronger climate change policy"

 foreach x of varlist gpt_* {
 capt drop u`x' l`x'
generate u`x' = m`x' + invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
generate l`x' = m`x' - invttail(c`x'-1,0.025)*(sd`x' / sqrt(c`x'))
}

tempfile climate_stations
save `climate_stations', replace




**********************************
/*Merge station shares of segments for all 4 policy issues and prepare dataset for graph*/
use `abortion_stations', clear
merge 1:1 station using `guns_stations', nogen
merge 1:1 station using `immigration_stations', nogen
merge 1:1 station using `climate_stations', nogen

preserve
keep station *gpt_abortion_rights_for
gen value = "Abortion"
rename (mgpt_abortion_rights_for ugpt_abortion_rights_for lgpt_abortion_rights_for) (mgpt ugpt lgpt)
tempfile abortion
save `abortion', replace
restore

preserve
keep station *gpt_guns_control_for
gen value = "Guns"
rename (mgpt_guns_control_for ugpt_guns_control_for lgpt_guns_control_for) (mgpt ugpt lgpt)
tempfile guns
save `guns', replace
restore

preserve
keep station *gpt_immigration_restr_against
gen value = "Immigration"
rename (mgpt_immigration_restr_against ugpt_immigration_restr_against lgpt_immigration_restr_against) (mgpt ugpt lgpt)
tempfile immig
save `immig', replace
restore

preserve
keep station *gpt_cc_pol_for
gen value = "Climate"
rename (mgpt_cc_pol_for  ugpt_cc_pol_for  lgpt_cc_pol_for ) (mgpt ugpt lgpt)
tempfile climate
save `climate', replace
restore


use `abortion', clear
append using `guns'
append using `immig'
append using `climate'

capt drop x_axis_position
generate  x_axis_position = 1  if station == "MSNBC" & value == "Climate"
replace  x_axis_position = 1.5  if station == "FOXNEWS" & value == "Climate"
replace  x_axis_position = 3.5  if station == "MSNBC" & value == "Immigration"
replace  x_axis_position = 4  if station == "FOXNEWS" & value == "Immigration"
replace  x_axis_position = 6  if station == "MSNBC" & value == "Guns"
replace  x_axis_position = 6.5  if station == "FOXNEWS" & value == "Guns"
replace x_axis_position = 8.5   if station == "MSNBC" & value == "Abortion"
replace  x_axis_position = 9  if station == "FOXNEWS" & value == "Abortion" 

graph set window fontface "Times New Roman"

twoway  (bar mgpt x_axis_position if x_axis_position == 1, bcolor(navy) barwidth(0.5) ) ///
		(bar mgpt x_axis_position if x_axis_position == 1.5 , bcolor(maroon) barwidth(0.5)) ///
		(bar mgpt x_axis_position if x_axis_position == 3.5, bcolor(navy) barwidth(0.5) ) ///
		(bar mgpt x_axis_position if x_axis_position == 4 , bcolor(maroon) barwidth(0.5)) ///
		(bar mgpt x_axis_position if x_axis_position == 6, bcolor(navy) barwidth(0.5) ) ///
		(bar mgpt x_axis_position if x_axis_position == 6.5 , bcolor(maroon) barwidth(0.5)) ///
		(bar mgpt x_axis_position if x_axis_position == 8.5, bcolor(navy) barwidth(0.5) ) ///
		(bar mgpt x_axis_position if x_axis_position == 9 , bcolor(maroon) barwidth(0.5)) ///
		(rcap ugpt lgpt x_axis_position, lcolor(sand) msize(small)), ///
       graphregion(color(white)) xsize(10) ysize(2.5) legend(label(1 "MSNBC") label(2 "FoxNews") order(1 2) size(vhuge)) ylabel(0(20)100, labsize(huge)) ///
       xscale(range(0 10)) xlabel(1.25 "Climate Change" 3.75 "Immigration" 6.25 "Gun Control" 8.75 "Abortion", noticks labsize(vhuge)) xtitle("") 
graph export "$replicationdir/03_output/Figure_1.eps", replace font("Times New Roman")
graph export "$replicationdir/03_output/Figure_1.pdf", replace 

