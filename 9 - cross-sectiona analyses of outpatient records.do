*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 9 - cross-sectional analyses of outpatient records
* Date created: June 2021
*
*********************************************************************************************

**************************************************************************
* this do-file covers data cleaning and to examine crude rates of outpatient appointments
* for young people with learning disabilities or autism at ages 10-24 years old
* in 2014-2018 calendar years
**************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."



*******************************************************************************
*******************************************************************************
*******************        denominator data    ********************************
*******************************************************************************
*******************************************************************************

use "${filepath3}inception cohort all records to check coding May 2021.dta", clear

capture drop high_risk
gen high_risk = 0
replace high_risk=1 if hr_metab==1 | retts==1 | hr_ca_brain==1 | highrisk_ca==1 | fragx_m==1 | chromos2==1 | down==1 | edwpat==1 

capture drop associated
gen associated = 0
replace associated=1 if a_metab==1 | cerb_pals==1 | a_q86==1 | a_q85==1 | a_q0==1 | a_q0==1 | associated_ca==1 | fragx_f==1 | klinef==1

tab high_risk ld, mi row
tab associated ld , mi row

tab ld asd, mi

keep if ld==1 | asd==1 | high_risk==1 | associated==1 

tab ydob, mi
drop if ydob<1990 | ydob>2008

keep encrypted_hesid ld high_risk associated asd bday dod

save  "${filepath3}\bigger cohort for OPC work.dta", replace


*******************************************************************************
*******************   generate person time at risk   **************************
*******************************************************************************

codebook bday
drop if bday>mdy(12,31,2009)
drop if bday<mdy(1,1,1990)

**** max end date - minimum of DoD, 25th bday or end of study:
gen bday25 =mdy( month(bday), day(bday), year(bday)+ 25)

gen end_tmp = mdy(12,31,2018)

egen study_end = rowmin(dod bday25 end_tmp  )
format study_end %td
drop bday25 end_tmp


**** min start date, 10th bday:
capture drop bday10
gen bday10 = mdy( month(bday), day(bday), year(bday)+ 10)
format bday10 %td


***** study start - 1st Jan 2014
capture drop start_tmp
gen start_tmp = mdy(1, 1, 2014)
format start_tmp %td


egen study_start = rowmax(start_tmp bday10  )
format study_start %td
drop start_tmp bday10


* drop those that would be 10 after the study end
drop if study_start > mdy(12,31,2018)


* drop if died before the start of the study
drop if dod < mdy(1, 1, 2014) & dod!=.

codebook study_start
codebook study_end

drop if study_start == study_end-0.5 
drop if study_end<study_start

capture drop tmp
gen tmp=study_end-study_start
tab tmp if tmp<30


*************** STSET the data for follow-up time
capture drop tmp
gen tmp=0

egen hesid = group(encrypted_hesid)

stset study_end, origin(time bday) enter(time study_start) exit(time study_end) failure(tmp==1) scale(365.25) id(hesid)

stsplit ageband, at(10(1)24)
tab ageband, mi
drop if ageband==0


********* fup time
capture drop fup_time
gen fup_time = _t - _t0

collapse (sum) fup_time, by(encrypted_hesid bday dod ageband   ld asd high_risk associated  )

save "${filepath3}\follow up OP data.dta" , replace



*******************************************************************************
**************   get a summary of person time at risk   ***********************
*******************************************************************************

use "${filepath3}\follow up OP data.dta", clear
keep if asd==1 & ld!=1 & high_risk!=1 & associated!=1 
collapse (sum) fup_time, by(ageband   )
br

use "${filepath3}\follow up OP data.dta", clear
keep if ld==1 | high_risk==1 | associated==1 
collapse (sum) fup_time, by(ageband   )
br

use "${filepath3}\follow up OP data.dta", clear
gen asd2=0
replace asd2 =1 if asd==1 & ld!=1 & high_risk!=1 & associated!=1 
gen any_ld=0
replace any_ld=1 if ld==1 | high_risk==1 | associated==1 
collapse (sum) any_ld asd2 ld high_risk associated , by(ageband   )




