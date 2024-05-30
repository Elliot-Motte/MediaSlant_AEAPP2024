*********************
/* Appendix Table A3: First Stage*/	
		
use "$replicationdir/02_data/appendix_analysis.dta", clear
set more off


	eststo: reghdfe  z_RTGFXNC z_lineupFXNC z_lineupMSNBC, noabsorb cluster(fips)
		
	
	eststo: reghdfe  z_RTGFXNC z_lineupFXNC z_lineupMSNBC, absorb(state) cluster(fips)
	
	
	eststo: reghdfe  z_RTGMSNBC z_lineupFXNC z_lineupMSNBC, noabsorb cluster(fips)
	
	
	eststo: reghdfe  z_RTGMSNBC z_lineupFXNC z_lineupMSNBC, absorb(state) cluster(fips)
	
	
	
	estfe *, labels(state "State FEs")   
			return list  	
			
			
	local label1 : variable label z_RTGFXNC	
	local label2 : variable label z_RTGMSNBC	
			
		esttab  using "$replicationdir/03_output/Table_A3.tex", r2 label replace se star(* 0.1 ** 0.05 *** 0.01) booktabs  nonotes b(4) se(3) ///	
				keep(z_lineupFXNC z_lineupMSNBC) ///
				indicate("State FEs = 0.state"  , labels("Yes"  "No")) ///
				substitute("&\multicolumn{1}{c}{`label1'}&\multicolumn{1}{c}{`label1'}"  "&\multicolumn{2}{c}{`label1'}" "&\multicolumn{1}{c}{`label2'}&\multicolumn{1}{c}{`label2'}"  "&\multicolumn{2}{c}{`label2'}") ///
				stats(N r2, label( "Observations" "R$^2$" ) fmt(%9.0gc %9.2f))

		est clear
