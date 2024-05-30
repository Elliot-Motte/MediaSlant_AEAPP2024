*********************
/* Table 2 - Panel B : 2SLS results*/
use "$replicationdir/02_data/main_analysis.dta", clear
set more off


	est clear
	
		foreach var in enviro_vs_jobs /*
				*/ enviro_scale /*
				*/ immig_border /*
				*/ immig_legalize /*
				*/ guns_assaultban /*
				*/ guns_permits /*
				*/ abortion_20weeks /*
				*/ abortion_always /*
				*/ {
	
	
			eststo: ivreghdfe `var' (z_RTGFXNC = z_lineupFXNC) z_lineupMSNBC $resp_controls , absorb(state##year) cluster(fips)
				  estadd scalar  wid_stat e(widstat)
				  qui sum  `var' if e(sample)
				  estadd scalar m r(mean)	
				  qui distinct  fips if e(sample)
				  estadd scalar fips r(ndistinct) 
				  
		
				  
				}
				
		estfe *, labels(fips "County FEs" year "Year FEs")   
			return list  	
			
			
		esttab  using "$replicationdir/03_output/Table_2B.tex", r2 label replace se star(* 0.1 ** 0.05 *** 0.01) booktabs  nonotes b(4) se(3) ///	
				indicate("MSNBC position = z_lineupMSNBC" "Respondent controls = $resp_controls" "State$\times$ Year FEs = 0.state#0.year"  , labels("Yes"  "No")) ///
				stats(wid_stat N fips r2 m, label("First stage F-stat" "Observations" "Number of counties" "R$^2$" "Mean dep. var." ) fmt(%9.2f %9.0gc %9.0gc %9.2f %9.2f))
		est clear
		