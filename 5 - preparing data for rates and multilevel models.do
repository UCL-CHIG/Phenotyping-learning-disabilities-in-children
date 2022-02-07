*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 5 - preparing data for analysis of rates and multilevel models
* Date created: June 2021
*
*********************************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."


******************************************************************************
* this do-file derives follow-up for children from age 10 until death, 
* 25th birthday or 31st March 2019, whichever occured first,
* excluding time spent in hospital during hospital admissions
*
*it then collapses the data for multilevel models
******************************************************************************




******************************************************************************
* additional data cleaning for FUP derivation
******************************************************************************

******* look at hospital records now & link in cohort info
use "${filepath3}ld hospital records transition cohort.dta", clear

**** only aged 10-24
gen startage2 = int( (admd-bday)/365.25 )
tab startage2, mi

drop if startage2>24
drop if startage2<10

gen agedeath=int( (dod-bday)/365.25 )
tab agedeath, mi

drop startage
rename startage2 startage

**** indicator of respite care
gen z75 = 0
replace z75=1 if strpos(diag_01, "Z75")>0
tab diag_01 if z75==1
rename z75 tmp
bysort encrypted_hesid admd: egen z75 = max(tmp)


* keep only bare minimum info for now
keep startage bday sex elec_adm disd admd adm_no  encrypted_hesid dod ///
	emerg elective preg_related self_harm injury referal  z75

duplicates drop *, force	
	
duplicates tag encrypted_hesid adm_no, gen(tag)
tab tag

gen ydob=year(bday)
tab ydob, mi


***** checks:
tab elec_adm, mi nolab

tab ydob elec_adm, mi
tab startage elec_adm, mi

* drop birth admissions and missing admission method
drop if  elec_adm==. |  elec_adm==3

tab elec_adm sex
drop if elec_adm==2 & sex==1
tab preg_related sex

capture drop adm_type
gen adm_type = .
replace adm_type = 0 if elective==1 /* elective */
replace adm_type = 1 if emerg==1 /* emergency */
replace adm_type = 2 if preg_related ==1
replace adm_type = 3 if elec_adm ==2 /* maternity */

tab adm_type sex, mi

label define adm_type 0 "elective" 1 "emergency" 2 "preg related" 3 "maternity" 
label val adm_type adm_type
label var adm_type "admission type"
* missing if no admissions

tab ydob adm_type, mi
tab adm_no if adm_type==.
tab startage adm_type, mi

gen birth_rec=0
replace birth_rec=1 if ydob>1997
tab startage adm_type if birth_rec==1, mi

* merge all individuals with no admissions so that they can contribute
merge m:1 encrypted_hesid using "${filepath3}inception cohort clean May 2021 with RF.dta"

drop if _merge==1

rename _merge only_rec
replace only_rec=1 if only_rec==2
replace only_rec=0 if only_rec==3
label drop _merge

tab elec_adm only_rec, mi
tab elec_adm, mi

duplicates drop *, force


***** extra checks:
capture drop tag	
duplicates tag encrypted_hesid adm_no, gen(tag)
tab tag
capture drop tag

capture drop any_cond_ld
gen any_cond_ld=0
replace any_cond_ld=1 if ld==1 |  associated==1 | high_risk==1

save  "${filepath3}\ld hospital records CLEAN study cohort v1.dta", replace





******************************************************************************
*		getting correct FUP
******************************************************************************

**** max end date - minimum of DoD, 25th bday or end of study:
gen bday25 =mdy( month(bday), day(bday), year(bday)+ 25)
codebook admd
gen end_tmp = mdy(3,31,2019)
egen max_end_date = rowmin(dod bday25 end_tmp  )
format max_end_date %td
drop bday25 end_tmp


**** drop admissions after end of FUP
* we use 1st of month as bday date - update for some older kids to more accurate data for FUP
br if admd > max_end_date & admd!=.
* this one - date of death before admd
gen tmpx = admd-max_end_date
tab tmpx if tmpx>0
replace admd=dod if  tmpx>0 & tmpx!=.
replace disd=dod if  tmpx>0 & tmpx!=.
drop tmpx

* save for reference
gen disd_old = disd
format disd_old %td

** creat disd after study end date
gen tmpx = disd - max_end_date
tab tmpx if tmpx>=0 & tmpx!=.
drop tmpx

gen disd_after_end=1 if disd>=max_end_date & disd!=.
replace disd=. if disd>=max_end_date & disd!=.
* need to be >= as otherwise we generated the last episode starting on 31st mar 2017 


