*******************************************************************************************
*
* Author: Ania Zylbersztejn (with some code from Pia Hardelid)
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 0 - cleaning HES and ONS datasets (groundwork)
* Date created: June 2021
*
*********************************************************************************************

clear
global filepath2 "X:\..."
global filepath "X:\..."


****************************************************************************
* This do-file covers preliminary data for cleaning of HES records from 1997-2019
* for young people with indication of LD/ASD anywhere at age 0-24 years old
*
* we used variables covering details of admission and discharge, diagnoses, procedures
* patient demographics & residence variables, hospital of care, treatment specialties
****************************************************************************



************************************************************************************
************************************************************************************
******************** part 1 - data cleaning ****************************************
************************************************************************************
************************************************************************************

use "${filepath}\ld hospital records.dta", clear


/* ethnos */
tab ethnos, mi
replace ethnos="" if ethnos=="Z" | ethnos=="X" | ethnos=="9" | ethnos=="99"

/* postdist */
replace postdist="" if postdist=="-"

/* sex */
tab sex, mi
replace sex=. if sex==0 | sex==9
label define sexl 1 "Male" 2 "Female"
label value sex sexl

/* dates */
codebook epistart epiend *date* 
foreach var of varlist epistart epiend *date*  {
	replace `var' = . if `var' < mdy(01,01,1930)
}

/* admission details */ 
tab admisorc, mi
replace admisorc=. if admisorc==99

tab dismeth, mi
replace dismeth=. if dismeth==9
label define dismethl 1 "Discharged" 2 "Self-discharged" 3 "Discharged by a legal entity" 4 " Died" ///
5 "Stillborn" 8 "NA - Still in hospital" 
label val dismeth dismethl

tab disdest, mi
replace disdest=. if disdest==99

/* epiorder */
tab epiorder, mi
replace epiorder=. if epiorder==99 | epiorder==98

/* epistat */
tab epistat, mi
label define epistatl 1 "Unfinished" 3 "Finished" 9 "Derived unfinished"
label val epistat epistatl

/* epitype */
tab epitype fyear, mi
label define epitypel 1 "General" 2 "Delivery" 3 "Birth" 4 "Mental Health" 5 "Delivery - other" 6 "Birth - other"
label val epitype epitypel

/* diagnosis & operation codes */
foreach var of varlist cause opertn* diag* {
	replace `var' = subinstr(`var',"-","",.)
	replace `var' = subinstr(`var',"/","",.)
	replace `var' = subinstr(`var',"&","",.)
	replace `var' = subinstr(`var'," ","",1)
	}

forvalues i=1/9 {
	replace opertn_0`i'="" if opertn_0`i'=="&"|opertn_0`i'=="-"
	replace opertn_0`i'="" if substr(opertn_0`i',1,3)=="X63"|substr(opertn_0`i',1,3)=="X64"  /*These are retired codes according to OPCS book */
}

forvalues i=10/24 {
	replace opertn_`i'="" if opertn_`i'=="&"|opertn_`i'=="-"
	replace opertn_`i'=""  if substr(opertn_`i',1,3)=="X63"|substr(opertn_`i',1,3)=="X64"
}

  
/* residence variables */
replace rescty="" if rescty=="Y" /*uknown */
replace resha="" if resha=="Y"

foreach var of varlist res* {
	replace `var'="" if `var'=="Y"
	replace `var'="" if `var'=="&"
}

