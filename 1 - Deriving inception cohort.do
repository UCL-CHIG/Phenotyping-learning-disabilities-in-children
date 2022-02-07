*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 1 - deriving cohort of young people with learning disabilities or autism
* Date created: June 2021
*
*********************************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."


****************************************************************************
* This do-file uses HES records from 1997-2019 for young people 
* to indicate diagnosis of learning disability, associated condition or autism
* anywhere in their hospital record at age 0-24 years old
****************************************************************************


use "${filepath}\ld hospital records clean v1.dta", clear

******** merge in deaths
capture drop _merge
merge m:1 encrypted_hesid using "${filepath}LD deaths clean v1.dta"
drop _merge


******** drop unneccesary variables
drop disdest dismeth epiorder gortreat hatreat pcttreat resgor resladst rururb_ind procode3 admincat endage  postdist gpprac imd04rk imd04_decile 
drop subsequent_activity match_rank dor cause_of* age_at_death 
drop death_record_used

rename dob_full bday


************ additional exclusion criteria for the cohort:

******** drop data before 1997, we focus on 1998-2018
capture drop calyr
gen calyr=year(admd)
tab calyr, mi

drop if calyr<1998
drop if calyr>2018

* using admd and bday for consistency
gen startage2 = int( (admd-bday)/365.25 )
tab startage2, mi

******* drop records with startage over 25 years old
keep if startage2<25

drop opert*

capture drop diag_concat
gen diag_concat=diag_01 + "."+diag_02 + "." + diag_03 + "."+ diag_04 + "."+ diag_05 + "."+ diag_06 + "."+ diag_07 + "."+ diag_08 + "."+ diag_09 + "."+ diag_10 + "."+ diag_11 + "."+ diag_12 + "."+ diag_13 + "."+ diag_14 + "."+ diag_15 + "."+ diag_16 + "."+ diag_17 + "."+ diag_18 + "."+  diag_19 + "."+ diag_20


******** startage2
tab startage2, mi
replace startage2 = 0.1 if startage2==7001
replace startage2 = 0.2 if startage2==7002
replace startage2 = 0.3 if startage2==7003
replace startage2 = 0.4 if startage2==7004
replace startage2 = 0.5 if startage2==7005
replace startage2 = 0.6 if startage2==7006
replace startage2 = 0.7 if startage2==7007

drop maxepino maxepino2

duplicates drop encrypted_hesid bday diag_* procode sex startage2 admidate disdate epistart epiend ydob adm_no episode_no2 nadm admd disd resgor_compl imd04rk_compl imd04_decile_compl postdist_compl resladst_compl dod, force

capture drop tmp
bysort encrypted_hesid: gen id_nr=_n

capture drop died
gen died=1 if dod!=.


************ Learning disability disability
capture drop ld_tmp*
gen ld_tmp = 0
replace ld_tmp = 1 if strpos(diag_concat,"F7")>0 
gen ld_tmp_date = admd if ld_tmp == 1
gen ld_tmp_age = startage2 if ld_tmp == 1
bysort encrypted_hesid: egen ld = max(ld_tmp)
bysort encrypted_hesid: egen ld_date = min(ld_tmp_date) 
tab ydob ld  if id_nr==1 


************ Austistic Spectrum Disorders
capture drop asd_tmp*
gen asd_tmp = 0
replace asd_tmp = 1 if strpos(diag_concat,"F840")>0 | strpos(diag_concat,"F841")>0 | strpos(diag_concat,"F843")>0 | strpos(diag_concat,"F844")>0   | ///
	strpos(diag_concat,"F845")>0 | strpos(diag_concat,"F848")>0 | strpos(diag_concat,"F849")>0 
gen asd_tmp_date= admd if asd_tmp==1
gen asd_tmp_age = startage2 if asd_tmp == 1
bysort encrypted_hesid: egen asd = max(asd_tmp)
bysort encrypted_hesid: egen asd_date = min(asd_tmp_date) 

tab asd ld  if id_nr==1 
tab  ld  if id_nr==1 & ydob<2003 & asd==1



