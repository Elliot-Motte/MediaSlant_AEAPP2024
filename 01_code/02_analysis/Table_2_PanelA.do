*********************
/* Table 2 - Panel A : Reduced Form results*/
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
				*/ abortion_always {
	
			
		
			eststo: reghdfe `var' z_lineupFXNC z_lineupMSNBC $resp_controls,  absorb(state##year) cluster(fips)
				  qui sum  `var' if e(sample)
				  estadd scalar m r(mean)	
				  qui distinct  fips if e(sample)
				  estadd scalar fips r(ndistinct) 	
				}
				  
		estfe *, labels(fips "County FEs" year "Year FEs")   
			return list  	
			
			
		esttab  using "$replicationdir/03_output/Table_2A.tex", r2 label replace se star(* 0.1 ** 0.05 *** 0.01) booktabs  nonotes b(4) se(3) ///	
				drop(_cons) ///
				indicate("Respondent controls = $resp_controls" "State$\times$ Year FEs = 0.state#0.year"  , labels("Yes"  "No")) ///
				stats(N fips r2 m, label("Observations" "Number of counties" "R$^2$" "Mean dep. var." ) fmt(%9.0gc %9.0gc %9.2f %9.2f))
		est clear












