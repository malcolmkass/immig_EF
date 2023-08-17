*controls and data cleaning
*dofile for cleaning controls for immig/econ free project, and now transfer to git hub
*2023 Fall	
clear  all                                
	set mem 1000m                           
	capture set maxvar 10000                         
	cd "C:\Users\mkass\OneDrive\Documents\GitHub\immig_EF"
	set logtype text
	capture log close
	log using controls1.log, replace
	set more off
	version 13

cap net set ado "C:\ado\personal"
adopath + "C:\ado\personal"

/*from a file that explains how to make nice graphs.
https://medium.com/the-stata-guide/stata-and-github-integration-8c87ddf9784a
*/

ssc install schemepack, replace
set scheme black_w3d
graph set window fontface "Arial Narrow"

*fave packages (may not be important)
*run "C:\Users\mkass\IT (30) Advanced Dropbox\Malcolm Kass\Research\Immigration_EF_Nazmul\datafiles\csv_files\kass_packages.do"

***************************************************************************************************************************
*business dynamics
clear
*import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\bds2020_states.xlsx", sheet("bds2020_states_full") firstrow clear
import delimited "C:\Users\mkass\OneDrive\Documents\GitHub\immig_EF\bds2020_states_full.csv", clear 


/*so I an dropping many varialbes.  I decided that looking at job gains and losses isn't as ideal as establishment firms and losses
and the rate metrics, to develop my own my changing my dataset*/

drop estabs_entry_rate estabs_exit_rate job_creation_rate_births job_creation_rate job_destruction_rate_deaths net_job_creation_rate job_destruction_rate ///
firmdeath_firms firmdeath_estabs firmdeath_emp reallocation_rate emp job_creation job_creation_births job_creation_continuers job_destruction ///
job_destruction_deaths job_destruction_continuers net_job_creation denom 

sort state_id year
drop if year < 1980

cap drop decennial
gen decennial = 4 
replace decennial = 3 if year <= 2010
replace decennial = 2 if year <= 2000
replace decennial = 1 if year <= 1990

*setting up varaibles for increments in 10 years
bysort state_id decennial: egen estabs_entry_ten = sum(estabs_entry)
bysort state_id decennial: egen estabs_exit_ten = sum(estabs_exit)
la var firms "No. of firms for that specific year"
la var estabs "no. of establishments for that year (think multiple plants per firm)"
la var estabs_entry_ten "A count of establishments born over the previous 10 years"
la var estabs_exit_ten "A count of establishments exiting over the previous 10 years"

*now removing middle years
keep if (year == 1990 | year == 2000 | year == 2010 | year == 2020 )

replace year = 2019 if year == 2020

*creating rates for our varaibles
xtset state_id decennial
cap drop estabs_entry_rate_ten
cap drop estabs_exit_rate_ten
gen estabs_entry_rate_ten = 2*(estabs_entry_ten - l.estabs_entry_ten)/(estabs_entry_ten + l.estabs_entry_ten)
gen estabs_exit_rate_ten = 2*(estabs_exit_ten - l.estabs_exit_ten)/(estabs_exit_ten + l.estabs_exit_ten)
la var estabs_entry_rate_ten "average percent change of establishments born"
la var estabs_exit_rate_ten "average percent change of establishments exited"

rename state_name state


save bus_dynamics.dta, replace



***************************************************************************************************************************
*urban percentage
*import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\pop-urban-pct-historical_partial_clean.xls", sheet("States") firstrow clear
import delimited "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\csv files\pop-urban-pct-historical_partial_clean.csv", clear

reshape long y, i(state) j(year)
rename y urban_pct
drop if year == 2010
save urban_pct.dta, replace

*import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\State_Urban_Rural_Pop_2020_2010_census.xlsx", sheet("States") firstrow clear
import delimited "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\csv files\State_Urban_Rural_Pop_2020_2010_census.csv", clear

rename statename state
rename pctruralpop y2019
rename k y2010
drop statefp stateabbrev totalpop urbanpop ruralpop i j l m n
drop if state == "American Samoa" 
drop if state == "Guam" 
drop if state == "Commonwealth of the Northern Marianas" 
drop if state == "Puerto Rico" 
drop if state == "US Virgin Islands"
drop in 52/2832
gen state_id = _n
reshape long y, i(state) j(year) 
rename y urban_pct

merge 1:n state year using urban_pct.dta
drop _merge
sort state year