******************************************************************
*					 High Risk Conditions
******************************************************************

*********** Downs & Patau & Edwards
gen down_tmp = 0
replace down_tmp=1 if  strpos(diag_concat,"Q90")>0 
gen down_tmp_date =.
replace down_tmp_date = admd if down_tmp ==1 
gen down_tmp_age = startage2 if down_tmp == 1
bysort encrypted_hesid: egen down = max(down_tmp)
bysort encrypted_hesid: egen down_date = min(down_tmp_date)
tab down ld  if id_nr==1 , row
tab  ld  if id_nr==1 & ydob<2003 & down==1

gen edwpat_tmp = 0
replace edwpat_tmp=1 if  strpos(diag_concat,"Q91")>0 
gen edwpat_tmp_date =.
replace edwpat_tmp_date = admd if edwpat_tmp ==1 
gen edwpat_tmp_age = startage2 if edwpat_tmp ==1 
bysort encrypted_hesid: egen edwpat = max(edwpat_tmp)
bysort encrypted_hesid: egen edwpat_date = min(edwpat_tmp_date)
tab edwpat ld  if id_nr==1 
tab  ld  if id_nr==1 & ydob<2003 & edwpat==1 


************** other chromosomal anomalies - likely to be coded more at later ages	
capture drop chromos2*
gen chromos2_tmp = 0
replace chromos2_tmp = 1 if strpos(diag_concat,"Q93")>0 | strpos(diag_concat,"Q920")>0 | strpos(diag_concat,"Q921")>0 | strpos(diag_concat,"Q922")>0 ///
		| strpos(diag_concat,"Q923")>0 | strpos(diag_concat,"Q924 ")>0 | strpos(diag_concat,"Q925 ")>0 /// 
		| strpos(diag_concat,"Q927")>0 | strpos(diag_concat,"Q928")>0 | strpos(diag_concat,"Q929")>0
tab chromos2_tmp, mi   /* only 13k? */
gen chromos2_tmp_date= admd if chromos2_tmp==1
gen chromos2_tmp_age = startage2 if chromos2_tmp == 1

bysort encrypted_hesid: egen chromos2 = max(chromos2_tmp)
bysort encrypted_hesid: egen chromos2_date = min(chromos2_tmp_date) 
tab chromos2 ld  if id_nr==1 
tab  ld  if id_nr==1 & ydob<2003 & chromos2==1


********** Fragile X in males
capture drop fragx_m*
gen fragx_m_tmp = 1 if (strpos(diag_concat,"Q922")>0 & sex==1)
tab fragx_m_tmp, mi 
gen fragx_m_tmp_date=admd if fragx_m_tmp == 1 
gen fragx_m_tmp_age = startage2 if fragx_m_tmp == 1
bysort encrypted_hesid: egen fragx_m = max(fragx_m_tmp)
bysort encrypted_hesid: egen fragx_m_date = min(fragx_m_tmp_date) 
tab fragx_m ld  if id_nr==1 , row
tab  ld  if id_nr==1 & ydob<2003 & fragx_m==1 


*********** other congenital anomaly codes 
* even though they are quite non-specific, they have high % of co-existing specific LD code
capture drop highrisk_ca*
gen highrisk_ca_tmp =1 if strpos(diag_concat,"Q998")>0   
replace highrisk_ca_tmp =1 if strpos(diag_concat,"Q999")>0  
replace highrisk_ca_tmp =1 if strpos(diag_concat,"Q898")>0  
tab highrisk_ca_tmp   
gen highrisk_ca_tmp_date=admd if highrisk_ca_tmp == 1 
gen highrisk_ca_tmp_age = startage2 if highrisk_ca_tmp == 1
bysort encrypted_hesid: egen highrisk_ca = max(highrisk_ca_tmp)
bysort encrypted_hesid: egen highrisk_ca_date = min(highrisk_ca_tmp_date) 
tab highrisk_ca ld  if id_nr==1 , row
tab  ld  if id_nr==1 & highrisk_ca==1 & ydob<2003



