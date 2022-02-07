*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 8 - examining length of stay by age and trends over time in main reasons for ELECTIVE admissions
* Date created: June 2021
*
*********************************************************************************************

**************************************************************************
* this do-file covers code to derive crude numbers of admissions by main reason for ELECTIVE admission
* and stats of length of stay by age at admission
* note that these numbers are not adjusted for multilevel structure of data 
* (i.e. children having multiple admissions)
**************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."

use "${filepath3}ld hospital records transition cohort.dta", clear


****** add indicator of surgical vs not
foreach var of varlist opertn* {
replace `var'="" if substr(`var', 1, 1)=="U"
replace `var'="" if substr(`var', 1, 3)=="X28"
replace `var'="" if substr(`var', 1, 3)=="X29"
replace `var'="" if substr(`var', 1, 2)=="X3" | substr(`var', 1, 2)=="X4" | ///
	substr(`var', 1, 2)=="X5" | substr(`var', 1, 2)=="X6" | substr(`var', 1, 2)=="X7" | ///
	substr(`var', 1, 2)=="X8" | substr(`var', 1, 2)=="X9" | substr(`var', 1, 3)=="Y90" | ///
	substr(`var', 1, 3)=="R36" | 	substr(`var', 1, 3)=="R37" | 	substr(`var', 1, 3)=="R38" | ///
	substr(`var', 1, 3)=="R39" | 	substr(`var', 1, 2)=="R4"
}

* generate number of missing operations
capture drop tmp
egen tmp = rowmiss(opertn*)
tab tmp

* now it's the number of complete operations
replace tmp = 24-tmp
tab tmp

*** generate indicators - 1 if at least one procedure
* 0 - no procedures at all
capture drop surg_tmp
gen surg_tmp = 0
replace surg_tmp = 1 if tmp!=0
bysort encrypted_hesid admd: egen surgical2 = max(surg_tmp)
label var surgical2 "any recorded procedures excl selection"

tab surgical2, mi


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


**** only LD diagnoses
capture drop any_cond_ld
gen any_cond_ld=0
replace any_cond_ld=1 if ld==1 | associated==1 | high_risk==1
keep if any_cond_ld==1 | asd==1

replace asd=0 if any_cond_ld==1

* complete case
keep if sex!=. & imd_quint!=. 


***** respite care
capture drop z75
gen z75 = 0
replace z75=1 if strpos(diag_01, "Z755")>0


****** dental problems 
capture drop dental
gen dental = 0
replace dental=1 if strpos(diag_01, "K02")>0 | strpos(opertn_01, "F09")>0 | strpos(opertn_01, "F10")>0 


******* Other long term conditions
capture drop other_ltc
gen other_ltc=0
replace other_ltc=1 if substr(diag_01, 1,3)=="K50" |  substr(diag_01, 1,3)=="K51" | ///
	 substr(diag_01, 1,3)=="K52"

	 
***** other reason
capture drop other_reason
gen other_reason = 0
replace other_reason=1 if substr(diag_01, 1,2)=="N8" | substr(diag_01, 1,2)=="N9" | ///
	 substr(diag_01, 1,3)=="M20" |   substr(diag_01, 1,3)=="M21" |  substr(diag_01, 1,3)=="M22" |  ////
	 substr(diag_01, 1,3)=="M23" |  substr(diag_01, 1,3)=="M24" | substr(diag_01, 1,3)=="M25" |  ///
	 substr(diag_01, 1,2)=="M7" |  substr(diag_01, 1,2)=="N4" |  substr(diag_01, 1,3)=="N50" |  ///
	 substr(diag_01, 1,3)=="N51"   

	 
******** cerb_pals
tab cerb_pals
capture drop cerb_pals
gen cerb_pals = 0 
replace cerb_pals=1 if strpos(diag_01,"G80")>0 | strpos(diag_01,"G81")>0 | ///
		strpos(diag_01,"G82")>0 |  strpos(diag_01,"G83")>0



capture drop kidn_dis
gen kidn_dis = 0 
replace kidn_dis=1 if substr(diag_01, 1,3)=="N18" | substr(diag_01, 1,3)=="N17" | substr(diag_01, 1,3)=="N19"
tab kidn_dis dialysis, mi
replace kidn_dis=1 if dialysis==1