la var urban_pct "est. urban percentage by state"

save urban_pct.dta, replace


/*note 1990 and 2000 data, this comes from the Urban Percentage of the Population for Counties, Historical Decennial Census, 1900-2010 U.S. Census Bureau
https://www.icip.iastate.edu/tables/population/urban-pct-states
note, we do not have 2020 data for this variable as of sept 2022 because it hasn't been released yet, per the decential censuskey
https://www2.census.gov/geo/pdfs/reference/ua/2020_Urban_Areas_FAQs.pdf

2010 and 2020 state level urban percentages from here
https://www.census.gov/programs-surveys/geography/guidance/geo-areas/urban-rural.html
*/


/*use use the state_area.dta
https://www.census.gov/geographies/reference-files/2010/geo/state-area.html
*/
clear
*import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\state_area.xlsx", sheet("Sheet1") firstrow
import delimited "C:\Users\mkass\IT (30) Advanced Dropbox\Malcolm Kass\Research\Immigration_EF_Nazmul\datafiles\csv files\state_area.csv", clear
save state_area.dta, replace

clear
*import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\Freedom_In_The_50_States_2022_kassedit.xlsx", sheet("Personal") firstrow clear
import delimited "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\csv files\Freedom_In_The_50_States_2022_kassedit.csv", clear 
*rename Year year
*rename State state
la var personalfreedom "pers. freedom score from Cato"
save state_persfreedom.dta, replace
*use state_persfreedom.dta, replace
/*freedom in the 50 states. this include personal freedoms form the Cato institute
https://www.freedominthe50states.org/data
Note: Personal tab contains overall and individual freedoms.  
abortion freedom index is monotonic in lesser abortion freedoms, so high numbers are state with resticted freedoms.
see the overall tab and the instructions tab for more info
no state_id, so with construcing dataset, need to match on state and year vs. state id
*/

log close

exit



clear
import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\bea_employ_data.xlsx", sheet("bls_nonfarm_total") firstrow clear
reshape long y, i(state_id) j(year) 
rename y tot_employ
la var tot_employ "Total Employed individuals per state in thousands"
save state_employed.dta, replace
import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\bea_employ_data.xlsx", sheet("bls_nonfarm_private") firstrow clear
reshape long y, i(state_id) j(year) 
rename y private_employ
la var private_employ "Private sector employed individuals per state in thousands"
merge 1:1 state_id year using state_employed.dta
drop _merge
save state_employed.dta, replace
*this is from the BLS_Data_Series*/


**********************************************************************************
*BEA data

/*here, I already retreived the data from the bea website:  
https://www.bea.gov/data/by-place-states-territories
and
https://apps.bea.gov/itable/iTable.cfm?ReqID=70&step=1&acrdn=1

*I have already aggregated this, but we may want to explore this further, see the links above.  Lastly, nothing is adjusted for inflation at any level, not even current prices*/
import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\BEA_pop_inc_state_1.xlsx", sheet("BEA_pop_inc_state") firstrow clear
rename GeoName state
sort LineCode state
drop if state == "Far West"
drop if state == "Great Lakes"
drop if state == "Mideast"
drop if state == "New England"
drop if state == "Plains"
drop if state == "Southeast"
drop if state == "Southwest"
drop if state == "Rocky Mountain"
sort LineCode state
gen temp = _n if LineCode == 1
bysort state: egen state_id = max(temp)
drop temp
reshape long y, i(state_id LineCode) j(year)
rename y demotemp
sort state_id  year LineCode
drop Description
reshape wide demotemp, i(state_id year) j(LineCode)
rename demotemp1 state_income_mil_nom
rename demotemp2 population
rename demotemp3 percapita_income_nom
la var state_income_mil_nom "state income in millions, nominal"
la var population "population"
la var percapita_income_nom "per capital income in $$$, nominal"
/*more info from this data/2015/acs/acs5/groups/Legend / Footnotes:																																																																																																
1/ Census Bureau midyear population estimate. BEA produced intercensal annual state population statistics for 2010 to 2019 that are tied to the Census Bureau decennial counts for 2010 and 2020. BEA developed intercensal population statistics because this data was not published when Census released state population data for 2020 and 2021, which are based on the 2020 decennial counts. BEA used the Census Bureau Das Gupta method (see https://www2.census.gov/programs-surveys/popest/technical-documentation/methodology/intercensal/2000-2010-intercensal-estimates-methodology.pdf), modified to account for an extra leap year day, to produce the intercensal population figures that will be used until Census releases its official intercensal population data.																																																																																																
2/ Per capita personal income is total personal income divided by total midyear population. BEA produced intercensal population figures for 2010 to 2019 that are tied to the Census Bureau decennial counts for 2010 and 2020 to create consistent time series that are used to prepare per capita personal income statistics. BEA used the Census Bureau Das Gupta method (see https://www2.census.gov/programs-surveys/popest/technical-documentation/methodology/intercensal/2000-2010-intercensal-estimates-methodology.pdf), modified to account for an extra leap year day, to produce the intercensal population figures that will be used until Census releases its official intercensal population data.																																																																																																
* Estimates prior to 1950 are not available for Alaska and Hawaii.																																																																																																
Note. All dollar estimates are in millions of current dollars (not adjusted for inflation). Calculations are performed on unrounded data.																																																																																																
(NA) Not available.																																																																																																
Last updated: September 30, 2022--revised statistics for 2017-2021.*/																																																																																																
save bea_stuff.dta, replace 