*************** Q0s
capture drop other*
gen hr_ca_brain_tmp = 0
replace hr_ca_brain_tmp = 1 if strpos(diag_concat,"Q00")>0 | strpos(diag_concat,"Q01")>0 
gen hr_ca_brain_tmp_date= admd if hr_ca_brain_tmp==1
gen hr_ca_brain_tmp_age = startage2 if hr_ca_brain_tmp == 1
bysort encrypted_hesid: egen hr_ca_brain = max(hr_ca_brain_tmp)
bysort encrypted_hesid: egen hr_ca_brain_date = min(hr_ca_brain_tmp_date) 
tab hr_ca_brain ld  if id_nr==1 , row
tab hr_ca_brain  if id_nr==1 & died==1
tab hr_ca_brain ld  if id_nr==1 & died!=1 , row


*************** Rett's - for examining separately
capture drop retts*
gen retts_tmp = 0
replace retts_tmp = 1 if strpos(diag_concat,"F842")>0 
gen retts_tmp_date= admd if retts_tmp==1
gen retts_tmp_age = startage2 if retts_tmp == 1
bysort encrypted_hesid: egen retts = max(retts_tmp)
bysort encrypted_hesid: egen retts_date = min(retts_tmp_date) 
tab retts ld  if id_nr==1 , row
tab retts ld  if id_nr==1 & ydob<2003, row


*********** High risk metabolic
capture drop hr_metab*
gen hr_metab_tmp =1 if strpos(diag_concat,"E00")>0 /* cong hyperthydorism */
replace hr_metab_tmp =1 if strpos(diag_concat,"E75")>0 
replace hr_metab_tmp=1 if strpos(diag_concat,"E791")>0 /* incl Lesch Nyhan disease */
replace hr_metab_tmp=1 if strpos(diag_concat,"E830")>0 /* incl Menkes disease */
gen hr_metab_tmp_date= admd if hr_metab_tmp==1
gen hr_metab_tmp_age = startage2 if hr_metab_tmp == 1
bysort encrypted_hesid: egen hr_metab = max(hr_metab_tmp)
bysort encrypted_hesid: egen hr_metab_date = min(hr_metab_tmp_date) 
tab hr_metab ld  if id_nr==1 , row
tab  ld  if id_nr==1 & ydob<2003 & hr_metab==1



******************************************************************
* 						Associated conditions 
******************************************************************

********** Klinefelter suyndrome
capture drop klinef*
gen klinef_tmp = 1 if strpos(diag_concat,"Q980")>0 	| strpos(diag_concat,"Q981")>0 | strpos(diag_concat,"Q982")>0 | strpos(diag_concat,"Q983")>0 | strpos(diag_concat,"Q984")>0 
gen klinef_tmp_date=admd if klinef_tmp == 1 
gen klinef_tmp_age = startage2 if klinef_tmp == 1
bysort encrypted_hesid: egen klinef = max(klinef_tmp)
bysort encrypted_hesid: egen klinef_date = min(klinef_tmp_date) 
tab klinef ld  if id_nr==1 , row


********** Fragile X - females or sex missing
capture drop fragx_f*
gen fragx_f_tmp = 1 if (strpos(diag_concat,"Q922")>0 & sex!=1)
tab fragx_f_tmp, mi 
gen fragx_f_tmp_date=admd if fragx_f_tmp == 1 
gen fragx_f_tmp_age = startage2 if fragx_f_tmp == 1
bysort encrypted_hesid: egen fragx_f = max(fragx_f_tmp)
bysort encrypted_hesid: egen fragx_f_date = min(fragx_f_tmp_date) 
tab fragx_f ld  if id_nr==1 , row