********* epilepsy
capture drop main_epilepsy
gen main_epilepsy=0
replace main_epilepsy=1 if strpos(diag_01,"F803")>0 | strpos(diag_01,"G400")>0 | strpos(diag_01,"G401")>0 | ///
	strpos(diag_01,"G402")>0 | strpos(diag_01,"G403")>0 | strpos(diag_01,"G404")>0 | ///
	strpos(diag_01,"G406")>0 | strpos(diag_01,"G407")>0 | strpos(diag_01,"G408")>0 | ///
	strpos(diag_01,"G409")>0 | strpos(diag_01,"G41")>0 | strpos(diag_01,"R568")>0 | ///
	strpos(diag_01,"Y460")>0 | strpos(diag_01,"Y461")>0 | strpos(diag_01,"Y462")>0 | ///
	strpos(diag_01,"Y463")>0 | strpos(diag_01,"Y464")>0 | strpos(diag_01,"Y465")>0 | strpos(diag_01,"Y466")>0  


**** unknown
gen r96 = 0
replace r96=1 if strpos(diag_01, "R69")>0


gen mental_health2=0
replace mental_health2=1 if  substr(diag_01, 1,2)=="F7" |  substr(diag_01, 1, 3)=="F84" 
	
	
capture drop tmp
gen tmp = substr(diag_01, 1, 3)

rename r96 r69

* keep only bare minimum info for now
keep encrypted_hesid bday adm_no admd disd elec_adm  main_epilepsy other_* mental_health*  other_reason preg_related injury elective emerg ld asd high_risk associated any_cond_ld startage nr_cond2  sex  cerb_pals z75 dental surgical2 kidn_dis r69

duplicates drop *, force	
	
duplicates tag encrypted_hesid adm_no, gen(tag)
tab tag


***** checks:
tab elec_adm, mi nolab

tab ydob elec_adm, mi
tab startage elec_adm, mi

* drop birth admissions and missing admission method
drop if  elec_adm==. |  elec_adm==3

tab preg_related sex

capture drop adm_type
gen adm_type = .
replace adm_type = 0 if elective==1 /* elective */
replace adm_type = 1 if emerg==1 /* emergency */
replace adm_type = 2 if preg_related ==1
replace adm_type = 3 if elec_adm ==2 /* maternity */

tab adm_type sex, mi

******** keep only those that were included as outcomes
keep if adm_type<2

* took out CC's
foreach var of varlist main_epilepsy other_* mental_health*  z75 dental surgical2 cerb_pals  kidn_dis r69 {
	rename `var' `var'_tmp
	replace `var'_tmp=0 if `var'_tmp==.
	bysort encrypted_hesid adm_no: egen `var' = max(`var'_tmp)
}

drop *_tmp

duplicates drop *, force

capture drop tag
duplicates tag encrypted_hesid adm_no, gen(tag)
tab tag, mi


******** keep only elective here
keep if elective==1
drop tag other_reason  preg_related injury


************ tabulations for the paper

preserve
keep if elective==1
*keep if any_cond_ld==1
keep if asd==1 & any_cond_ld!=1
tab startage dental , mi
tab startage kidn_dis, mi
tab startage other_ltc, mi
tab startage z75, mi
tab startage cerb_pals, mi
tab startage main_epilepsy, mi
tab startage mental_health2, mi
tab startage mental_health, mi
tab startage r69, mi
tab startage surgical2, mi
restore

preserve
keep if elective==1
keep if any_cond_ld==1
tab startage dental , mi
tab startage kidn_dis, mi
tab startage other_ltc, mi
tab startage z75, mi
tab startage cerb_pals, mi
tab startage main_epilepsy, mi
tab startage mental_health2, mi
tab startage mental_health, mi
tab startage r69, mi
tab startage surgical2, mi
restore



****************** length of stay ***************
global adm elective

gen length_adm = disd - admd

capture drop length_adm_sh
recode length_adm 0=0 1= 1 2/6=2 7/. = 3, gen(length_adm_sh)

tab startage length_adm_sh if ${adm}==1 & any_cond_ld==1, mi
tab startage length_adm_sh if ${adm}==1 & asd==1 & any_cond_ld!=1, mi

preserve
keep if any_cond_ld==1
tabstat length_adm if ${adm}==1 , by(startage) stat(mean sd)
tabstat length_adm if ${adm}==1 , by(startage) stat(p25 p50 p75)
tabstat length_adm if ${adm}==1 , by(startage) stat(min max p99)
restore

preserve
keep if asd==1  & any_cond_ld!=1
tabstat length_adm if ${adm}==1 , by(startage) stat(mean sd)
tabstat length_adm if ${adm}==1 , by(startage) stat(p25 p50 p75)
tabstat length_adm if ${adm}==1 , by(startage) stat(min max p99)
restore

