*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 2 - additional cleaning & derivation of "clean" variables form hospital
*						records for young people in study cohort
* Date created: June 2021
*
*********************************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."


******************************************************************************
* This do-file will save hosp records for revised study cohort (1990-2001)
* and derive additional risk factors from hospital records
******************************************************************************


******************************************************************************
* Save hosp records for revised study cohort (1990-2001)
******************************************************************************

use "${filepath3}inception cohort IDs.dta"


******* look at hospital records now & link in cohort info
merge 1:m encrypted_hesid using "${filepath}ld hospital records clean v1.dta"
keep if _merge==3
drop _merge


******** merge in deaths
merge m:1 encrypted_hesid using "${filepath}LD deaths clean v1.dta"
drop if _merge==2
drop _merge

******** drop unneccesary variables
drop disdest dismeth epiorder gortreat hatreat pcttreat  rururb_ind procode3 admincat endage   gpprac imd04rk imd04_decile 
drop subsequent_activity match_rank dor cause_of* age_at_death 
drop death_record_used

rename dob_full bday


******** drop data before 1997
capture drop calyr
gen calyr=year(admd)
tab calyr, mi

drop if calyr<1998
drop if calyr>2018


********* drop those born before 1990 or after 2002
capture drop ydob
gen ydob=year(bday)
tab ydob, mi
* we want to look coding more long term


********** check age
gen age = int((admd-bday)/365.25 )
tab age, mi

drop if age>24

save "${filepath3}ld hospital records clean v1.dta", replace



******************************************************************************
* Derive extra clean variables from hospital records  
******************************************************************************

**** this now already has only cohort info:
use "${filepath3}ld hospital records clean v1.dta", clear


************* ethnicity data *****************
tab ethnos, mi

capture drop ethnos_clean
gen ethnos_clean=.
replace ethnos_clean=0 if ethnos=="0"|ethnos=="A"|ethnos=="B"|ethnos=="C"  /*white*/
replace ethnos_clean=1 if ethnos=="1" |ethnos=="M"  /*Black Carribbean */
replace ethnos_clean=2 if ethnos=="2" | ethnos=="N"  /*Black Carribbean */
replace ethnos_clean=3 if ethnos=="3" | ethnos=="P"  /*Black Other */
replace ethnos_clean=4 if ethnos=="4" | ethnos=="H"  /* Indian */
replace ethnos_clean=5 if ethnos=="5" | ethnos=="J"  /* Pakistani */
replace ethnos_clean=6 if ethnos=="6" | ethnos=="K"  /* Bangladeshi */
replace ethnos_clean=7 if ethnos=="7" | ethnos=="R"  /* Chinese */
replace ethnos_clean=8 if ethnos=="8" | ethnos=="S" | ethnos=="D" | ethnos=="E" | ethnos=="F" | ethnos=="G" |ethnos=="L"      /* Any other */

tab ethnos_clean, mi
label def ethnic_gr 0 "White" 1 "Black - Caribbean" 2 "Black - African" 3 "Black - Other" 4 "Indian" 5 "Pakistani" 6 "Bangladeshi" 7 "Chinese" 8 "Any other ethnic group"
label val ethnos_clean ethnic_gr

**** we want to take modes of recorded values
tab ethnos_clean, mi
drop if ethnos_clean==.

keep encrypted_hesid ethnos_clean ethnos adm_no episode_no2 admd 
duplicates drop *, force

bysort encrypted_hesid adm_no: egen ethnos_adm=mode(ethnos_clean)  /*Check if all episodes for each ID have same ethnic group*/

* drop episode_no and run per child in all admissions
keep encrypted_hesid ethnos_clean ethnos adm_no episode_no2 admd ethnos_adm
duplicates drop *, force

* now take the mode over the whole hospital record - include ethnicity recorded in each epiosde as sometimes that varies (probably depending on who was recording info?)
bysort encrypted_hesid: egen ethnos_compl=mode(ethnos_clean) 

label val  ethnos_compl ethnic_gr
label val  ethnos_adm ethnic_gr

rename ethnos ethnos_orig
label var ethnos_orig "Original ethnicity"

label var ethnos_adm "Ethnicity - mode per admission"
label var ethnos_compl "Ethnicity - mode per child"

tab ethnos_compl, mi
tab ethnos_adm, mi

save "${filepath3}\ethnic group completed per child and admission.dta", replace



******************* REGION OF RESIDENCE **********************
use "${filepath3}ld hospital records clean v1.dta", clear

keep encrypted_hesid resgor* episode_no2  adm_no admd bday

gen age = int((admd-bday)/365.25 )
tab age, mi

drop resgor_compl
duplicates drop *, force
tab resgor, mi

**** drop missing values
replace resgor="" if resgor=="Y"
drop if resgor==""

**** from string to number
encode resgor, generate(resgor_tmp)
label define resgor_tmp 1 "North East" 2 "North West" 3 "Merseyside" 4 "Yorkshire and Humber" 5 "East Midlands" 6 "West Midlands" 7 "East of England" 8 "Londond" 9 "South East" 10 "South West" 11 "Scotland" 12 "No fixed abode" 13 "Wales" 14 "Foreign" 15 "Northern Ireland", replace
label val  resgor_tmp resgor_tmp


**** derive mode per admission
bysort encrypted_hesid adm_no: egen resgor_compl=mode(resgor_tmp)
label val resgor_compl resgor_tmp
tab resgor_compl, mi
rename resgor_compl resgor_adm