/*CPI numbers
Series Title:	All items in U.S. city average, all urban consumers, seasonally adjusted				
Area:	U.S. city average				
Item:	All items				
Base Period:	1982-84=100				
Years:	1947 to 2022				*/

import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\cpi_kass.xlsx", sheet("BLS Data Series") firstrow clear
rename Year year
merge 1:m year using bea_stuff.dta
drop _merge

save bea_stuff.dta, replace 

*****************************************************************************
/*dependent varaible.  Here from the Pew research center, description of data.  

https://www.pewresearch.org/hispanic/wp-content/uploads/sites/5/2019/03/Pew-Research-Center_2018-11-27_U-S-Unauthorized-Immigrants-Total-Dips_Updated-2019-06-25.pdf

Combo of american community survey and Homeland security's Office of Immigration Statistics...

The estimates for the U.S. unauthorized immigrant population presented in this report are based on a residual estimation methodology that compares a demographic estimate of the number of immigrants residing legally in the country with the total number of immigrants as measured by either the American Community Survey or the March Supplement to the Current Population Survey. The difference is assumed to be the number of unauthorized immigrants in the survey, a number that later is adjusted for omissions from the survey (see below). 

The basic estimate is: 

Unauthorized Immigrants = Foreign Born - Immigrant Population  

The lawful resident immigrant population is estimated by applying demographic methods to counts of lawful admissions covering the period since 1980 obtained from the Department of Homeland Security's Office of Immigration Statistics and its predecessor at the Immigration and Naturalization Service, with projections to current years, when necessary. Initial estimates here are calculated separately for age-gender groups in six states (California, Florida, Illinois, New Jersey, New York and Texas) and the balance of the country; within these areas the estimates are further subdivided into immigrant populations from 35 countries or groups of countries by period of arrival in the United States.*/

clear
import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\foreign_kass.xlsx", sheet("clean") firstrow
sort state year


la var foreign_full_born_pew "Total foreign born individuals in the state, latest is from 2018"
la var foreign_pct_overall_pew "fraction of foreign born relative to total state population, latest is from 2018"
la var unauthorized_k_pew "Total undocumented workers in k, rounded to nearest k, latest is from 2016, Pew"
la var majority_unauthorized_mexico "if the state's undocumented immigrants were from Mexico, binary"



/*the next few variable come from the Center for Migration Statistics, from his link

http://data.cmsny.org/state.html

Here, what is listed as 2018 is actually 2019 */


la var unauthorized_cms "Total undocumented workers from the CMS, latest is from 2019"
la var unauthorized_cms_entry "Incoming undocumented workers, from 2010 to 2019, CMS data"

la var eligible_naturalize_total_cms "Total authorized workers from the CMS, latest is from 2019"
la var eligible_naturalize_cms_entry "Incoming authorized workers, from 2010 to 2019, CMS data"

*note, authorized means authorized immigrants, but not naturalized
*note, for the immigration data, eventhing is listed as 2018, but the actual year may be different.  See the data labels

/*Lastly, the Migration Policy institute, here the 2018 data is from 2019

Data from these sites
https://www.migrationpolicy.org/programs/us-immigration-policy-program-data-hub/unauthorized-immigrant-population-profiles
https://www.migrationpolicy.org/programs/data-hub/state-immigration-data-profiles

And the methodology from here
https://www.migrationpolicy.org/about/mpi-methodology-assigning-legal-status-noncitizens-census-data
*/