********* admission on last day - might need to drop these if cause weird results
gen adm_on_last_day=0
replace adm_on_last_day=1 if admd == max_end_date & admd!=.

replace max_end_date=admd+0.5 if  adm_on_last_day==1


**** min start date, 10th bday:
capture drop bday10
gen bday10 = mdy( month(bday), day(bday), year(bday)+ 10)
format bday10 %td

capture drop tmp
bysort encrypted_hesid (admd disd): gen tmp = _n


******** expand last row so that we have extra FUP until end of study after dischare

*indicate last record
capture drop last
bysort 			encrypted_hesid (admd disd): gen last=1 if _n==_N & only_rec!=1	&  disd!=.
tab only_rec, mi

tab last


* expand only for those with hosp admissions who left hosp before end of study
expand 			2 if last==1 	& disd_after_end!=1								

* re-do the unique count
capture drop tmp
bysort encrypted_hesid (admd disd): gen tmp = _n
bysort 	encrypted_hesid (admd disd): gen last2=1 if _n==_N 	 & only_rec!=1	& disd_after_end!=1

replace admd=. if last2==1
replace disd=. if last2==1


***** fup start: *****

* 1) FUP start date for the first record - 10th bday10
sort encrypted_hesid admd disd
capture drop fup_start
gen fup_start = bday10 if tmp==1
replace fup_start = bday10 if only_rec==1
format fup_start %td

*it's FUP for first admission or if only record

* 2) next fups - discharge date of the admission before
* if disdate = admidate need to add 0.5
replace disd=disd + 0.5 if disd==admd & disd!=.
bysort encrypted_hesid (admd disd): replace fup_start = disd[_n-1] if fup_start==.

* 3) check if all complete - 3 missing
codebook fup_start

gen tmpx=1 if fup_start==.
bysort encrypted_hesid : egen tmpx2=max(tmpx)
br encrypted_hesid max_end_date admd disd* fup* last last2 disd_after_end only_rec if tmpx2==1


* 4) if we have any records with FUP start at study end
br encrypted_hesid max_end_date admd disd* fup* last disd_after_end only_rec if fup_start >= mdy(3,31,2019)




****** fup end *******

* 1) if only record - make it the max FUP date
capture drop fup_end
gen fup_end=.
bysort 	encrypted_hesid (admd disd): replace fup_end = max_end_date if only_rec==1
format fup_end %td

* 2) if in hospital during end of FUP then, end of FUP end is admission date for 
replace fup_end = admd if disd_after_end==1


* 3) FUP end is next admission date 
replace fup_end = admd if fup_end==.
codebook fup_end


* 4) fix the last FUP time until end of study period:
codebook fup_end if last2==1
bysort 	encrypted_hesid (admd disd): replace fup_end = max_end_date if last2==1 
codebook fup_end

**** checks
capture drop tmp2
gen tmp2= fup_end - fup_start
hist tmp2

tab tmp2 if tmp2<10
*br if fup_start==mdy(3,31,2017)
replace fup_end= fup_end+0.5 if tmp2==0
capture drop tmp2
gen tmp2= fup_end - fup_start
tab tmp2 if tmp2<10



*********** generate indicator of event

* we dont want to count the "duplicated" episode counting FUP time from last discharge to the end of study period as an event
tab elec_adm last2, mi
tab elective last2, mi
replace elec_adm=. if last2==1
replace elective=0 if last2==1
replace emerg=0 if last2==1

replace elective=0 if elective==.
replace emerg=0 if emerg==.


**** checks 
* 1) if only record we want no events
tab elective if only_rec==1, mi
tab emerg if only_rec==1, mi

* 2) FUP time from discharge to end of study - not event
tab elective if last2==1
tab emerg if last2==1, mi

* 3) check 
tab disd_after_end, mi
tab elective if disd_after_end==1   
tab emerg if disd_after_end==1  
tab preg_related if disd_after_end==1 , mi  
tab elec_adm if disd_after_end==1  , mi  


* 4) check deaths - think only deaths during admission 
capture drop tmpx
gen tmpx=1 if dod==fup_end
tab emerg if dod==fup_end
tab elective if dod==fup_end
capture drop tmpx

drop admd disd
drop  disd_old bday10 tmp last last2 tmp2 
drop disd_after_end
drop  elec_adm max_end_date


capture drop high_risk
gen high_risk = 0
replace high_risk=1 if hr_metab==1 | retts==1 | hr_ca_brain==1 | highrisk_ca==1 | fragx_m==1 | chromos2==1 | down==1 | edwpat==1 

