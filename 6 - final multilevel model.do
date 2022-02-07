******************************************************************************************
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
* this do-file covers multilevel models used for this study
* it requires setting up which condition and which type of admission is modelled first
******************************************************************************


********* load data
use "${filepath3}data prepared for models.dta", clear


*********************************************************************
*********************** multilevel models ***************************
*********************************************************************

******* admission type : global macro
global adm_type elective

******* condition: global macro
global cond_type asd


keep if ${cond_type}==1

******* st up log:
capture log close
log using "${filepath3}\${cond_type} ${adm_type}.log", replace



****************** multilevel models ***********************
menbreg ${adm_type} age_int1-age_int3 age_slope1-age_slope3 i.sex ib5.imd_quint  ib3.ydob_cat   i.nr_cond_sh  , exposure(fup_time)  nocons || hesid: , irr 

***** rates for the figure
nbreg ${adm_type} i.ageband  , exposure(fup_time)    irr 
margins i.ageband

** unadjusted multilevel model
menbreg ${adm_type} i.ageband , exposure(fup_time) || hesid: , irr 
predict pred_nr_tmp, mu

menbreg ${adm_type} age_int1-age_int3 age_slope1-age_slope3 i.sex ib5.imd_quint  ib3.ydob_cat   i.nr_cond_sh , exposure(fup_time)  nocons || hesid: , irr 
predict pred_nr, mu


*sensitivity - include only young people who did not die
menbreg ${adm_type} age_int1-age_int3 age_slope1-age_slope3 i.sex ib5.imd_quint  ib3.ydob_cat   i.nr_cond_sh if died!=1, exposure(fup_time)  nocons || hesid: , irr 

*sensitivity - run separate models by year of birth category
bysort ydob_cat: menbreg  ${adm_type} age_int1-age_int3 age_slope1-age_slope3  i.sex ib5.imd_quint i.nr_cond_sh, exposure(fup_time)  nocons || hesid: , irr 


collapse (sum)  ${adm_type} fup_time pred_nr*, by(ageband)
list ageband  ${adm_type} fup_time pred_nr*

log close