la var foreign_citizen_mpi "total foreign-born citizens, migration policy institute"
la var foreign_noncitizen_mpi "Total foreign born non-citizens"
la var foreign_pct_female_mpi "Percent foreign born female"
la var unauthorized_mpi "Total unauthorized immigrants, rounded to nearest 1000s"
la var unauthorized_female_pct_mpi "Percent unauthorized that are female"
la var unauthorized_latin_pct_mpi "Percent unauthorized that are from Mexico or Latin America"


save foreign_kass.dta, replace


******************************************************************************
*econ freedom work

clear

import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\Econ_free_labor.xlsx", sheet("overall_labor") firstrow 
reshape long y, i(state) j(year) 
rename y  labor_score
la var labor_score "average of 3 labor freedom component rankings"
save labor_score.dta, replace
clear

import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\Econ_free_labor.xlsx", sheet("labor_minwage") firstrow 
reshape long y, i(state) j(year) 
rename y  minwage_fracinc
la var minwage_fracinc "Full-time Minimum Wage Income as a Percentage of Per Capita Income"
save minwage_fracinc.dta, replace
clear

import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\Econ_free_labor.xlsx", sheet("labor_fracgovtemploy") firstrow 
reshape long y, i(state) j(year) 
rename y  fracgovtemploy
la var fracgovtemploy "Government Employment as a Percentage of Total State/Provincial Employment"
save fracgovtemploy.dta, replace
clear

import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\Econ_free_labor.xlsx", sheet("labor_uniondensity") firstrow 
reshape long y, i(state) j(year) 
rename y  uniondensity
la var uniondensity "Union Density, percentage of union employees relative to all employees"
save uniondensity.dta, replace
clear

import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\Econ_free_labor.xlsx", sheet("overall_govt_spend") firstrow 
reshape long y, i(state) j(year) 
rename y  govt_spend_score
la var govt_spend_score "average of 3 govt spending component rankings"
save gov_spend_score.dta, replace
clear

import excel "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\Econ_free_labor.xlsx", sheet("overall_tax") firstrow 
reshape long y, i(state) j(year) 
rename y  tax_score
la var tax_score "average of 4 taxiation component rankings"
save tax_score.dta, replace
clear

*merging econ_free_labor
use labor_score.dta
merge 1:1 state year using minwage_fracinc.dta
drop _merge
merge 1:1 state year using fracgovtemploy.dta
drop _merge
merge 1:1 state year using uniondensity.dta
drop _merge
merge 1:1 state year using tax_score.dta
drop _merge
merge 1:1 state year using gov_spend_score.dta
drop _merge
label var state "state"
la var year "year"
sort state year
save econ_free_labor.dta, replace

*****************************************************************************
/*Heating days (to account for people who hate the cold more than hate 
the heat)  Methodology here

https://www.weather.gov/key/climate_heat_cool
https://ftp.cpc.ncep.noaa.gov/htdocs/degree_days/weighted/daily_data/2010/
*/

import delimited "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\heatingdays.txt", clear 
la var heatdays "number of heating days"
save heatdays.dta, replace

*****************************************************************************
*cost of Living index

/* this is from the world pop. review, 2022 data

https://worldpopulationreview.com/state-rankings/cost-of-living-index-by-state

but this stems from the ACCRA

http://c2c.coli.org/compare.asp?action=methodology */

import delimited "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\costliving2022.csv", clear 
la var costindex "ACCRA 2022 cost of living index"
cap rename ïstate_id state_id
save costindex.dta, replace

*****************************************************************************
*State level education performance. 

/* Here, we are looking at data from the national assessment of education progress, the state level report cards. 

https://nces.ed.gov/nationsreportcard/assessments/
https://www.nagb.gov/naep-subject-areas/mathematics.html

SOURCE: U.S. Department of Education, Institute of Education Sciences, National Center for Education Statistics, National Assessment of Educational Progress (NAEP), 1992 Mathematics Assessment.							


Here, we have average scores, percentiles above basic, percentiles above proficient.  Seperated out by topic?
*/

import delimited "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\datafiles\EducTestScores.csv", clear 