/* IMD decile */
foreach var of varlist imd* {
	destring `var', replace
}

tab imd04_decile, mi
label define imd04decl 1 "Most deprived 10%" 2 "More deprived 10-20%" 3 "More deprived 20-30%" ///
	4 "More deprived 30-40%" 5 "More deprived 40-50%" 6 "Less deprived 40-50%" ///
	7 "Less deprived 30-40%" 8 "Less deprived 20-30%" 9 "Less deprived 10-20%" ///
	10 "Least deprived 10%"
label value imd04_decile imd04decl 


/* GP practice */
replace gpprac="" if gpprac=="&" | gpprac=="V81999" | gpprac=="V81998"

/* month and year of birth */
codebook mydob
tostring mydob, replace
replace mydob="" if mydob=="."
capture drop ydob2
gen ydob2 =  substr(mydob,-4, .)
replace mydob = "0"+mydob if length(mydob)==5
capture drop month_dob
gen month_dob = substr(mydob, 1, 2)
destring ydob2, replace
destring month_dob, replace

gen dob_full=.
replace dob_full=mdy(month_dob, 15, ydob2) 

gen ydob=year(dob_full)
tab ydob, mi

drop ydob2 month_dob


/* specialty */
foreach var of varlist  mainspef tretspef {
replace `var'="" if `var'=="&"
destring `var', replace
}

******** drop unfinished episodes
tab epistat, mi nolab
drop if epistat!=3

compress 

save "${filepath}\ld hospital records.dta", replace




************************************************************************************
************************************************************************************
************** part 2 - figure mode of month year of birth     *********************
************************************************************************************
************************************************************************************

use "${filepath}\ld hospital records.dta", clear

keep encrypted_hesid dob_full admidate disdate epistart epiend
* dob_full generated above as dob_full=mdy(month_dob, 15, ydob2) 

duplicates drop *, force

gen ydob = year(dob_full)
tab ydob, mi

bysort encrypted_hesid: egen bday_tmp = mode(dob_full)
format bday_tmp %td
gen tmp = 0
replace tmp=1 if dob_full!=bday_tmp
bysort encrypted_hesid: egen tmp2 = max(tmp)

* examine conflicting dates: 
sort encrypted_hesid admidate disdate epistart epiend
br if tmp2==1
br if bday_tmp==.
codebook encrypted_hesid if bday_tmp==.

* upon examination, we decided to drop records with conflicting information
drop if bday_tmp==.

replace dob_full=bday_tmp if bday_tmp!=dob_full
capture drop ydob
gen ydob = year(dob_full)
tab ydob, mi

* focus on those aged max 14 in 1998
drop if ydob<1984

keep encrypted_hesid dob_full
duplicates drop *, force

rename dob_full dob_full_complete

merge 1:m encrypted_hesid using "${filepath}\ld hospital records.dta"
keep if _merge==3
drop _merge
drop dob_full
rename dob_full_complete dob_full


save "${filepath}\ld hospital records clean v1.dta", replace





************************************************************************************
************************************************************************************
******************** part 3 further data cleaning **********************************
************************************************************************************
************************************************************************************

use "${filepath}\ld hospital records clean v1.dta", clear

codebook encrypted_hesid


************************************************************************************
*        			REMOVE EXACT DUPLICATES
************************************************************************************

capture drop tag
duplicates tag encrypted_hesid startage endage mydob sex ///
epiorder diag*  opertn* procode postdist ///
epistart epiend admidate disdate, generate(tag) 
tab tag  , mi
capture drop tag

duplicates drop encrypted_hesid startage endage mydob sex ///
epiorder diag* opertn* procode postdist ///
epistart epiend admidate disdate, force


*************************************************************************
*								fix dates								*
*************************************************************************

codebook admidate
br if admidate < mdy(3,31,1997)
drop if admidate < mdy(3,31,1997)

codebook epistart
replace epistart=. if epistart< mdy(3,31,1997)
codebook epiend
codebook disdate

gen tmp=admidate-dob_full if startage==0
tab tmp
replace startage=7001 if startage==0  & tmp==0
replace startage=7002 if startage==0  & tmp>0 & tmp<7
replace startage=7003 if startage==0  & tmp>=7 & tmp<=28
replace startage=7004 if startage==0  & tmp>=29 & tmp<=90
replace startage=7005 if startage==0  & tmp>=91 & tmp<=180
replace startage=7006 if startage==0  & tmp>=181 & tmp<=270
replace startage=7007 if startage==0  & tmp>=271 & tmp<=364
replace startage=1 if startage==0  & tmp>=364 & tmp!=.
drop tmp

tab endage


************ fix admidate
tab ydob if admidate==., mi

replace admidate=epistart if admidate==. & epiorder==1 
tab ydob if admidate==.

gen tmp=1 if admidate==.
bysort encrypted_hesid: egen tmp2 = min(tmp)
br if tmp2==1
drop tmp*

drop if admidate==. & disdate==.


************ fix epistart
tab ydob if epistart==.

************* missing epiend_tmp
tab ydob if epiend==.
replace epiend = disdate if epiend==. & disdate!=.
br encrypted_hesid admidate disdate epistart epiend epiorder startage if epiend==.


************** episode start before admission date
tab ydob if epistart < admidate
br encrypted_hesid admidate disdate epistart epiend epiorder startage if epistart < admidate
gen tmp = epistart - admidate
tab tmp if epistart < admidate
replace epistart = admidate if  epistart < admidate
drop tmp


************ episode start is after the episode end 
tab ydob if epistart>epiend 
br encrypted_hesid admidate disdate epistart epiend epiorder startage if epistart>epiend 

capture drop tmp
gen tmp=1 if epistart>epiend 
gen epistart_tmp = epiend if tmp==1
gen epiend_tmp = epistart if tmp==1

replace epistart = epistart_tmp if tmp==1
replace epiend = epiend_tmp if tmp==1
drop tmp epistart_tmp epiend_tmp


************ episode start is before admission date
tab ydob if epiend<admidate
tab ydob if disdate < epiend & disdate!=.

replace disdate = epiend if disdate < epiend & epiend!=. & disdate!=.

tab ydob if disdate< admidate & disdate!=.


************ generate complete discharge date
* highest discharge date per admission
bysort encrypted_hesid admidate: egen disdate_compl=max(disdate) 

* highest epiend date per admission
bysort encrypted_hesid admidate: egen max_epiend=max(epiend) 

replace disdate_compl=max_epiend if disdate_compl==.
replace disdate_compl=max_epiend if disdate_compl<max_epiend
format disdate_compl %td
drop max_epiend 

tab ydob if epiend>disdate_compl
tab ydob if epiend>disdate_compl & epiend!=.


capture drop tag
duplicates tag encrypted_hesid startage endage mydob sex ///
epiorder diag*  opertn* procode postdist ///
epistart epiend admidate disdate, gen(tag)
tab tag

duplicates drop encrypted_hesid startage endage mydob sex ///
epiorder diag*  opertn* procode postdist ///
epistart epiend admidate disdate, force

save "${filepath}\ld hospital records clean v1.dta", replace



gen tmp=epiend - epistart
tab mainspef if tmp>365
tab mainspef if tmp>300
tab tmp if tmp>364

drop if tmp>364
drop tmp




************************************************************************************
************************************************************************************
******************** part 4 number admissions     **********************************
************************************************************************************
************************************************************************************

***** based on code developed by Pia Hardelid

egen hesid = group(encrypted_hesid)     /* shorter identifier */


************ fix disdate complete
capture drop disdate_compl 
bysort encrypted_hesid admidate: egen disdate_compl=max(disdate) 
capture drop max_epiend 
bysort encrypted_hesid admidate: egen max_epiend=max(epiend) 
replace disdate_compl=max_epiend if disdate_compl==.
replace disdate_compl=max_epiend if disdate_compl<max_epiend
format disdate_compl %td
drop max_epiend 

bysort hesid admidate (epistart epiend disdate_compl): gen episode_no=_n 
label var episode_no "episode number start"


/*Assign a consecutive number to each admission for all individuals
 - we are numbering all separate admissions in the dataset */
egen admission_no = group(hesid admidate), missing
label var admission_no "admission count overall start"

/*Assign a general consecutive number per child, to each admission within individuals
 - we are numbering admissions within a HEs ID*/
bysort hesid: egen minadm = min(admission_no)
gen genadmno = admission_no - minadm + 1
label variable genadmno "Admission order per child"


/* number of admissions per individual */
bysort hesid: egen nadmch=max(genadmno)
label var nadmch "total admission nr per person"


/************ COMPARING DISCHARGE DATES AND SUBSEQUENT ADMISSION DATES *********/
gen disdate_compl_chron=disdate_compl

set varabbrev off


* This loop generates a new discharge date if the discharge date of a previous admission 
* is greater than the current admissions
* It will do this going back up to 20 discharge dates from current discharge date
* When there are no more discharge dates where the difference between the current and the previous discharge date is negative, it will stop
* May have to increase to higher number depending on how many loops are required 

format disdate_compl_chron %td

capture drop  disdif disdif_test
sort hesid admidate episode_no
gen prevdisdate = disdate_compl_chron[_n-1]   /*assign the date of discharge of subsequent row to a new variable*/
format prevdisdate %td       
replace prevdisdate=. if hesid[_n-1]!=hesid[_n]         /*assign missing value to first date of last discharge or episode of same hesid*/

* difference between previos disdate ad current
gen disdif=disdate_compl_chron-prevdisdate
hist disdif
replace disdate_compl_chron =prevdisdate if disdif<=0

* now i see there are some very weird things happening here! if have an admission that seems to ahve started between other admissions 

/* replace disdate_compl_chron with previous discharge date if there's an overlap */

* now look at disdate and disdate one before 
gen disdif_test=disdate_compl_chron-disdate_compl_chron[_n-(1+1)]
replace disdif_test=. if hesid[_n-(1+1)]!=hesid[_n]
 
tab disdif_test if disdif_test<0
di r(N)


local i=1		 

while `i'<=20 {

         capture drop  disdif disdif_test
         sort hesid admidate episode_no
         gen prevdisdate`i' = disdate_compl_chron[_n-`i']                                
         /*assign the date of discharge of subsequent row to a new variable*/
         format prevdisdate`i' %td       
         replace prevdisdate`i'=. if hesid[_n-`i']!=hesid[_n]  
         /*assign missing value to first date of last discharge or episode of same hesid*/

         gen disdif=disdate_compl_chron-prevdisdate`i'
         replace disdate_compl_chron =prevdisdate`i' if disdif<=0
         /* replace disdate_compl_chron with previous discharge date if there's an overlap */

         gen disdif_test=disdate_compl_chron-disdate_compl_chron[_n-(`i'+1)]
         replace disdif_test=. if hesid[_n-(`i'+1)]!=hesid[_n]
 
         qui: tab disdif_test if disdif_test<0
         di r(N)
		 
         if r(N)==0 {   
               local i= 21
			}

         else {         
			local i =`i'+1
			}

}

* these were only needed 
capture drop prevdisdate* disdif disdif_test

format disdate_compl_chron %td  
label var disdate_compl_chron "new updated discharge date"

/*This is the dishcarge date variable which is used to check 
whether there is overlap between the current admission date and previous discharge date */

capture drop prevdisdate
bysort hesid ( admidate episode_no): gen prevdisdate=disdate_compl_chron[_n-1]

capture drop disgap
gen disgap=admidate-prevdisdate  /*This indicates the number of days' difference between admissions */

format prevdisdate %td

*hist disgap

replace disgap = . if nadmch==1				/*delete 'number of days between admissions' (usually '0' for admissions with more than one episode) for cases with only 1 admission*/
replace disgap = . if genadmno==1			/*delete 'number of days between admissions' for first admission*/
replace disgap = . if episode_no!=1			/*delete 'number of days between admissions' for subsequent episodes of one admission*/

capture drop admi_flag
gen admi_flag=1 if disgap<=0

sort hesid episode_no admidate disdate_compl  

/*Sort it so that episode numbers are grouped together - otherwise will not flag admissions but episodes */

gen admi_flag_consec=admi_flag  /*this variable will be used to create the new admission number by chronologically re-ordering overlapping admissions*/

replace admi_flag_consec=admi_flag_consec[_n-1]+admi_flag[_n] if admi_flag[_n]==1 & admi_flag_consec[_n-1]!=.

* this numbered episodes within overlapping admissions
replace admi_flag_consec=. if episode_no>1  /* flag the first episode of an admission */

sort hesid admidate episode_no
bysort hesid admidate: egen admi_flag_consec2=max(admi_flag_consec)


/**************** Create a new admission number ****************************/
gen newadmno=genadmno
replace newadmno=genadmno-admi_flag_consec2 if admi_flag_consec2!=.

* genadmo - admission order per child
* admi_flag_consec2 - numbered episodes within overlapping admissions
* the resulting numbering of admissions is not sequential but episodes within the same admission
* have the same number 

egen admno2 = group(hesid newadmno), missing    /*generates new sequential number for all admissions in the dataset*/

bysort hesid (admidate genadmno episode_no): egen minadmno2 = min(admno2) /* assigns the same number to episodes of the same HES ID */
gen adm_no = admno2 - minadmno2 + 1                                             /*re-start admission number to 1 at each hesid*/

label var adm_no "updated admission number"

bysort hesid adm_no (epistart epiend): gen episode_no2 = _n
label variable episode_no2 "Updated episode order"

bysort hesid adm_no: egen maxepino=max(episode_no)
bysort hesid adm_no: egen maxepino2=max(episode_no2)


/*Counting number of collapsed admissions per child*/
bysort hesid: egen nadm = max(adm_no)
label variable nadm "number of admissions per child"

*** generate updated admission and discharge dates
bysort hesid adm_no: egen admd=min(admidate)   
bysort hesid adm_no: egen disd=max(disdate_compl)
format admd %td
format disd %td

* adding length of neonatal admission
gen length_adm=disd-admd
label var length_adm "Length of an admission"

sort hesid episode_no2 admd disd  

egen admcount = group(encrypted_hesid adm_no)
egen admcount_old = group(encrypted_hesid admidate) /*ok*/

label variable admd "admidate of new admission indicator"
label variable disd "disdate of new discharge indicator"
la var admidate "Admission date (HES)"
la var disdate "Discharge date (HES)"

drop minadmno2 admno2 newadmno admi_flag_consec2 admi_flag_consec admi_flag disgap prevdisdate disdate_compl_chron nadmch genadmno minadm admission_no episode_no 
drop   admcount admcount_old

save "${filepath}\ld hospital records clean v1.dta", replace





************************************************************************************
************************************************************************************
******************** part 5 - copy info between admissions *************************
************************************************************************************
************************************************************************************

use "${filepath}ld hospital records clean v1.dta", clear


***** complete info on sex - okay the ones that have missing sex have only one HES record 
tab sex, mi

tab dismeth if sex==.
tab admimeth if sex==.

***** drop foreign patients
tab resgor, mi
replace resgor="" if resgor=="x" 


*********** rescty ***************
tab resgor, mi
replace resgor="" if resgor=="Y"
encode resgor, generate(resgor_tmp)
bysort hesid adm_no: egen resgor_compl=mode(resgor_tmp)
label val resgor_compl resgor_tmp
gen resgor1_check=1 if resgor_tmp!=.  & resgor_compl!=resgor_tmp
bysort hesid adm_no: egen resgor1_check_id=min(resgor1_check)
drop resgor1_check
label val resgor_compl resgor_tmp
decode resgor_compl, gen(resgor_str)
drop resgor_compl
rename resgor_str resgor_compl


*********** imd04rk ***************
summ imd04rk,det
summ imd04rk

bysort hesid adm_no: egen imd04rk_compl=mode(imd04rk)
label val imd04rk_compl imd04rk1
gen imd04rk1_check=1 if imd04rk!=.  & imd04rk_compl!=imd04rk
bysort hesid adm_no: egen imd04rk1_check_id=min(imd04rk1_check)
drop imd04rk1_check


*********** imd04_decile ***************
summ imd04_decile,det
summ imd04_decile

bysort hesid adm_no: egen imd04_decile_compl=mode(imd04_decile)
label val imd04_decile_compl imd04_decile1
gen imd04_decile1_check=1 if imd04_decile!=.  & imd04_decile_compl!=imd04_decile
bysort hesid adm_no: egen imd04_decile1_check_id=min(imd04_decile1_check)
drop imd04_decile1_check


*********** post dist ***************
tab postdist, mi
replace postdist="" if postdist=="ZZ99" | postdist=="ZZZ"
encode postdist, generate(postdist_tmp)
bysort hesid adm_no: egen postdist_compl=mode(postdist_tmp)
label val postdist_compl postdist_tmp
gen postdist1_check=1 if postdist_tmp!=.  & postdist_compl!=postdist_tmp
bysort hesid adm_no: egen postdist1_check_id=min(postdist1_check)
br if postdist1_check_id==1
drop postdist1_check* postdist_tmp
decode postdist_compl, gen(postdist_str)
drop postdist_compl
rename postdist_str postdist_compl



*********** Local authority ***************
tab resladst, mi
replace resladst="" if resladst=="Y"
encode resladst, generate(resladst_tmp)
bysort hesid adm_no: egen resladst_compl=mode(resladst_tmp)
label val resladst_compl resladst_tmp
gen resladst1_check=1 if resladst_tmp!=.  & resladst_compl!=resladst_tmp
bysort hesid adm_no: egen resladst1_check_id=min(resladst1_check)
br if resladst1_check_id==1
drop resladst1_check* resladst_tmp
decode resladst_compl, gen(resladst_str)
drop resladst_compl
rename resladst_str resladst_compl

tab resladst_compl, mi

label drop imd04decl



****************
tab rescty, mi
replace rescty="" if rescty=="Y"
encode rescty, generate(rescty_tmp)
bysort encrypted_hesid adm_no: egen rescty_compl=mode(rescty_tmp)
label val rescty_compl rescty_tmp
gen rescty1_check=1 if rescty_tmp!=.  & rescty_compl!=rescty_tmp
bysort encrypted_hesid adm_no: egen rescty1_check_id=min(rescty1_check)
br if rescty1_check_id==1
drop rescty1_check* rescty_tmp
decode rescty_compl, gen(rescty_str)
drop rescty_compl
rename rescty_str rescty_compl
tab rescty_compl

tab rescty_compl, mi
tab resladst_compl if length(rescty_compl)==1


*************** Elective admissions ***************
tab admimeth, mi

gen calyr = year(admd)
tab calyr admimeth 

gen tmp=1 if admimeth=="" | admimeth=="98"
bysort encrypted_hesid: egen tmp2 = min(tmp)
br encrypted_hesid admimeth admisorc disdest admd disd length_adm adm_no episode_no2  if tmp2==1

gen elec_tmp=.
replace elec_tmp=0 if admimeth=="11" | admimeth=="12" | admimeth=="13" | admimeth=="81" | admimeth=="84" | admimeth=="89" /*elective */
replace elec_tmp=1 if admimeth=="21"  | admimeth=="22" | admimeth=="23" | admimeth=="24"  | admimeth=="25" | admimeth=="28" | ///
  admimeth=="2A" | admimeth=="2B" | admimeth=="2D"  /*emergency*/
replace elec_tmp=2 if admimeth=="31" | admimeth=="32"  /*maternity*/
replace elec_tmp=3 if admimeth=="82" | admimeth=="83" | admimeth=="2B" /*birth*/

tab admimeth elec_tmp 

tab elec_tmp, mi
br if elec_tmp==.

****Copy the elective status of first episode of each newly linked admission to all other episodes in the same admission
capture drop elec_adm1
bysort hesid adm_no (episode_no2): gen elec_adm1 = elec_tmp if _n==1

bysort hesid adm_no: egen elec_adm=min(elec_adm1)

la def elec_adm 0 "Elective" 1"Emergency" 2"Maternity" 3"Birth"
la val elec_adm elec_adm
la var elec_adm "Elective status of new admission"
la val  elec_tmp elec_adm

tab elec_adm elec_tmp, mi

capture drop tmp
gen tmp=1 if elec_adm==.
capture drop tmp2
bysort hesid admd: egen tmp2=max(tmp)

br encrypted_hesid admimeth admisorc admidate disdate disdest admd disd length_adm adm_no episode_no2 elec_* if  tmp2==1


tab elec_adm, mi
br if elec_adm==.

bysort hesid adm_no: egen elec_adm2=mode(elec_tmp)
tab elec_adm2 elec_adm, mi

drop elec_adm1

label var elec_tmp "episode level admission mode"
label var elec_adm2 "mode of admission mode"


tab elec_adm, mi



**************** sex ***************
tab sex, mi
bysort hesid adm_no: egen sex_compl=mode(sex)
capture drop tmp
gen tmp=1 if sex!=sex_compl
br if tmp==1
* all ok*
drop tmp sex_compl


******** drop variables we dont need:
drop  imd04_decile1_check_id imd04rk1_check_id resgor1_check_id resgor_tmp tag hesid disdate_compl  procodet classpat mainspef tretspef epistat
drop tmp2

save "${filepath}\ld hospital records clean v1.dta", replace






************************************************************************************
************************************************************************************
***********************    part 6 clean deaths       *******************************
************************************************************************************
************************************************************************************


use  "${filepath2}\ld_dataupdate_deaths.dta", clear

tab age_at_death

**** clean causes of death
foreach var of varlist cause_of* {
	tostring `var', replace
	replace `var' = subinstr(`var'," ","",1)
	replace `var' = subinstr(`var',"-","",.)
	replace `var' = subinstr(`var',"&","",.)
	replace `var' = subinstr(`var',"/","",.)
}

tab subsequent_activity, mi

replace subsequent_activity="0" if subsequent_activity==""
replace subsequent_activity="1" if subsequent_activity=="Y"
destring subsequent_activity, replace

tab sex, mi
replace sex=. if sex!=1 & sex!=2 
label define sexl 1 "Male" 2 "Female"
label value sex sexl
rename sex sex_ons

tab match_rank,mi

*drop if age_at_death>25
tab age_at_death

keep age_at_death death_record_used sex_ons subsequent_activity encrypted_hesid match_rank dor dod cause*

save "${filepath}LD deaths.dta", replace


******* merge ONS deaths and HES data:
merge 1:m encrypted_hesid using "${filepath}ld hospital records clean v1.dta", gen(_merge2)
drop if _merge2==1
drop _merge2

tab dismeth, mi nolab

gen dod_tmp=disdate if dismeth==4
bysort encrypted_hesid: egen dod_hosp=max(dod_tmp)
drop dod_tmp
format dod_hosp %td


****** save deaths only:
keep if dod!=. | dod_hosp!=.
drop diag* opert*

drop admimeth admisorc elec_adm endage  gpprac  imd04*
drop res*

capture drop max_activity
bysort encrypted_hesid: egen max_activity = max(disd)
format max_activity %td

capture drop tmp
gen tmp = 1 if admd > dod & dod!=. & admd!=.
tab tmp, mi

bysort encrypted_hesid: egen tmp2= sum(tmp)
capture drop subs_adm
bysort encrypted_hesid: egen subs_adm= max(tmp2)
drop tmp*

keep death_record_used dod dod_hosp dor encrypted_hesid  age_at_death match_rank ///
max_activity  subsequent_activity subs_adm  dob_full 

duplicates drop *, force

duplicates tag encrypted_hesid, gen(tag)
tab tag
drop tag


************ explore deaths in HES and ONS:

* number of admissions "after" death
tab match_rank death_record_used, mi
* 0 if HES only
* . if my additional death record

gen hosp_death=0
replace hosp_death=1 if dod_hosp!=.

tab death_record_used hosp_death, mi
br if death_record_used=="" & hosp_death==1
* they seem plausible so can include them as deaths
replace dod=dod_hosp if death_record_used=="" & hosp_death==1
replace match_rank=0 if death_record_used=="" & hosp_death==1

gen later_episodes_dif= max_activity-dod 
replace later_episodes_dif = . if later_episodes_dif<1
tab later_episodes_dif , mi 

* allow for 1 day of a difference
tab subs_adm if later_episodes_dif>1 & later_episodes_dif!=.

tab match_rank if later_episodes_dif>0 & later_episodes_dif!=.
tab later_episodes_dif if match_rank==1 & later_episodes_dif>0 & later_episodes_dif!=.
tab subs_adm if later_episodes_dif>1 & later_episodes_dif!=.


* if it is over 2 days difference - assume wrong link
gen tmp=1 if later_episodes_dif>1 & later_episodes_dif!=.
drop if tmp==1

tab subs_adm, mi
br if subs_adm==1
* that's fine

* examine match rank and drop poorest quality:
tab match_rank, mi
tab age_at_death if match_rank==8
drop if match_rank==8


********** check age at death
gen ageatdeath = int( (dod-dob_full)/365.25 )
tab ageatdeath, mi
tab age_at_death

rename dod dod_clean
keep encrypted_hesid dod_clean ageatdeath

merge 1:1  encrypted_hesid  using "${filepath}LD deaths.dta"
drop if _merge==2

replace match_rank=0 if dod==.
replace dod=dod_clean if dod==.

drop dod_clean _merge*

***** drop deaths aged over 24 accoring to approx bday
drop if ageatdeath>24

save "${filepath}LD deaths clean v1.dta", replace

log close