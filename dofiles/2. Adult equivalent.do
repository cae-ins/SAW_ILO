********************************************************************************
*							II. Adult equivalent 
* Author: Layembe Parfait & Doho Latif
* Date: Novembre, 2024
********************************************************************************
* 1. Call the parameters
*------------------------
//include "$do_files/1. config.do"

* 2. Use individual level data to generate adult equivalent variables at the HH level
*------------------------------------------------------------------------------------
use "${hh_ind}", clear // Open raw data containing information at the individual level in the household
 
* Rename relevant variables
* Note: For gender the categorization is 1: Men - 2: Female
keep if resid==1 //Enlever les non résidents
gen gender=sexe /*VARIABLE_NAME*/ 
label define gender 1"Men" 2"Female"
label values gender gender
*gen age=/*VARIABLE_NAME*/  


*Adult equivalent definition (OECD-modified scale)
gen ae_coef=.
replace ae_coef=1 if lien==1
replace ae_coef=0.7 if lien!=1 & age>=18
*replace ae_coef=1 if gender==1 & age>=18
*replace ae_coef=0.7 if gender!=1 & age>=18
replace ae_coef=0.5 if age<18


*Adult equivalent - for calorie intake
gen aeq_cal=.
replace aeq_cal=0.29 if age==0
replace aeq_cal=0.29 if age==1 & gender==2
replace aeq_cal=0.32 if age==1 & gender==1

replace aeq_cal=0.36 if age==2  & gender==2
replace aeq_cal=0.38 if age==2 & gender==1

replace aeq_cal=0.39 if age==3  & gender==2
replace aeq_cal=0.42 if age==3 & gender==1

replace aeq_cal=0.42 if age==4  & gender==2
replace aeq_cal=0.46 if age==4 & gender==1

replace aeq_cal=0.45 if age==5  & gender==2
replace aeq_cal=0.50 if age==5 & gender==1

replace aeq_cal=0.48 if age==6  & gender==2
replace aeq_cal=0.53 if age==6 & gender==1

replace aeq_cal=0.53 if age==7  & gender==2
replace aeq_cal=0.58 if age==7 & gender==1

replace aeq_cal=0.58 if age==8  & gender==2
replace aeq_cal=0.62 if age==8 & gender==1

replace aeq_cal=0.63 if age==9  & gender==2
replace aeq_cal=0.67 if age==9 & gender==1

replace aeq_cal=0.68 if age==10  & gender==2
replace aeq_cal=0.73 if age==10 & gender==1

replace aeq_cal=0.73 if age==11 & gender==2
replace aeq_cal=0.80 if age==11 & gender==1

replace aeq_cal=0.77 if age==12 & gender==2
replace aeq_cal=0.86 if age==12 & gender==1

replace aeq_cal=0.81 if age==13 & gender==2
replace aeq_cal=0.94 if age==13 & gender==1

replace aeq_cal=0.83 if age==14 & gender==2
replace aeq_cal=1.02 if age==14 & gender==1

replace aeq_cal=0.85 if age==15 & gender==2
replace aeq_cal=1.08 if age==15 & gender==1

replace aeq_cal=0.85 if age==16 & gender==2
replace aeq_cal=1.13 if age==16 & gender==1

replace aeq_cal=0.85 if age==17 & gender==2
replace aeq_cal=1.15 if age==17 & gender==1

replace aeq_cal=0.85 if age==18 & gender==2
replace aeq_cal=1.15 if age==18 & gender==1

replace aeq_cal=0.86 if age>=19 & age<30 & gender==2
replace aeq_cal=1.03 if age>=19 & age<30 & gender==1

replace aeq_cal=0.81 if age>=30 & age<=60 & gender==2
replace aeq_cal=1.00 if age>=30 & age<=60 & gender==1

replace aeq_cal=0.75 if age>60 & age!=. & gender==2
replace aeq_cal=0.83 if age>60 & age!=. & gender==1

* Adult equivalent coefficient by household
foreach i of varlist ae_coef aeq_cal {
	egen `i'_hh = total( `i'), by($var_lst_hh)
}
* Keep relevant variables

keep $var_lst_hh ae_coef_hh aeq_cal_hh
duplicates drop

save "${temp}/aeq_temp.dta", replace


use "${temp}\aeq_temp.dta", clear 
merge 1:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(region milieu hhsize hhweight)
gen hhsize2 = hhsize
replace hhsize2 = 10 if hhsize>10
mean hhsize [pw=hhweight]
mean hhsize2 [pw=hhweight]
scalar define hh = int(e(b)[1,1]) + 1 
mean aeq_cal_hh ae_coef_hh [pw=hhweight], over(hhsize2)
mean aeq_cal_hh ae_coef_hh [pw=hhweight], over(hhsize)
scalar define aeq_calhh = e(b)[1,5]
scalar define ae_coefhh = e(b)[1,28]

do "${do_files}/pop en equivalent temps plein.do"