********** other broad cong anom codes
capture drop dtmp*
gen dtmp =1 if strpos(diag_concat,"Q870")>0     
replace dtmp =1 if strpos(diag_concat,"Q871")>0    
replace dtmp =1 if strpos(diag_concat,"Q872")>0     
replace dtmp =1 if strpos(diag_concat,"Q873")>0    
replace dtmp =1 if strpos(diag_concat,"Q875")>0     
replace dtmp =1 if strpos(diag_concat,"Q878")>0     
tab dtmp   
capture drop associated_ca*
rename dtmp associated_ca_tmp
gen associated_ca_tmp_date=admd if associated_ca_tmp == 1 
gen associated_ca_tmp_age = startage2 if associated_ca_tmp == 1
bysort encrypted_hesid: egen associated_ca = max(associated_ca_tmp)
bysort encrypted_hesid: egen associated_ca_date = min(associated_ca_tmp_date) 
tab associated_ca ld  if id_nr==1 , row


********* other anomalies of brain & spine (Q0):
capture drop a_q0*
gen a_q0_tmp = 1 if strpos(diag_concat,"Q03")>0 | strpos(diag_concat,"Q02")>0 | strpos(diag_concat,"Q04")>0 
gen a_q0_tmp_date=admd if a_q0_tmp == 1 
gen a_q0_tmp_age = startage2 if a_q0_tmp == 1
bysort encrypted_hesid: egen a_q0 = max(a_q0_tmp)
bysort encrypted_hesid: egen a_q0_date = min(a_q0_tmp_date) 
tab a_q0 ld  if id_nr==1 , row
tab a_q0 ld  if id_nr==1 & ydob<2003, row



************ neurofibromatosis :
capture drop dtmp
gen dtmp =1 if strpos(diag_concat,"Q851")>0 | strpos(diag_concat,"Q858")>0 | strpos(diag_concat,"Q859")>0
tab dtmp   
rename dtmp a_q85_tmp
gen a_q85_tmp_date=admd if a_q85_tmp == 1 
gen a_q85_tmp_age = startage2 if a_q85_tmp == 1
bysort encrypted_hesid: egen a_q85 = max(a_q85_tmp)
bysort encrypted_hesid: egen a_q85_date = min(a_q85_tmp_date) 
tab a_q85 ld  if id_nr==1 , row


****************** FAS etc
capture drop a_q86*
gen a_q86_tmp = 1 if strpos(diag_concat,"Q860")>0 | strpos(diag_concat,"Q861")>0 | strpos(diag_concat,"Q862")>0 | strpos(diag_concat,"Q868")>0 
gen a_q86_tmp_date=admd if a_q86_tmp == 1 
gen a_q86_tmp_age = startage2 if a_q86_tmp == 1
bysort encrypted_hesid: egen a_q86 = max(a_q86_tmp)
bysort encrypted_hesid: egen a_q86_date = min(a_q86_tmp_date) 
tab a_q86 ld  if id_nr==1 , row
tab a_q86 ld  if id_nr==1 & ydob<2003, row


*********** associated metabolic conditons
capture drop a_metab*
gen a_metab_tmp =1 if strpos(diag_concat,"E76")>0 
replace a_metab_tmp =1 if strpos(diag_concat,"E77")>0 
replace a_metab_tmp=1 if strpos(diag_concat,"E888")>0 
gen a_metab_tmp_date= admd if a_metab_tmp==1
gen a_metab_tmp_age = startage2 if a_metab_tmp == 1
bysort encrypted_hesid: egen a_metab = max(a_metab_tmp)
bysort encrypted_hesid: egen a_metab_date = min(a_metab_tmp_date) 
tab a_metab ld  if id_nr==1 , row
tab  ld  if id_nr==1 & ydob<2003 & a_metab==1


************ cerebral palsy
capture drop cerb_pals* 
gen cerb_pals_tmp = 0
replace cerb_pals_tmp = 1 if strpos(diag_concat,"G80")>0 
gen cerb_pals_tmp_date=admd if cerb_pals_tmp == 1 
gen cerb_pals_tmp_age = startage2 if cerb_pals_tmp == 1
bysort encrypted_hesid: egen cerb_pals = max(cerb_pals_tmp)
bysort encrypted_hesid: egen cerb_pals_date = min(cerb_pals_tmp_date) 
tab cerb_pals ld  if id_nr==1 , row 
tab cerb_pals ld  if id_nr==1 & ydob<2003 , row

format *_date* %td

