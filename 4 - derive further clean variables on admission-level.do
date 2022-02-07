*******************************************************************************************
*
* Author: Ania Zylbersztejn
* Project: Transition to adult care in young people with autism or learning disabilities
* Do-file title: 4 - deriving additional admission-level variables
* Date created: June 2021
*
*********************************************************************************************

clear
global filepath3 "X:\..."
global filepath "X:\..."



*************** exclude non-English residents from hosp records *************
use "${filepath3}ld hospital records clean v1.dta", clear
merge m:1 encrypted_hesid using "${filepath3}inception cohort IDs exc non-Eng.dta"
keep if _merge==3
drop _merge


**** check age at death
tab ageatdeath, mi 
* looks ok

capture drop ydob
gen ydob=year(bday)
tab ydob, mi

tab calyr, mi

drop resgor_compl imd04rk_compl imd04_decile_compl postdist_compl resladst_compl rescty_compl  


***** save only records in FUP age range: 10-24 years old
tab age, mi
keep if age>9 & age<25


***************** generate codes for main reasons for admissions
gen diag_concat=diag_01 + "."+diag_02 + "." + diag_03 + "."+ diag_04 + "."+ diag_05 + "."+ diag_06 + "."+ diag_07 + "."+ diag_08 + "."+ diag_09 + "."+ diag_10 + "."+ diag_11 + "."+ diag_12 + "."+ diag_13 + "."+ diag_14 + "."+ diag_15 + "."+ diag_16 + "."+ diag_17 + "."+ diag_18 + "."+ diag_19 + "."+ diag_20

gen opertn_concat=opertn_01 + "."+opertn_02 + "." + opertn_03 + "."+ opertn_04 + "."+ opertn_05 + "."+ opertn_06 + "."+ opertn_07 + "."+ opertn_08 + "."+ opertn_09 + "."+ opertn_10 + "."+ opertn_11 + "."+ opertn_12 + "."+ opertn_13 + "."+ opertn_14 + "."+ opertn_15 + "."+ opertn_16 + "."+ opertn_17 + "."+ opertn_18 + "."+ opertn_19 + "."+ opertn_20


******* generate injury related admissions
capture drop injury
gen injury=0
replace injury=1 if strpos(diag_01,"S")>0 | strpos(diag_01,"T")>0  
tab injury, mi

******* self-harm
gen self_harm=0
replace self_harm=1 if strpos(diag_concat,"X6")>0 |  strpos(diag_concat,"X7")>0 | ///
	strpos(diag_concat,"X80")>0 |  strpos(diag_concat,"X81")>0 |  strpos(diag_concat,"X82")>0 | ///
	strpos(diag_concat,"X83")>0 |  strpos(diag_concat,"X84")>0 |  strpos(diag_concat,"Z915")>0  

tab self_harm injury, mi	


****** indicate pregnancy-related admissions ********
gen preg_related = 0
replace preg_related=1 if elec_adm==2 /* maternity admission */
replace preg_related=1 if strpos(diag_concat,"O")>0 
replace preg_related=1 if strpos(diag_concat,"P00")>0 | strpos(diag_concat,"P01")>0 | ///
	strpos(diag_concat,"P02")>0 | strpos(diag_concat,"P03")>0 | strpos(diag_concat,"P04")>0 | ///
	strpos(diag_concat,"P20")>0 | strpos(diag_concat,"P50")>0 | strpos(diag_concat,"P51")>0 | ///
	strpos(diag_concat,"P52")>0 | strpos(diag_concat,"P53")>0 | strpos(diag_concat,"P54")>0 | ///
	strpos(diag_concat,"P55")>0 | strpos(diag_concat,"P56")>0 | strpos(diag_concat,"P60")>0 | ///
	strpos(diag_concat,"P61")>0 | strpos(diag_concat,"P70")>0 | strpos(diag_concat,"P77")>0 | ///
	strpos(diag_concat,"P83")>0 | strpos(diag_concat,"P93")>0 | strpos(diag_concat,"P95")>0 | ///
	strpos(diag_concat,"P964")>0 | strpos(diag_concat,"P965")>0 | strpos(diag_concat,"P00")>0 | ///
	strpos(diag_concat,"Z300")>0 | strpos(diag_concat,"Z301")>0 | strpos(diag_concat,"Z303")>0 | ///
	strpos(diag_concat,"Z304")>0 | strpos(diag_concat,"Z305")>0 | strpos(diag_concat,"Z308")>0 | ///
	strpos(diag_concat,"Z309")>0 | strpos(diag_concat,"Z31")>0 | strpos(diag_concat,"Z32")>0 | ///
	strpos(diag_concat,"Z33")>0 | strpos(diag_concat,"Z34")>0 | strpos(diag_concat,"Z35")>0 | ///
	strpos(diag_concat,"Z36")>0 | strpos(diag_concat,"Z37")>0 | strpos(diag_concat,"Z38")>0 | ///
	strpos(diag_concat,"Z39")>0 | strpos(diag_concat,"Z640")>0 | strpos(diag_concat,"Z641")>0