*******************************************************************************
*******************************************************************************
******************      outpatient appointmetns counts ************************
*******************************************************************************
*******************************************************************************

***************************************************************************
********************* part 1 - clean data *********************************
***************************************************************************

use "${filepath}\ld_outpatient_data.dta", replace

keep apptage atentype attended firstatt encrypted_hesid mainspef tretspef postdist procode protype sex lsoa01 apptdate diag_01 opertn_01 

tab apptage, mi
label define agel 7001 "Less than one day" 7002 "1 to 6 days" 7003 "7 to 28 days" ///
7004 "29 to 90 days" 7005 "3 to 6 months" 7006 "6 to 9 months" 7007 "9 to 12 months"
label value  apptage agel

tab atentype, mi
replace atentype=. if atentype==13 /* not known */

/* 1-3 atended, 4-6 did not attend, 7-9 patient cancelled, 10-12 hosp cancelled, 
21-22 attended, 24-25 did not attent, 27-28 patient cancelled, 30-31 hospital cancelled */

tab atentype attended, mi


tab  attended, mi
label define attend 2 "cancelled - pat" 3 "not attended" 4 "cancelled - hosp" ///
	5 "attended" 6 "attended but late" 7 "late and not attend" 9 "missing"
label val attended attend	
replace attended = . if attended==9

***** dates
codebook *date*

foreach var of varlist oper* diag*  {
	replace `var' = subinstr(`var',"-","",.)
	replace `var' = subinstr(`var'," ","",.)
	replace `var' = subinstr(`var',"N","",.)
	replace `var' = subinstr(`var',"&","",.)
}
codebook diag_*
* a lot of missing data

tab firstatt
replace firstatt="" if firstatt=="X"
destring firstatt, replace
replace firstatt=. if firstatt==9
label var firstatt "first or followup attendance"
label define firstatt 1 "first" 2 "followup" 3 "first phone" 4 "followup phone"
label val firstatt firstatt

replace postdist="" if postdist=="-" | postdist==" N"

tab sex, mi
replace sex=. if sex==0 | sex==9
label define sexl 1 "Male" 2 "Female"
label value sex sexl

drop diag* 
drop opertn*

codebook tretspef
replace tretspef="" if tretspef==" N"
replace tretspef="" if tretspef=="&"
destring tretspef, replace
replace mainspef="" if mainspef==" N"
replace mainspef="" if mainspef=="&"
destring mainspef, replace


duplicates drop *, force

save "${filepath}\ld_outpatient_data.dta", replace



******************************************************************************
************* part 2 - get count of appointments by age **********************
******************************************************************************

use"${filepath}\ld_outpatient_data.dta", clear

merge m:1 encrypted_hesid using   "${filepath3}\bigger cohort for OPC work.dta"
keep if _merge==3
drop _merge

gen apptage2 = int((apptdate - bday)/365.25)
tab apptage2
drop if apptage2<10
drop if apptage2>24

drop if apptdate<mdy(1,1,2014)
drop if apptdate>mdy(12,31,2018)

gen calyr=year(apptdate)
tab calyr

**** keep only ones that are complete
tab attended, mi nolab
tab atentype, mi 

gen attend = 0
replace attend = 1 if attended==5  | attended==6
tab attend, mi

gen non_attend=0
replace non_attend=1 if attend==0

rename apptage2 startage

save "${filepath3}\opc_records.dta", replace


************* get the results:

use "${filepath3}\opc_records.dta", clear
keep if ld==1 | high_risk==1 | associated==1 
tab calyr
collapse (sum) attend , by(startage )
br

use "${filepath3}\opc_records.dta", clear
keep if asd==1 & ld!=1 & high_risk!=1 & associated!=1 
tab calyr
collapse (sum) attend , by(startage )
br