* for consistency lets start everything from 1998
drop if admd<mdy(1,1,1998)
codebook encrypted_hesid

br *_tmp

gen tmp=0
foreach var of varlist *tmp{
replace `var'=0 if `var'==.
replace tmp=1 if `var'==1
}


************ Intelectual disability - subgroups of codes
gen tmpdiag=substr(diag_01, 1, 3)
capture drop dtmp*

gen mild_ld_tmp=0
replace mild_ld_tmp = 1 if strpos(diag_concat,"F70")>0 
bysort encrypted_hesid: egen mild_ld = max(mild_ld_tmp)

gen moderate_ld_tmp=0
replace moderate_ld_tmp = 1 if strpos(diag_concat,"F71")>0 
bysort encrypted_hesid: egen moderate_ld = max(moderate_ld_tmp)

gen severe_ld_tmp=0
replace severe_ld_tmp = 1 if strpos(diag_concat,"F72")>0 
bysort encrypted_hesid: egen severe_ld = max(severe_ld_tmp)

gen profound_ld_tmp=0
replace profound_ld_tmp = 1 if strpos(diag_concat,"F73")>0 
bysort encrypted_hesid: egen profound_ld = max(profound_ld_tmp)

gen other_ld_tmp=0
replace other_ld_tmp = 1 if strpos(diag_concat,"F78")>0 | strpos(diag_concat,"F79")>0 
bysort encrypted_hesid: egen other_ld = max(other_ld_tmp)



************ Asperger - subgroups
gen asperg_tmp=0
replace asperg_tmp = 1 if strpos(diag_concat,"F845")>0 
bysort encrypted_hesid: egen asperg = max(asperg_tmp)

tab tmp, mi
keep if tmp==1


save "${filepath3}inception cohort all records to check coding May 2021.dta", replace




************************************************************************************
************************************************************************************
***********************    one record per child      *******************************
************************************************************************************
************************************************************************************

use "${filepath3}inception cohort all records to check coding May 2021.dta", clear


keep encrypted_hesid cerb_pals cerb_pals_date a_metab_date a_metab a_q86_date a_q86 a_q85_date a_q85 a_q0_date a_q0 associated_ca_date associated_ca fragx_f_date fragx_f klinef_date klinef hr_metab_date hr_metab retts_date retts hr_ca_brain_date hr_ca_brain highrisk_ca_date highrisk_ca fragx_m_date fragx_m chromos2_date chromos2 edwpat_date edwpat down_date down asd_date asd ld_date ld  *_ld asperg  bday dod

foreach var of varlist   hr_metab retts hr_ca_brain highrisk_ca fragx_m chromos2 down edwpat a_metab cerb_pals a_q86 a_q85 a_q0 a_q0 associated_ca fragx_f klinef ld asd *_ld asperg {
replace `var'=0 if `var'==.
}

duplicates drop *, force

capture drop tag
duplicates tag encrypted_hesid, gen(tag)
tab tag
drop tag

gen high_risk = 0
replace high_risk=1 if hr_metab==1 | retts==1 | hr_ca_brain==1 | highrisk_ca==1 | fragx_m==1 | chromos2==1 | down==1 | edwpat==1 

gen associated = 0
replace associated=1 if a_metab==1 | cerb_pals==1 | a_q86==1 | a_q85==1 | a_q0==1 | a_q0==1 | associated_ca==1 | fragx_f==1 | klinef==1

tab high_risk ld, mi row
tab associated ld , mi row

tab ld asd, mi

keep if ld==1 | asd==1 | high_risk==1 | associated==1 

capture drop ydob
gen ydob=year(bday)
tab ydob

save  "${filepath3}inception cohort all records to check coding.dta", replace


gen agedeath=int( (dod-bday)/365.25 )
tab agedeath, mi
drop if agedeath<10 & agedeath!=.


****** for the study we focus on births in 1990-2001
drop if ydob<1990
drop if ydob>2001 

format *_date* %td

save "${filepath3}inception cohort clean May 2021.dta", replace

keep encrypted_hesid
save "${filepath3}inception cohort IDs.dta", replace