tab preg_related sex, mi	

replace preg_related=1 if strpos(opertn_concat,"R")>0  | strpos(opertn_concat,"Q12")>0 | ///
	strpos(opertn_concat,"Q13")>0 | strpos(opertn_concat,"Q14")>0 | strpos(opertn_concat,"Q21")>0 | ///
	strpos(opertn_concat,"Z452")>0 | strpos(opertn_concat,"Z453")>0 | strpos(opertn_concat,"Z454")>0 | ///
	strpos(opertn_concat,"Z455")>0 | strpos(opertn_concat,"Y95")>0 
	
replace preg_related=1 if epitype==2 | epitype==5
*replace preg_related=1 if epitype==3 | epitype==6   /* at this point i think i will assume epitype is wrong */

replace preg_related=1 if  classpat==5
drop classpat

 * need to copy this info between all episodes of an admission	
rename preg_related preg_related_tmp
tab preg_related_tmp, mi
bysort encrypted_hesid adm_no: egen preg_related = max(preg_related_tmp)
tab preg_related sex, mi
tab preg_related sex if startage<7000, mi

gen tmp = 1 if preg_related==1 & sex==1 & startage<7000
bysort encrypted_hesid: egen tmp2=min(tmp)
tab tmp tmp2, mi
drop tmp tmp2
* they are likely incorrectly indicated as preg related
replace preg_related=0 if preg_related==1 & sex==1  & startage<7000


foreach var of varlist self_harm injury {
	rename `var' `var'_tmp
	replace `var'_tmp=0 if `var'_tmp==.
	bysort encrypted_hesid adm_no: egen `var'=max(`var'_tmp)
} 

drop *_tmp
 

 ******** indicate elective admission
tab elec_adm, mi nolab
capture drop elective
gen elective=0
replace elective=1 if elec_adm==0
replace elective=0 if preg_related==1

********* indicate emergency admission
capture drop emerg
gen emerg=0
replace emerg=1 if elec_adm==1
replace emerg=0 if preg_related==1


********** generate main reasons for diag categories
gen diabetes = 0
replace diabetes = 1 if substr(diag_01, 1,3)=="E10" |  substr(diag_01, 1,3)=="E11" | ///
	 substr(diag_01, 1,3)=="E12" |  substr(diag_01, 1,3)=="E13" |  substr(diag_01, 1,3)=="E14" | ///
	 substr(diag_01, 1,4)=="G590" |  substr(diag_01, 1,4)=="G632" |  substr(diag_01, 1,4)=="I792" | ///
	 substr(diag_01, 1,4)=="M142" |  substr(diag_01, 1,4)=="N083" |  substr(diag_01, 1,4)=="O240" | ///	 
	 substr(diag_01, 1,4)=="O241" |  substr(diag_01, 1,4)=="O242" |  substr(diag_01, 1,4)=="O243" |  ///
	 substr(diag_01, 1,4)=="Y423"  

gen asthma=0
replace asthma=1 if substr(diag_01, 1,3)=="J41" |  substr(diag_01, 1,3)=="J42" | ///
	 substr(diag_01, 1,3)=="J43" |  substr(diag_01, 1,3)=="J44" |  substr(diag_01, 1,3)=="J45" | ///
	   substr(diag_01, 1,3)=="J46" |  substr(diag_01, 1,3)=="J47" 
	   
