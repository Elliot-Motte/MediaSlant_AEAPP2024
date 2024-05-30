* Set the working directory
cd "C:/Users/ellio/Dropbox/Climate_Change_narratives/AEA_PP_submission/03_replication/01_code"


* Define global macros for paths
global replicationdir "C:/Users/ellio/Dropbox/Climate_Change_narratives/AEA_PP_submission/03_replication"

*Set ado directory
adopath ++ "$replicationdir/00_programs/ado"



* Install required Stata packages if not already installed
//ssc install zscore /*or do findit zscore and then manually click on installing the package)*/
//net install statastates, from(https://raw.github.com/wschpero/statastates/master/)
//ssc install ftools
//ssc install reghdfe
//ssc install estout



*Define global for variable lists used in the regressions
global resp_controls /*
	*/ age  /*
	*/ gender /*
	*/ college faminc /*
	*/ __ideo31 __ideo32 __ideo33 /*
	*/ __pid31 __pid32 __pid33

	
*Set random seed for reproducibility
set seed 3547