capture drop associated
gen associated = 0
replace associated=1 if a_metab==1 | cerb_pals==1 | a_q86==1 | a_q85==1 | a_q0==1 | a_q0==1 | associated_ca==1 | fragx_f==1 | klinef==1

capture drop any_cond_ld
gen any_cond_ld=0
replace any_cond_ld=1 if ld==1 |  associated==1 | high_risk==1

tab asd, mi


save "${filepath3}LD cohort data for incidence rates v1.dta", replace



********************************************************************************
* stset the data & get initial rates:
********************************************************************************

use "${filepath3}LD cohort data for incidence rates v1.dta", clear

*global adm_type "elective"
global adm_type "emerg"

**** complete case
keep if sex!=. & imd_quint!=. 

gen id = _n
stset fup_end, origin(time bday) enter(time fup_start) exit(time fup_end) failure(${adm_type}==1) scale(365.25) id(id)

****** stsplit the data
stsplit ageband, at(11(1)24)
replace ageband=10 if ageband==0

tab ageband, mi

tab asd any_cond_ld, mi
capture drop any_cond_ld
gen any_cond_ld=0
replace any_cond_ld=1 if ld==1 | high_risk==1 | associated==1
replace asd=0 if any_cond_ld==1

strate ageband if any_cond_ld==1 ,  per(100)
strate ageband if asd==1 & any_cond_ld!=1,  per(100)




********************************************************************************
* collapse the data for mutlilevel models
********************************************************************************

use "${filepath3}LD cohort data for incidence rates v1.dta", clear

capture log close

**** some additional variables
capture drop nr_cond
gen nr_cond = cc_group2 + cc_group3 + cc_group4 + cc_group5 + cc_group6 + cc_group8 + cc_group10

tab nr_cond
recode nr_cond 0=0 1=1 2=2 3/.=3, gen(nr_cond_sh)

capture drop cc_flag
gen cc_flag=0
replace cc_flag=1 if cc_group2==1 | cc_group3==1 |  cc_group4==1 |  cc_group5==1 |  cc_group6==1 | cc_group8==1 | cc_group10==1 

tab elective emerg, mi
gen any_adm=elective
replace any_adm=2 if emerg==1


*************** STSET the data for NBREG 
gen id = _n
stset fup_end, origin(time bday) enter(time fup_start) exit(time fup_end) failure(any_adm==1,2) scale(365.25) id(id)


****** stsplit the data - maybe this is not right
stsplit ageband, at(11(1)24)
replace ageband=10 if ageband==0

**** complete case
keep if sex!=. & imd_quint!=. 

**** extra variables
gen died=1 if dod!=.
replace died=0 if died==.

**** collapse data
gen fup_time = _t-_t0

capture drop elective
gen elective=_d
replace elective=0 if any_adm!=1

capture drop emerg
gen emerg=_d
replace emerg=0 if any_adm!=2

drop any_adm
rename _d any_adm

*strate ageband, per(100)

collapse (sum) any_adm elective emerg fup_time, by(encrypted_hesid sex ageband imd_quint ydob asd ld high_risk associated  nr_cond_sh cc_flag died cc* resgor_adm ethnos_compl  )

save "${filepath3}data prepared for models.dta", replace


******* additional variables:
recode ydob 1990/1993=1 1994/1997=2 1998/2002=3, gen(ydob_cat)

* generate intercept first:
recode ageband 10/15=1 16/18=2 19/24=3, gen(age_int)

* our intercept
capture drop age_int1 age_int2 age_int3
recode age_int 1=1 2=0 3=0, gen(age_int1)
recode age_int 1=0 2=1 3=0, gen(age_int2)
recode age_int 1=0 2=0 3=1, gen(age_int3)

gen ageband_tmp = ageband
replace ageband = ageband-10

* generate spline
capture drop ageband1 ageband2 ageband3
mkspline ageband1 5 ageband2 8 ageband3 = ageband

* or generate my own slope:
capture drop age_slope*
gen age_slope1 = ageband
replace age_slope1 = 0 if age_int!=1

gen age_slope2 = ageband
replace age_slope2=age_slope2-5
replace age_slope2 = 0 if age_int!=2

gen age_slope3 = ageband
replace age_slope3=age_slope3-8
replace age_slope3 = 0 if age_int!=3

egen hesid = group(encrypted_hesid)

***** clean LD and ADS indicators
capture drop any_cond_ld
gen any_cond_ld=0
replace any_cond_ld=1 if ld==1 | high_risk==1 | associated==1

replace asd=0 if any_cond_ld==1

save "${filepath3}data prepared for models.dta", replace







