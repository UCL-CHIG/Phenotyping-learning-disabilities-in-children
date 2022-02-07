*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 3 - merge all information and create a study cohort with risk factors (one row per baby)
* Date created: June 2021
*
*********************************************************************************************

*********************************************************************************************
* this do-file combines information derived in previous do-files
* to create a study cohort with one row per child and all risk factors
********************************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."



*********************** load the cohort ************************
use "${filepath3}inception cohort clean May 2021.dta", clear


***************** drop non-English residents *******************
merge 1:1 encrypted_hesid using  "${filepath3}\non English res.dta"
drop if _merge==3
drop _merge

save "${filepath3}inception cohort clean May 2021 with RF.dta", replace



***************** add information on ethnicity *******************
use "${filepath3}\ethnic group completed per child and admission.dta", clear

keep encrypted_hesid ethnos_compl
duplicates drop *, force

merge 1:1 encrypted_hesid using "${filepath3}inception cohort clean May 2021 with RF.dta"
drop if _merge==1
drop _merge

tab ethnos_compl, mi

save "${filepath3}inception cohort clean May 2021 with RF.dta", replace



***************** add information on residence *******************
merge 1:1 encrypted_hesid using "${filepath3}region residence info short.dta"
drop _merge

codebook resgor*
replace resgor_adm = resgor_9 if resgor_adm==.   
drop resgor_9

replace resgor_adm = resgor_all2 if resgor_adm==.   
replace resgor_adm = resgor_all if resgor_adm==.  

tab resgor_adm, mi

drop resgor_all2
save "${filepath3}inception cohort clean May 2021 with RF.dta", replace



***************** add information on IMD *******************
merge 1:1 encrypted_hesid using "${filepath3}IMD info short.dta"
drop if _merge==2
drop _merge

codebook imd*

replace imd04rk_adm = imd04rk_9 if imd04rk_adm==.   
drop imd04rk_9

replace imd04rk_adm = imd04rk_all2 if imd04rk_adm==.  
replace imd04rk_adm = imd04rk_all if imd04rk_adm==.

drop imd04rk_all2

***** further data cleaning
recode imd04rk_adm 1/6496=1 6497/12993=2 12994/19489=3 19490/25986=4 25986/32482=5, gen (imd_quint)
label define imd_quint 1 "Q1: Most deprived 20%" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5: Least deprived 20%" 
label val imd_quint imd_quint
tab imd_quint, mi

save "${filepath3}inception cohort clean May 2021 with RF.dta", replace


***************** merge in chronic conditions
merge 1:1 encrypted_hesid using "${filepath3}\chronic conditions for the inception cohort Dec 2020.dta"

drop if _merge==2
drop _merge

capture drop any_cond
gen any_cond=0
replace any_cond=1 if ld==1 | asd==1 | high_risk==1 | associated==1

foreach var of varlist cc_* nr_cond {
	replace `var'=0 if `var'==.
	}
	
save "${filepath3}inception cohort clean May 2021 with RF.dta", replace


capture drop ageatdeath
gen ageatdeath = int( (dod-bday)/365.25 )
tab ageatdeath, mi

capture drop nr_cond2
gen nr_cond2 =  cc_group2 + cc_group3 + cc_group4 + cc_group5 + cc_group6  + cc_group8 + cc_group10

save "${filepath3}inception cohort clean May 2021 with RF.dta", replace



************* sex data *****************
use "${filepath3}ld hospital records clean v1.dta", clear
keep encrypted_hesid sex
duplicates drop *, force
duplicates tag encrypted_hesid, gen(tag)
tab tag
drop tag
merge 1:1 encrypted_hesid using "${filepath3}inception cohort clean May 2021 with RF.dta"

drop if _merge==1
drop _merge

save "${filepath3}inception cohort clean May 2021 with RF.dta", replace


*************** final checks
tab resgor_adm, mi 
replace resgor_adm=2 if resgor_adm==3
drop if resgor_adm>10 & resgor_adm!=.
drop non_eng

drop *_date
drop any_cond

save "${filepath3}inception cohort clean May 2021 with RF.dta", replace



*************** save updated info on IDs in inception cohort to exclude
* non-English residents from hosp records in next do-file *************
keep encrypted_hesid
duplicates drop *, force
save "${filepath3}inception cohort IDs exc non-Eng.dta", replace

