*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 8a - examining length of stay by age and trends over time in main reasons for EMERGENCY admissions
* Date created: June 2021
*
*********************************************************************************************

**************************************************************************
* this do-file covers code to derive crude numbers of admissions by main reason for EMERGENCY admission
* and stats of length of stay by age at admission
* note that these numbers are not adjusted for multilevel structure of data 
* (i.e. children having multiple admissions)
**************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."


**** load hospital records
use "${filepath3}ld hospital records transition cohort.dta", clear


**** link to cohort
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

tab asd any_cond_ld, mi

* complete case
keep if sex!=. & imd_quint!=. 


******************** generate main reasons for diag categories ********************

******* symptoms as main reason
capture drop symptoms
gen symptoms = 0 
replace symptoms=1 if substr(diag_01, 1,2)=="R1" | substr(diag_01, 1,3)=="K59" | ///
	 substr(diag_01, 1,3)=="R50" |  substr(diag_01, 1,3)=="R51" | substr(diag_01, 1,3)=="R52" |  substr(diag_01, 1,3)=="R53" |  substr(diag_01, 1,3)=="R54" | substr(diag_01, 1,3)=="R55" | substr(diag_01, 1,3)=="R57" | substr(diag_01, 1,3)=="R58" |    substr(diag_01, 1,3)=="R59" |    ///
	 substr(diag_01, 1,4)=="R560" | /// 
	 substr(diag_01, 1,2)=="R6" |  ///
	 substr(diag_01, 1,2)=="R0" |  substr(diag_01, 1,2)=="R2" |  substr(diag_01, 1,2)=="R3" |  ///
	 substr(diag_01, 1,2)=="R4" |  substr(diag_01, 1,2)=="R7" |  substr(diag_01, 1,2)=="R8" |  substr(diag_01, 1,2)=="R9" 

capture drop tmp
gen tmp = substr(diag_01, 1, 3)
tab tmp if symptoms==1

capture drop injury
gen injury=0
replace injury=1 if strpos(tmp,"S")>0 | strpos(tmp,"T")>0  
tab injury, mi


capture drop diag_concat
gen diag_concat=diag_01 + "."+diag_02 + "." + diag_03 + "."+ diag_04 + "."+ diag_05 + "."+ diag_06 + "."+ diag_07 + "."+ diag_08 + "."+ diag_09 + "."+ diag_10 + "."+ diag_11 + "."+ diag_12 + "."+ diag_13 + "."+ diag_14 + "."+ diag_15 + "."+ diag_16 + "."+ diag_17 + "."+ diag_18 + "."+ diag_19 + "."+ diag_20+"."+ cause


capture drop self_harm
gen self_harm=0
replace self_harm=1 if strpos(diag_concat,"X6")>0 |  strpos(diag_concat,"X7")>0 | ///
	strpos(diag_concat,"X80")>0 |  strpos(diag_concat,"X81")>0 |  strpos(diag_concat,"X82")>0 | ///
	strpos(diag_concat,"X83")>0 |  strpos(diag_concat,"X84")>0 |  strpos(diag_concat,"Z915")>0  

tab self_harm injury, mi	


capture drop main_epilepsy
gen main_epilepsy=0
replace main_epilepsy=1 if strpos(diag_01,"F803")>0 | strpos(diag_01,"G400")>0 | strpos(diag_01,"G401")>0 | ///
	strpos(diag_01,"G402")>0 | strpos(diag_01,"G403")>0 | strpos(diag_01,"G404")>0 | ///
	strpos(diag_01,"G406")>0 | strpos(diag_01,"G407")>0 | strpos(diag_01,"G408")>0 | ///
	strpos(diag_01,"G409")>0 | strpos(diag_01,"G41")>0 | strpos(diag_01,"R568")>0 | ///
	strpos(diag_01,"Y460")>0 | strpos(diag_01,"Y461")>0 | strpos(diag_01,"Y462")>0 | ///
	strpos(diag_01,"Y463")>0 | strpos(diag_01,"Y464")>0 | strpos(diag_01,"Y465")>0 | strpos(diag_01,"Y466")>0  