**** derive mode per age
bysort encrypted_hesid age: egen resgor_age=mode(resgor_tmp)

save "${filepath3}region residence info.dta", replace


****** indicate non-English residents (during study period)
use  "${filepath3}region residence info.dta", clear
keep if age>9 & age<25
tab age, mi
bysort encrypted_hesid: egen resgor_compl=mode(resgor_tmp)
label val resgor_compl resgor_tmp
tab resgor_compl, mi nolab
keep if resgor_compl!=. & resgor_compl>10
keep encrypted_hesid
duplicates drop * , force
gen non_eng=1
save  "${filepath3}\non English res.dta", replace

merge 1:m encrypted_hesid using  "${filepath3}region residence info.dta"
drop if _merge==3
drop _merge
drop non_eng
save "${filepath3}region residence info.dta", replace
 


******* derive region information
use  "${filepath3}region residence info.dta", clear

keep if age>9 & age<25
tab age, mi

sort encrypted_hesid adm_no episode_no2
bysort encrypted_hesid (adm_no episode_no2): keep if _n==1
keep encrypted_hesid resgor_adm
label variable resgor_adm "Region residence at first admission"
save "${filepath3}region residence info short.dta", replace

**** add region of residence at age 9
use  "${filepath3}region residence info.dta", clear
keep if age==9
keep encrypted_hesid resgor_age
duplicates drop *, force
duplicates tag encrypted_hesid, gen(tag)
tab tag
drop tag
rename resgor_age resgor_9
label var resgor_9 "Region of residence at age 9"
label val resgor_9 resgor_tmp
merge 1:1 encrypted_hesid using "${filepath3}region residence info short.dta"
drop _merge
save "${filepath3}region residence info short.dta", replace


**** add region of residence overall
use  "${filepath3}region residence info.dta", clear
bysort encrypted_hesid:  egen resgor_all=mode(resgor_tmp)
keep encrypted_hesid resgor_all
duplicates drop *, force
merge 1:1 encrypted_hesid using "${filepath3}region residence info short.dta"
drop _merge
save "${filepath3}region residence info short.dta", replace


**** add region of residence during study period
use  "${filepath3}region residence info.dta", clear
keep if age>9 & age<25
bysort encrypted_hesid:  egen resgor_all2=mode(resgor_tmp)
keep encrypted_hesid resgor_all2
duplicates drop *, force
merge 1:1 encrypted_hesid using "${filepath3}region residence info short.dta"
drop _merge

label var resgor_all "Region residence - all data"
label var resgor_all2 "Region residence - study FUP only"

label val resgor_all resgor_tmp
label val resgor_all2 resgor_tmp

keep encrypted_hesid resgor*
duplicates drop *, force
save "${filepath3}region residence info short.dta", replace




************* IMD data & region data *****************

use "${filepath3}ld hospital records clean v1.dta", clear

keep encrypted_hesid imd* episode_no2  adm_no admd bday

gen age = int((admd-bday)/365.25 )
tab age, mi

duplicates drop *, force

**** drop missing values
codebook imd*
drop imd04_decile_compl

****  mode per admission derived earlier
drop if imd04rk_compl==.

**** derive mode per age
bysort encrypted_hesid age: egen imd04rk_age=mode(imd04rk_compl)

rename imd04rk_compl imd04rk_adm

save "${filepath3}IMD info.dta", replace


****** IMD at first admission during study period
use  "${filepath3}IMD info.dta", clear
keep if age>9 & age<25
tab age, mi

sort encrypted_hesid adm_no episode_no2
bysort encrypted_hesid (adm_no episode_no2): keep if _n==1
keep encrypted_hesid imd04rk_adm
label variable imd04rk_adm "IMD at first admission"
save "${filepath3}IMD info short.dta", replace

**** IMD at age 9
use  "${filepath3}IMD info.dta", clear
keep if age==9
keep encrypted_hesid imd04rk_age
duplicates drop *, force
duplicates tag encrypted_hesid, gen(tag)
tab tag
drop tag
rename imd04rk_age imd04rk_9
label var imd04rk_9 "IMD at age 9"
merge 1:1 encrypted_hesid using "${filepath3}IMD info short.dta"
drop _merge
save "${filepath3}IMD info short.dta", replace


**** add IMD overall
use  "${filepath3}IMD info.dta", clear
bysort encrypted_hesid:  egen imd04rk_all=mode(imd04rk_adm)
keep encrypted_hesid imd04rk_all*
duplicates drop *, force
duplicates tag encrypted_hesid, gen(tag)
tab tag
drop tag
merge 1:1 encrypted_hesid using "${filepath3}IMD info short.dta"
drop _merge
save "${filepath3}IMD info short.dta", replace

**** add IMD overall in study period
use  "${filepath3}IMD info.dta", clear
keep if age>9 & age<25
bysort encrypted_hesid:  egen imd04rk_all2=mode(imd04rk_adm)
keep encrypted_hesid imd04rk_all*
duplicates drop *, force
duplicates tag encrypted_hesid, gen(tag)
tab tag
drop tag
merge 1:1 encrypted_hesid using "${filepath3}IMD info short.dta"
drop _merge
label var imd04rk_all "IMD - all data"
label var imd04rk_all2 "IMD - study FUP only"
save "${filepath3}IMD info short.dta", replace



