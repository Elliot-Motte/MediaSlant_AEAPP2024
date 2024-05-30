*********************
/* Appendix Table A2: placebo*/	
		
use "$replicationdir/02_data/appendix_analysis.dta", clear
set more off



	eststo: reghdfe rep_voteshare_1996 z_lineupFXNC z_lineupMSNBC, noabsorb cluster(fips)
	
				  qui sum rep_voteshare_1996 if e(sample)
				  estadd scalar m r(mean)	
	
	eststo: reghdfe rep_voteshare_1996 z_lineupFXNC z_lineupMSNBC, absorb(state) cluster(fips)
	
				  qui sum rep_voteshare_1996 if e(sample)
				  estadd scalar m r(mean)	
		
	estfe *, labels(state "State FEs")   
			return list  	
			
	local label1 : variable label rep_voteshare_1996	
			
		esttab  using "$replicationdir/03_output/Table_A2.tex", r2 label replace se star(* 0.1 ** 0.05 *** 0.01) booktabs  nonotes b(4) se(3) ///	
				keep(z_lineupFXNC z_lineupMSNBC) ///
				indicate("State FEs = 0.state"  , labels("Yes"  "No")) ///
				substitute("&\multicolumn{1}{c}{`label1'}&\multicolumn{1}{c}{`label1'}"  "&\multicolumn{2}{c}{`label1'}" ) ///
				stats(N r2 m, label( "Observations" "R$^2$" "Mean dep. var." ) fmt(%9.0gc %9.2f %9.2f))
		est clear



