capture drop mental_health
gen mental_health=0
replace mental_health=1 if  substr(diag_01, 1,2)=="F1" |  substr(diag_01, 1,2)=="F2" |   substr(diag_01, 1,2)=="F3" |  ///
	 substr(diag_01, 1,3)=="F60" |  substr(diag_01, 1,3)=="F61" |  substr(diag_01, 1,3)=="F69" 

	 
capture drop diabetes
gen diabetes = 0
replace diabetes = 1 if substr(diag_01, 1,3)=="E10" |  substr(diag_01, 1,3)=="E11" | ///
	 substr(diag_01, 1,3)=="E12" |  substr(diag_01, 1,3)=="E13" |  substr(diag_01, 1,3)=="E14" | ///
	 substr(diag_01, 1,4)=="G590" |  substr(diag_01, 1,4)=="G632" |  substr(diag_01, 1,4)=="I792" | ///
	 substr(diag_01, 1,4)=="M142" |  substr(diag_01, 1,4)=="N083" |  substr(diag_01, 1,4)=="O240" | ///	 
	 substr(diag_01, 1,4)=="O241" |  substr(diag_01, 1,4)=="O242" |  substr(diag_01, 1,4)=="O243" |  ///
	 substr(diag_01, 1,4)=="Y423"  
tab diabetes, mi	 

capture drop asthma
gen asthma=0
replace asthma=1 if substr(diag_01, 1,3)=="J41" |  substr(diag_01, 1,3)=="J42" | ///
	 substr(diag_01, 1,3)=="J43" |  substr(diag_01, 1,3)=="J44" |  substr(diag_01, 1,3)=="J45" | ///
	   substr(diag_01, 1,3)=="J46" |  substr(diag_01, 1,3)=="J47" 
tab asthma
	   
	   
	   
* keep only bare minimum info for now
keep encrypted_hesid bday adm_no admd disd elec_adm  main_epilepsy other_ltc  mental_health symptoms infection*   self_harm injury elective emerg ld asd high_risk associated any_cond_ld startage asthma diabetes  sex preg_related  abdon_sympt

duplicates drop *, force	
	
duplicates tag encrypted_hesid adm_no, gen(tag)
tab tag


***** checks:

* drop birth admissions and missing admission method
drop if  elec_adm==. |  elec_adm==3

capture drop adm_type
gen adm_type = .
replace adm_type = 0 if elective==1 /* elective */
replace adm_type = 1 if emerg==1 /* emergency */
replace adm_type = 2 if preg_related ==1
replace adm_type = 3 if elec_adm ==2 /* maternity */

tab adm_type sex, mi

******** keep only those that were included as outcomes
keep if adm_type<2

**** emergency only
keep if emerg==1


foreach var of varlist main_epilepsy  mental_health symptoms abdon_sympt infection*  asthma diabetes other_ltc self_harm injury    {
	rename `var' `var'_tmp
	replace `var'_tmp=0 if `var'_tmp==.
	bysort encrypted_hesid adm_no: egen `var' = max(`var'_tmp)
}

drop *_tmp

duplicates drop *, force

capture drop tag
duplicates tag encrypted_hesid adm_no, gen(tag)
tab tag, mi



************ tabulations update - emergency 
capture drop any_cond_ld
gen any_cond_ld=0
replace any_cond_ld=1 if ld==1 | high_risk==1 | associated==1
replace asd=0 if any_cond_ld==1


preserve 
*keep if any_cond_ld==1
keep if asd==1
tab startage injury, mi
tab startage injury if self_harm==1, mi
tab startage main_epilepsy , mi
tab startage symptoms , mi
tab startage infection_resp , mi
tab startage infection, mi
tab startage mental_health, mi
tab startage diabetes, mi
tab startage asthma, mi
tab startage other_ltc, mi
restore

preserve 
keep if any_cond_ld==1
*keep if asd==1
tab startage injury, mi
tab startage injury if self_harm==1, mi
tab startage main_epilepsy , mi
tab startage symptoms , mi
tab startage infection_resp , mi
tab startage infection, mi
tab startage mental_health, mi
tab startage diabetes, mi
tab startage asthma, mi
tab startage other_ltc, mi
restore


****************** length of stay ***************
global adm emerg
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

