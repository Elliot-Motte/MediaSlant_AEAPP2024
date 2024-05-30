/*************************************
Authors: Milena Djourelova & Elliot Motte.
Contact: mnd43@cornell.edu

Goal: Create analysis files to produce Tables 1 & 2 of "Media Slant and Public Policy Views" AEA Papers and Proceedings 2024.

**************************************/



clear all
set more off



/*Clean county-fips crosswalk from the USDA*/
import delimited "$replicationdir/02_data/03_Controls/US_county_fips.txt", clear varn(1) case(lower)
set more off
rename name county
order state county fips, first
drop if inlist(state, "AS", "MP", "GU", "PR", "VI") /*Drop US territories*/


/*Format FIPS code*/
tostring fips, gen(str_fips)

capt drop len_fips
gen len_fips = length(str_fips)
replace str_fips = "0" + str_fips if len_fips == 4
replace len_fips = length(str_fips) 
drop len_fips

replace county = lower(county)

/*Add in state name*/
statastates, abbreviation(state) nogen
drop state_fips
order state_name, after(state)
replace state_name = lower(state_name)

capt drop str_state_county
gen str_state_county = state_name + " " + county

tempfile fips_cty_usda
save `fips_cty_usda', replace




/*Clean NIELSEN ratings/viewership data at county level*/
import excel "$replicationdir/02_data/04_NIELSEN/county_level_2012.xlsx", first clear

  
  keep if Characteristic == "TV Households"
  keep if Affil == "CABLE"
  
  
  
  *** merge counties to fips-county crosswalk
  
  
  split Geography, p(",")
  
  
  rename Geography1 county
  rename Geography2 state
  
  replace state = trim(state)
  
  replace county = subinstr(county, " Co.", "" , .)
  
  replace county = lower(county)
  
  keep state county ViewingSource RTG 
  rename ViewingSource channel
  
  /*Cleaning county name prior to merging*/  
  replace county = "de kalb" if county == "dekalb"
  replace county = "de soto" if county == "desoto"
  replace county = "de witt" if county == "dewitt"
  replace county = "jefferson davis" if county=="jeff davis"
  replace county = "jefferson davis" if county=="jeff davis"
  replace county = "la grange" if county=="lagrange"
  replace county = "la moure" if county=="lamoure"

  replace county = subinstr(county, "-e", "",.)
  replace county = subinstr(county, "-w", "",.)
  replace county = subinstr(county, "-s", "",.)
  replace county = subinstr(county, "-n", "",.)

   
  collapse (mean) RTG, by(state county channel) /*Take mean rating for duplicates*/
   
  
  merge m:1 county state using `fips_cty_usda', keepusing(fips state)
  
  drop if _merge==2 
     drop _merge
  
  
  /*Do some cleaning then reshape wide*/
  replace channel = trim(channel)
  
  keep fips channel RTG
  
  drop if fips == .
  
  drop if channel =="MSNA"

  
  reshape wide RTG, i(fips) j(channel) string
  
  la var fips "5-digit fips code of county"
  
  
  tempfile ratings_by_county
     save `ratings_by_county', replace
  
  

  
 /*Clean cable lineup data (channel positions)*/
import delimited using "$replicationdir/02_data/04_NIELSEN/2012 Carriage", varn(3) clear

		replace hetype = trim(hetype)
		replace device = trim(device)
	
		
		keep heid netstncall lineup
		
		rename netstncall channel
		rename lineupchannelposition lineup
				
		duplicates drop
		
		replace channel = trim(channel)
		drop if channel == ""
		
		drop if lineup == .
		
		
		*** in case of conflict in the data, take the lowest channel position
		
		sort heid channel lineup
		  by heid channel: keep if _n==1
		
		
		reshape wide lineup, i(heid) j(channel) string
		
		su lineup*, de

		
  tempfile lineups_by_operator		
     save `lineups_by_operator', replace		


	 

