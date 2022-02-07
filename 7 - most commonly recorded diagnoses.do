*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 7 - getting most commonly recorded diagnoses
* Date created: June 2021
*
*********************************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."
use "${filepath3}ld hospital records transition cohort.dta", clear


merge m:1 encrypted_hesid using  "${filepath3}inception cohort clean May 2021 with RF.dta"
keep if _merge==3
drop _merge


**** only aged 10-24
gen startage2 = int( (admd-bday)/365.25 )
tab startage2, mi
drop if startage2>24
drop if startage2<10

drop startage

rename startage2 startage

tab ydob elective, mi

**** drop birth admissions and missing admission method
drop if  elec_adm==. |  elec_adm==3

capture drop any_cond_ld
gen any_cond_ld=0
replace any_cond_ld=1 if ld==1 | associated==1 | high_risk==1

keep if any_cond_ld==1 | asd==1


* complete case
keep if sex!=. & imd_quint!=. 


tab ydob elective if any_cond_ld==1,mi
tab startage elective if any_cond_ld==1,mi

* looks ok
tab startage elective if episode_no2==1, mi

keep encrypted_hesid bday diag_01 adm_no episode_no2 admd disd elec_adm diabetes asthma main_epilepsy other_ltc mental_health symptoms other_reason infection referal preg_related self_harm injury elective emerg ld asd high_risk associated cerb_pals any_cond_ld startage admidate 

foreach var of varlist diabetes asthma other_ltc mental_health symptoms other_reason infection main_epilepsy   {
	rename `var' `var'_tmp
	replace `var'_tmp=0 if `var'_tmp==.
	bysort encrypted_hesid adm_no: egen `var' = max(`var'_tmp)
}

drop *_tmp
drop episode_no2

duplicates drop *, force

capture drop tag
duplicates tag encrypted_hesid adm_no, gen(tag)
tab tag elective, mi
br encrypted_hesid diag_01 admidate admd if tag!=0

drop if strpos(diag_01, "R69")>0 & tag!=0
capture drop tag

gen z75 = 0
replace z75=1 if strpos(diag_01, "Z75")>0
tab diag_01 if z75==1

gen diag_sh = substr(diag_01, 1, 3)
drop diag_01
duplicates drop *, force

save "${filepath3}\summary of primary diagnoses.dta", replace




***************** save most common diags **********************
* this step needs to be repeated for each cohort & by type of admissions


use "${filepath3}\summary of primary diagnoses.dta", clear

******* choose elective or emergency admissions 
global adm_type emerg
* global adm_type elective

****** choose cohort of autistic young people or young people with learning disabilities
global cond any_cond_ld
*global cond asd
*replace asd=0 if any_cond_ld==1

keep if ${adm_type}==1
keep if ${cond}==1

recode startage 10/15=1 16/18=2 19/24=3, gen(age_cat)
drop startage
gen count=1

collapse (sum) count, by(age_cat diag_sh description)
gsort age_cat -count
gen count2 = -count
capture drop tmp
bysort age_cat (count2): gen tmp=_n
keep if tmp<=20
drop count2
reshape wide diag_sh description count, i(tmp) j(age_cat)
br

******* export results to excel
export excel using "${filepath3}data excel\most common primary diag desc.xlsx", sheet("${cond} ${adm_type}", replace) firstrow(variables) 