la var avescore_math "NAEP average math score"
la var atbasic_math	"NAEP percent above basic math score"
la var atproficient_math "NAEP percent above proficient math score"
la var avescore_read "NAEP average read score"
la var atbasic_read	"NAEP percent above basic read score"
la var atproficient_read "NAEP percent above proficient read score"

save eductestscores.dta, replace




*****************************************************************************
*aggregating everything...

*Merging the seperate parts
use foreign_kass.dta, replace 

merge 1:1 state_id year using econ_free_labor.dta
drop _merge

merge 1:1 state_id year using bus_dynamics.dta
drop _merge

merge 1:1 state_id year using urban_pct.dta
drop _merge

merge m:1 state_id using state_area.dta
drop _merge

merge 1:1 state_id year using state_employed.dta
drop _merge

merge 1:1 state_id year using bea_stuff.dta
drop _merge

merge 1:1 state_id year using heatdays.dta
drop _merge

merge 1:1 state_id year using eductestscores.dta
drop _merge

merge 1:1 state_id year using state_persfreedom.dta
drop _merge

merge m:1 state_id using costindex.dta
drop _merge

*****************************************
gsort year state_id

/*some cleanup*/
replace heatdays = 4744 in 3389
replace contus = 1 in 3389
replace heatdays = 5472 in 2927
replace contus = 1 in 2927
replace heatdays = 5472 in 2414
replace contus = 1 in 2414
replace heatdays = 5472 in 1901
replace contus = 1 in 1901

drop if state_id == 59

/*here the key years are 2019, 2010, 2000, 1990, and even then there are a number of missing years.*/ 

keep if (year==1990 | year == 2000 | year == 2010 | year == 2019) & state_id != 9

/*Some key notes...
- we only have resonably complete data from 1990, 2000, 2010, 2019.  This should be data from all 50 states. (note that Washington DC state_id = 9, So this is ignored)
- our immigration variable is only capturing immigration overall to these states, and not the undocumented working migration that we hope to move with later.  
- using the form of immigration from Card 2016
*/

***********************************************************
*setting up the panel structure

*first, we need to get the data in a structure that we can handle. 
cap drop temp_pew
gen temp_pew = 1 if year == 1990
replace temp_pew = 2 if year == 2000
replace temp_pew = 3 if year == 2010
replace temp_pew = 4 if year == 2019
la var temp_pew "time variable for using the pew data"

cap drop temp_cms
gen temp_cms = 1 if year == 2000
replace temp_cms = 2 if year == 2010
replace temp_cms = 3 if year == 2019
la var temp_pew "time variable for using the Center Migration Studies data"

***********************************************************
/*Now the dependent varaible, here is the list we will use...*/
*a bit more clean up
gsort year state_id
replace foreign_pct_female_mpi = 52.5 in 158
replace unauthorized_latin_pct_mpi = 77 in 192

save ef_immig_data_modified, replace

************************************************************
*lastly, so backfill an unauthorized number of 2000 from the CMS data use the data from unauthorized entry
xtset state_id temp_cms
replace unauthorized_cms = f.unauthorized_cms + f.unauthorized_cms_entry if year == 2000
/*so this is hella wrong, but hopefully wrong in a way that is not correlated with economic freedom*/


saveold "C:\Users\mkass\Dropbox (IT (30) Advanced)\Research\Immigration_EF_Nazmul\ef_immig_data_v2.dta", replace version(13)


*now to properly setup our key variables. 
***************************************************************

gsort year state_id

**************************************************************************************
**************************************************************************************
**************************************************************************************
**********************************************************
*First a review of the dependent variables forms we have.

/*for the unauthorized immigrants.  Pew and CMS data.  Not enought datapoints to use the MPI unauthorized immigrant data.  
unauthorized_k_pew "Total undocumented workers in thousands, latest is from 2016, Pew"
majority_unauthorized_mexico "if the state's undocumented immigrants were from Mexico, binary"

*Center for Migration Statistics, much more spotty data
unauthorized_cms "Total undocumented workers from the CMS, latest is from 2019", only have 2010 and 2019 data
unauthorized_cms_entry "Incoming undocumented workers, from 2010 to 2019, CMS data", imcoming undocumented from 2010 to 2019

There are others, but I do not thik these are going to be worth our time to mess with
*/