gen epilepsy_main_diag=0
replace epilepsy_main_diag=1 if strpos(diag_01,"F803")>0 | strpos(diag_01,"G400")>0 | strpos(diag_01,"G401")>0 | ///
	strpos(diag_01,"G402")>0 | strpos(diag_01,"G403")>0 | strpos(diag_01,"G404")>0 | ///
	strpos(diag_01,"G406")>0 | strpos(diag_01,"G407")>0 | strpos(diag_01,"G408")>0 | ///
	strpos(diag_01,"G409")>0 | strpos(diag_01,"G41")>0 | strpos(diag_01,"R568")>0 | ///
	strpos(diag_01,"Y460")>0 | strpos(diag_01,"Y461")>0 | strpos(diag_01,"Y462")>0 | ///
	strpos(diag_01,"Y463")>0 | strpos(diag_01,"Y464")>0 | strpos(diag_01,"Y465")>0 | strpos(diag_01,"Y466")>0    
rename epilepsy_main_diag main_epilepsy

gen cerb_pals = 0 
replace cerb_pals=1 if strpos(diag_01,"G80")>0 | strpos(diag_01,"G81")>0 | ///
		strpos(diag_01,"G82")>0 |  strpos(diag_01,"G83")>0
	
gen other_ltc=0
replace other_ltc=1 if substr(diag_01, 1,3)=="K50" |  substr(diag_01, 1,3)=="K51" | ///
	 substr(diag_01, 1,3)=="K52"


gen mental_health=0
replace mental_health=1 if  substr(diag_01, 1,2)=="F1" |  substr(diag_01, 1,2)=="F2" |   substr(diag_01, 1,2)=="F3" |  ///
	 substr(diag_01, 1,3)=="F60" |  substr(diag_01, 1,3)=="F61" |  substr(diag_01, 1,3)=="F69" 
	 
* excluding R568 - cause that's included for main epilepsy
capture drop symptoms
gen symptoms = 0 
replace symptoms=1 if substr(diag_01, 1,2)=="R1" | substr(diag_01, 1,3)=="K59" | ///
	 substr(diag_01, 1,3)=="R50" |  substr(diag_01, 1,3)=="R51" |  substr(diag_01, 1,3)=="R52" |  substr(diag_01, 1,3)=="R53" | //// 
	 substr(diag_01, 1,3)=="R54" |  substr(diag_01, 1,3)=="R55" |  substr(diag_01, 1,3)=="R57" |  substr(diag_01, 1,3)=="R58" | /// 
	 substr(diag_01, 1,3)=="R59" |  substr(diag_01, 1,4)=="R560" |   substr(diag_01, 1,2)=="R6" |  ///
	 substr(diag_01, 1,2)=="R0" |  substr(diag_01, 1,2)=="R2" |  substr(diag_01, 1,2)=="R3" |  ///
	 substr(diag_01, 1,2)=="R4" |  substr(diag_01, 1,2)=="R7" |  substr(diag_01, 1,2)=="R8" |  substr(diag_01, 1,2)=="R9" 

	 
gen other_reason = 0
replace other_reason=1 if substr(diag_01, 1,2)=="N8" | substr(diag_01, 1,2)=="N9" | ///
	 substr(diag_01, 1,3)=="M20" |   substr(diag_01, 1,3)=="M21" |  substr(diag_01, 1,3)=="M22" |  ////
	 substr(diag_01, 1,3)=="M23" |  substr(diag_01, 1,3)=="M24" | substr(diag_01, 1,3)=="M25" |  ///
	 substr(diag_01, 1,2)=="M7" |  substr(diag_01, 1,2)=="N4" |  substr(diag_01, 1,3)=="N50" |  ///
	 substr(diag_01, 1,3)=="N51"   

	 