/*Clean NIELSEN geo-to-zipcode crosswalk*/
import delimited using "$replicationdir/02_data/04_NIELSEN/2012 Geography Served", varn(3) clear


		keep heid zipcode
		
		replace zipcode=trim(zipcode)
		
		destring zipcode, replace force
		
		
		tempfile zipcode
		save `zipcode', replace
		
		
		*** Merge in to zipcode-county mapping + zipcode population
   
		import delimited using "$replicationdir/02_data/03_Controls/zcta_county_rel_10.txt", clear
		
		
		*** In case of duplicates: keep county that accounts for most of the zipcode
		rename geoid fips
		
		keep zcta5 fips poppt zpop state
		
		rename zcta5 zipcode
		
		
		joinby zipcode using `zipcode'
		
		
			
			*** Merge in lineups
			
			merge m:1 heid using `lineups_by_operator', keepusing(lineup*)

			drop _merge
	
			drop if fips == .
		
			
			collapse (mean) lineup* [pw=poppt], by(fips state) /*The channel position in a county is the pop-weighted avg. of lineup of the channel in all zipcodes of the county*/
			
			
			*** Merge in ratings
			
			merge m:1 fips using `ratings_by_county'		
  
			drop _merge
			
			
			
			tempfile county_level_data
			   save `county_level_data', replace
			
			
			
			
			**** Merge in county-level covariates
			
			use "$replicationdir/02_data/03_Controls/county_controls_2010.dta", clear
		
			merge 1:1 fips using `county_level_data'
			drop if _merge == 1
			drop _merge 
			
			save `county_level_data', replace
			
			
			**** Merge in vote share in the year 1996			
			
			use "$replicationdir/02_data/03_Controls/presidential.dta", clear
				  
				  keep if year == 1996
				  
				  gen rep_voteshare_1996 = repshare 
				  
			  merge 1:m fips using `county_level_data'
			  drop if _merge == 1
			  drop _merge 
			  
			  
			 /*Format vars before analysis */ 
			 rename lineupMNBC lineupMSNBC
				
			/*Create z-scores*/
			zscore RTGFXNC
			zscore RTGMSNBC 
		
			zscore lineupFXNC
			zscore lineupMSNBC
		
		
			label var z_lineupFXNC "Fox News position (std)"
			label var z_lineupMSNBC "MSNBC position (std)"
			label var z_RTGFXNC    "Fox News rating (std)"
			label var z_RTGMSNBC   "MSNBC rating (std)"
		
			label var rep_voteshare_1996 "1996 Republican vote share"
			
			save "$replicationdir/02_data/appendix_analysis.dta", replace
						

			
			
*** Merge in CCES data

	use "$replicationdir/02_data/02_CCES/cumulative_cces_policy_preferences", clear
		merge 1:1 case_id year using "$replicationdir/02_data/02_CCES/cumulative_2006-2021"
			
			
		drop _merge 
		
		destring county_fips, replace
		rename county_fips fips
		
		merge m:1 fips using "$replicationdir/02_data/appendix_analysis.dta"
			
		drop if _merge==2
		   drop _merge
		   
		   
		 /*Clean vars for analysis*/	
			recode ideo5 (6=.)
			
			   gen ideo3 = ideo5
			recode ideo3 (1 2=1)(3=2)(4 5=3)
	
		  
			 **** Differences in demographics
			 
			   gen college = educ
			recode college (1/3=0)(4/6=1)
			recode gender (1=1)(2=0) 
			 
			 recode ideo5 (6=0)
			 recode faminc (13=.)(14=.)
			 
			 recode pid7 (8=.)
			 recode pid3 (1=1)(3=2)(2=3)(4=.)(5=.)
			 
			 label define pid3_ 1 "Democrat" 2 "Independent" 3 "Republican"
			 label val pid3 pid3_
			 
			 
			 
			 label var age     "Age"
			 label var gender  "Male"
			 label var college "College degree"
			 label var faminc  "Income category"
			 label var ideo5   "Ideology category (Liberal to Conservative)"
			 
			 

				qui tab ideo3, gen(__ideo3)
				qui tab pid3, gen(__pid3)
				
		
		
		recode guns_assaultban (1=1)(2=0)
		recode guns_permits    (2=1)(1=0)
		
		recode immig_border   (2=1)(1=0)
		recode immig_legalize (1=1)(2=0)

		recode abortion_20weeks (2=1)(1=0)
		recode abortion_always  (1=1)(2=0)
		
		recode enviro_vs_jobs (6=.)
		
		recode enviro_vs_jobs (1=5)(2=4)(3=3)(4=2)(5=1)
		recode enviro_scale   (1=5)(2=4)(3=3)(4=2)(5=1)
		
		
		label var enviro_vs_jobs "\shortstack{Environment \\ vs jobs}"
	    label var enviro_scale "\shortstack{Climate \\ change \\ concerns}"
		label var immig_border "\shortstack{Increase \\ border \\ security ($\times$-1)}"
		label var immig_legalize "\shortstack{Legalize \\ immigrants}"
		label var guns_assaultban "\shortstack{Ban \\ assault \\ weapons}"
		label var guns_permits "\shortstack{Ease \\ concealed-carry \\ permits}"
		label var abortion_20weeks "\shortstack{Ban \\ abortions \\ after 20th week ($\times$-1)}"
		label var abortion_always "\shortstack{Always \\ allow \\ abortions}"
		
		
		
			cap drop z*
			zscore RTGFXNC
			zscore RTGMSNBC 

			zscore lineupFXNC
			zscore lineupMSNBC
		
		
			label var z_lineupFXNC "Fox News position (std)"
			label var z_lineupMSNBC "MSNBC position (std)"
			label var z_RTGFXNC    "Fox News rating (std)"
			label var z_RTGMSNBC   "MSNBC rating (std)"
								

	save "$replicationdir/02_data/main_analysis.dta", replace
			
			

		
	