**********************************************************
/*now some Card 2016 adjustments to the data. (If we are get away with First differencing, then this should work A-OK, 
but at the conference, I was told we need to double lag the DV to account for potential endogenity concerns.  Need to double check
the "Grecian Horse" Alexandre Padilla paper and Wooldrige to see if first differnencing is enough.  Last I looked at the Padilla paper, that
is what he used for his strategy, along with GMM and a shift share instrument.  We should look up that paper again.)*/

sort state_id temp_pew
xtset state_id temp_pew
gen native_pew = population - foreign_full_born_pew
la var native_pew "population of native born people in a state (no foreign born citizens)"
*first, the immigration inflow from Card et al
gen immig_inflow_unau_pew = 1000*(unauthorized_k_pew - l.unauthorized_k_pew)/l.native_pew
la var immig_inflow_unau_pew "Card inflow variable, FD in unauthorized over lag of native born people"

*now the Card 2016 form of the DV from the CMS and the MPI
gen native_cms = population - (unauthorized_cms + eligible_naturalize_total_cms + foreign_citizen_mpi)
gen immig_inflow_unau_cms = (unauthorized_cms - l.unauthorized_cms)/l.native_cms
*probably not used

*Note, that the lower end of the immigration totals for the CMS data is just either not given, or just rounded. 
*********************************************************************************
*********************************************************************************
*********************************************************************************
*stardard DV for immigration variables
gen immig_unau_pew = 1000*unauthorized_k_pew/population
la var immig_unau_pew "fraction of unauthorized over state population"
gen immig_unau_cms = unauthorized_cms/population


*********************************************************************************
*manually stardardize variables. First are the dependent varaibles, then the varaibles of interest
*immigration inflow
egen zimmig_inflow_unau_pew = std(immig_inflow_unau_pew) 
la var zimmig_inflow_unau_pew "z score of immig_inflow_unau_pew"
egen zimmig_inflow_unau_cms = std(immig_inflow_unau_cms) 

*stardard immigration variable
egen zimmig_unau_pew = std(immig_unau_pew)
la var zimmig_unau_pew "z score of immig_unau_pew"
egen zimmig_unau_cms = std(immig_unau_cms)



**************************************************************************************
*variable of interest:  State level economic freedom
egen zlaborscore = std(labor_score) 
egen zminwage = std(minwage_fracinc) 
egen zfracgov = std(fracgovtemploy) 
egen zunion = std(uniondensity) 
egen ztaxscore = std(tax_score)
egen zgovt_spend_score = std(govt_spend_score)

************************************************************************************
*Controls:  We need to conduct a LASSO Analysis on this to see what are good variables here
gen frac_priv_employ = private_employ/population
la var frac_priv_employ "fraction of private employment with respect to population"
egen zurban = std(urban_pct)
egen zPersonalFreedom = std(PERSONALFREEDOM)
egen zcostindex = std(costindex)
egen zheatdays = std(heatdays)
gen lpop = log(population)
gen linc_state = log(state_income_mil_nom/CPI_U)
la var linc_state "log of REAL income for each state"
egen zlinc_pers = std(log(percapita_income_nom/CPI_U))
la var linc_state "log of REAL income per capita in each state-area"
gen lpemploy = log(private_employ)
la var lpemploy "log of private employment"
gen school = avescore_math + avescore_read 
la var school "sum of schooling averages"



*First, lets look at full economic freedom, first a temp variable (as of Jan 2023)
cap drop zef_temp
egen zef_temp = std(labor_score + tax_score + govt_spend_score)

drop unauthorized_cms unauthorized_cms_entry eligible_naturalize_total_cms eligible_naturalize_cms_entry foreign_citizen_mpi foreign_noncitizen_mpi foreign_pct_female_mpi unauthorized_mpi unauthorized_female_pct_mpi unauthorized_latin_pct_mpi GunRights AlcoholFreedom CannabisFreedom TravelFreedom GamingFreedom Malumprohibitum EducationalFreedom AssetForfeiture IncarcerationandArrests MarriageFreedom CampaignFinanceFreedom grocerycost housingcost utilitiescost transportationcost misccost native_cms immig_inflow_unau_cms immig_unau_cms zimmig_inflow_unau_cms zimmig_unau_cms TobaccoFreedom

gen south = 1 if (state_id == 3 | state_id == 5 | state_id == 32 | state_id == 44 )
la var south "border state"

gsort year state_id
save ef_immig_data_v5.dta, replace

*just cleaning the data now, mainly dropping the individual variable and the data from the mpi and the cms (not used)


log off