gen infection =0
replace infection=1 if  substr(diag_01, 1,2)=="A0" | substr(diag_01, 1,4)=="I880" | ///
	 substr(diag_01, 1,4)=="K230" |	 substr(diag_01, 1,4)=="K231" | ///
	 substr(diag_01, 1,3)=="K25" |  substr(diag_01, 1,3)=="K26" | substr(diag_01, 1,3)=="K27" |  ////
	 substr(diag_01, 1,3)=="K28" |  substr(diag_01, 1,4)=="K293" |  substr(diag_01, 1,4)=="K294" | ///
	 substr(diag_01, 1,4)=="K295" |  substr(diag_01, 1,3)=="K35" |  substr(diag_01, 1,3)=="K36" | ///
	 substr(diag_01, 1,3)=="K37" | substr(diag_01, 1,4)=="K528" |  substr(diag_01, 1,4)=="K529" | ///
	 substr(diag_01, 1,3)=="K61" |  substr(diag_01, 1,4)=="K630" |  substr(diag_01, 1,4)=="K632" | ///
	 substr(diag_01, 1,4)=="K650" |  substr(diag_01, 1,4)=="K678" |  substr(diag_01, 1,4)=="K908" | ///
	 substr(diag_01, 1,4)=="K930" |  substr(diag_01, 1,3)=="R11"  | ///
	 substr(diag_01, 1,4)=="N300"  | ///
	 substr(diag_01, 1,4)=="N341"  |  substr(diag_01, 1,4)=="N351" |  substr(diag_01, 1,3)=="N37" | ///
	 substr(diag_01, 1,4)=="N390" |  substr(diag_01, 1,4)=="N410"  |  substr(diag_01, 1,4)=="N411" | ///
	 substr(diag_01, 1,4)=="N412" |  substr(diag_01, 1,4)=="N413" |  substr(diag_01, 1,4)=="N431" | ///
	 substr(diag_01, 1,3)=="N45" |  substr(diag_01, 1,4)=="N481"  |  substr(diag_01, 1,4)=="N482"   | ///
     substr(diag_01, 1,3)=="N49" |  ///
	 substr(diag_01, 1,3)=="N51" |  substr(diag_01, 1,3)=="N70" |  substr(diag_01, 1,3)=="N71"  | ///
	 substr(diag_01, 1,3)=="N72" |  substr(diag_01, 1,3)=="N73" |  substr(diag_01, 1,3)=="N74" | ///
	 substr(diag_01, 1,4)=="N751"  |  substr(diag_01, 1,4)=="N764" |  substr(diag_01, 1,3)=="N87" 
	 

gen infection_resp =0
replace infection_resp=1 if    substr(diag_01, 1,3)=="A15" | ///
	 substr(diag_01, 1,3)=="A16" | substr(diag_01, 1,3)=="A17" | substr(diag_01, 1,3)=="A18" | ///
	 substr(diag_01, 1,3)=="A19" | substr(diag_01, 1,4)=="A481"| substr(diag_01, 1,4)=="A482" | ///
	 substr(diag_01, 1, 3)=="B59" | ///
	 substr(diag_01, 1,3)=="J00" |  substr(diag_01, 1,3)=="J01" |  substr(diag_01, 1,3)=="J02" | ///
	 substr(diag_01, 1,3)=="J03" |  substr(diag_01, 1,3)=="J04" |  substr(diag_01, 1,3)=="J05" | ///
	 substr(diag_01, 1,3)=="J06" |  substr(diag_01, 1,2)=="J1" |  substr(diag_01, 1,2)=="J2" | ///
	 substr(diag_01, 1,3)=="J32" |  substr(diag_01, 1,3)=="J36" |  substr(diag_01, 1,3)=="J37" | ///
	 substr(diag_01, 1,4)=="J390" |   substr(diag_01, 1,4)=="J391" |  substr(diag_01, 1,3)=="J40" | ///
	 substr(diag_01, 1,3)=="J41" | substr(diag_01, 1,3)=="J42" | substr(diag_01, 1,4)=="J430" | ///
	 substr(diag_01, 1,4)=="J440" | substr(diag_01, 1,3)=="J47" | substr(diag_01, 1,3)=="J56" | ///
	 substr(diag_01, 1,3)=="J85" | substr(diag_01, 1,3)=="J86" | substr(diag_01, 1,4)=="J988"  | ///
	 substr(diag_01, 1,4)=="N740"   | substr(diag_01, 1,4)=="N741" 
	 

gen dialysis=0
replace dialysis=1 if strpos(opertn_01,"X40")>0  	 
	 
******* admission source
tab admisorc, mi
drop admisorc
tab elec_adm, mi nolab
tab admimeth if elec_adm==1 & episode_no2==1 
gen tmp = 0
replace tmp=1 if elec_adm==1 & episode_no2==1  & admimeth=="22" /* GP */
bysort encrypted_hesid adm_no: egen referal = max(tmp)
label define referal 1 "GP" 0 "other"
label values referal referal
tab referal, mi	 
drop tmp	 

save "${filepath3}ld hospital records transition cohort.dta", replace

