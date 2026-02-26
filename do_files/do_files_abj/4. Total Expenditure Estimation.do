********************************************************************************
*							IV. Estimation of Monthly Total Expenditures
* Author: Erika Chaparro
* Date: September, 2023
********************************************************************************

* 1. Call the parameters
*------------------------
*include "$do_files/1. config.do"

* 2. Estimate expenditures by category
*-------------------------------------

* 2.1 Food 

use "${temp}/food_consumption_hh.dta", clear 							// Import data
merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta" ,keepusing (region)
keep if region == 1 // Pour ne rester que dans Abidjan
drop _merge
gen f_exp_item= q_kg_adj*price											// Estimate expenses
* NOTE: Estimate the Monthly expenses
replace f_exp_item=(f_exp_item/7)*30 //Mensualisation de la conso à l'intérieur
collapse (sum) f_exp_item, by($var_lst_hh)
keep $var_lst_hh f_exp_item /*VARIABLE_MONTHLY_EXP*/					// Keep relevant variables
*duplicates drop															// Drop duplicates
save "${temp}/food_hh_temp.dta", replace

* Food away from home (fafh)
*NOTE: Estimate the monthly expenses in case this variable is available.  

* Total food expenses 
* merge 1:1 $var_lst_hh using "${temp}/fafh_hh_temp.dta"				// Merge food and fafh expenses
* drop _merge
use "${temp}/food_ext.dta", clear //Importer la base de conso à l'extérieur
merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta" ,keepusing (region)
keep if region == 1 // Pour ne rester que dans Abidjan
drop _merge
drop if item_cod==1007  //On supprime les boissons alcoolisés
rename s07aq f_exp_ext //Depense de conso hors ménage
replace f_exp_ext=(f_exp_ext/7)*30  //Mensualisation de la conso hors ménage
collapse (sum) f_exp_ext, by($var_lst_hh)
merge 1:1 $var_lst_hh using "${temp}/food_hh_temp.dta"
drop _merge
replace f_exp_ext=0 if f_exp_ext==.
replace f_exp_item=0 if f_exp_item==.
gen food_exp=f_exp_ext+f_exp_item //On additionne les deux conso(int et hors ménage)
*drop f_exp_item f_exp_ext
save  "${temp}/food_temp.dta", replace

* 2.2. Housing

* Rent
* NOTE: This calculation might vary due to the nature of the data. 
use "${data}/s11_me_CIV2021", clear
*use "${housing}", clear
 ****charge utilité mensuel***
sum s11q05 s11q06 s11q23a s11q25 s11q36a s11q44a  /// 
s11q47a s11q51a 
recode s11q05 s11q06 s11q23a s11q25 s11q36a s11q44a s11q47a s11q51a (99 999 9999 99999 999999 . .a=0)

*clonevar s11q5a=s11q05
*clonevar s11q6a=s11q06
*clonevar s11q25a=s11q25

*gen s11q5b=5
*gen s11q6b=2
*gen s11q25b=2


*****loyer annuel pour les propriétaires
*gen depan5=s11q05*12

*****loyer annuel pour les locataires
*gen depan6=s11q06*12

****dépenses annuelles auprès des revendeurs eau
*gen depan25=s11q25*365/30
gen depan25=s11q25  /*dep en eau revendeur mensuel*/

****dépenses mensuelles de facture éau (s11q23a); facture électricité (s11q36a); fcature telephone (s11q44a), facture abonnement internet (s11q47a); facture abonnement cable(s11q51a)

foreach x in 23 36 44 47 51 {
 tab1 s11q`x'b 
 gen depan`x'=s11q`x'a*52/12 if s11q`x'b==1
 replace depan`x'=s11q`x'a*12/12 if s11q`x'b==2
 replace depan`x'=s11q`x'a*6/12 if s11q`x'b==3
 replace depan`x'=s11q`x'a*4/12 if s11q`x'b==4
   }

ren depan25 achat_eau 
ren depan23 fact_eau
ren depan36 fact_elect
ren depan44 fact_tel
ren depan47 fact_net
ren depan51 fact_cablTV

egen utilities_month=rowtotal(achat_eau fact_eau fact_elect fact_tel fact_net fact_cablTV)

**Calcul du loyer imputé
preserve
	include "${do_files}/Dofile_Loyer.do"
	keep vague hhweight hhsize loyer_impute grappe menage
	rename loyer_impute rent_month
	save "${temp}/Loyer.dta", replace
restore

merge 1:1 grappe menage using "${temp}/Loyer.dta"
drop _merge
merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta" ,keepusing (region)
keep if region == 1 // Pour ne rester que dans Abidjan
drop _merge

keep grappe menage utilities_month rent_month

													// Import data
*keep $var_lst_hh $var_lst_housing										// Keep relevant variables
*gen rent_month= /*RENT_VARIABLE*/										// Rent - Mothly estimation
*egen utilities_month= rowtotal(/*UTILITIES_VARIABLES*/)					// Utilities - Mothly estimation
*keep $var_lst_hh rent_month	utilities_month								// Keep relevant variables
egen housing_exp_month = rowtotal (utilities_month rent_month) // Estimate expenses housing
save "${temp}/housing_temp.dta", replace


* 2.3. Education
use "${data}/s02_me_CIV2021", clear
merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta" ,keepusing (region)
keep if region == 1 // Pour ne rester que dans Abidjan
drop _merge
keep $var_lst_hh s02q12
gen effectif_depan_educ = 1 if s02q12 == 1
keep if effectif_depan_educ !=.
collapse (sum) effectif_depan_educ, by ($var_lst_hh)

merge 1:m $var_lst_hh using "${data}/ehcvm_conso_CIV2021"
keep if _merge==3
drop _merge

keep if codpr >= 701 & codpr <= 748 

collapse (sum) depan, by ($var_lst_hh effectif_depan_educ)
										
gen educ_exp_hh_month= depan / 12

keep $var_lst_hh effectif_depan_educ educ_exp_hh_month

/*
use "${educ}", clear
keep $var_lst_hh $var_lst_educ											// Keep relevant variables
gen health_month= /*EDUCATION_VARIABLE*/
duplicates drop
*/
save "${temp}/education_temp.dta", replace


* 2.4. Health
use "${data}/s03_me_CIV2021", clear

merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta" ,keepusing (region)
keep if region == 1 // Pour ne rester que dans Abidjan
drop _merge
keep $var_lst_hh s03q12 s03q19 s03q24a s03q25 s03q28 s03q31a s03q33 s03q47

gen effectif_depan_health = 1 if s03q12 == 1 | s03q19 == 1 | s03q24a == 1 | s03q25 == 1 | s03q28 == 1 | s03q31a == 1 | s03q47 == 1
keep if effectif_depan_health !=.

collapse (sum) effectif_depan_health, by ($var_lst_hh)

merge 1:m $var_lst_hh using "${data}/ehcvm_conso_CIV2021"
keep if _merge==3
drop _merge

keep if codpr >= 761 & codpr <= 777 

//Supprimons les dépenses jugées exceptionelles
drop if inlist(codpr,774,775,776,777,773,770,771) //Proposition de LAYEBE

collapse (sum) depan, by ($var_lst_hh effectif_depan_health)

gen health_exp_month= depan / 12										

/*
use "${heatlh}", clear
keep $var_lst_hh $var_lst_health 										// Keep relevant variables	
gen health_month= /*Health_VARIABLE*/
keep $var_lst_hh health_month
duplicates drop
*/
save "${temp}/health_temp.dta", replace

* 2.5. Other consumption

/* NOTE: 
1. Some items should not be taken into account since those are not essentials, such as cigarretes, lottery, gold among others.
2. The estimates of other essentials might vary due the nature of the variables and consumption ranges (monthly, yearly). 
ALL the consumption estimates must be homogeneized and reported at a monthly basis.
*/

//Appeler oter fait dans le programme 1	
use "${temp}/Other_depan.dta", clear
keep if region == 1 // Pour ne rester que dans Abidjan

/*Supprimons les dépenses pour lesquelles l'abscence n'a pas
pas un impact significatif sur le bien-être et le 
développement personnel d'un individu (Voir page 76)

drop if inlist(codpr,308,311,312,314,315,411,624,628, ///
629,630,631,632,633,634,636,643,648,649,650,652,653) ///
& inrange(codpr,801,843)
*/
collapse (sum) other_depan=depan , by ($var_lst_hh )

gen other_exp_month= other_depan/12

keep $var_lst_hh other_exp_month

/*
use "${other}", clear
keep $var_lst_hh $var_lst_other										// Keep relevant variables
drop if /*VARIABLE_NAME*/==/*CATEGORY_VARIABLE*/					// Drop non-essential items 
* NOTE: Estimate monthly expenditures for the HH. 
keep $var_lst_hh /*VARIABLE_OTH_EXP_MONTH*/ 						// Keep relevant variables
duplicates drop
*/
save "${temp}/other_temp.dta", replace




* 2.6 TOTAL EXPENDITURES

use "${temp}/food_temp.dta", clear
local expenditures housing education health other
foreach m of local expenditures {
    merge 1:1 $var_lst_hh using "${temp}/`m'_temp.dta"
	drop _merge
} 

/*Application des déflateurs sur les prix */
cap frame drop deflateur
frame create deflateur
frame deflateur {
	use "${data}/deftemp_2025.dta", clear
	mkmat deftemp_2022_2021 deftemp_2023_2022 deftemp_2024_2023 deftemp_2025_2024, mat(deftemp)
	matrix rownames deftemp = Alimentation "Autres biens essentiels" Education Logement "Santé" Exclure "Composites 4 composantes"
}

/* Calcul de la dépense agrégée */

local i = 1
foreach dep in food_exp other_exp_month educ_exp_hh_month housing_exp_month  health_exp_month{
	replace `dep' = `dep' * deftemp[`i',1] * deftemp[`i',2] * deftemp[`i',3] * deftemp[`i',4]
	local i = `i' + 1
}

egen total_exp_month= rowtotal (food_exp housing_exp_month educ_exp_hh_month health_exp_month other_exp_month)

* Expenditures per adult equivalent
* Merge with adult equivalencies and hh weights
merge 1:1 $var_lst_hh using "${temp}/aeq_temp.dta"
keep if _merge==3
drop _merge

/*
preserve
keep $var_lst_hh /*VARIABLE_WEIGHT*/
save hh_wgt_size.dta, replace
restore
*/

*merge 1:1 $var_lst_hh using "${temp}/hh_wgt_size.dta"
merge 1:1 $var_lst_hh using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(hhweight hhsize milieu)
keep if _merge==3
drop _merge

* Total expenses
gen total_exp_aeq=total_exp_month/ae_coef_hh	// OECD aeq coefficient

* 2.7 Quintiles
xtile quintile= total_exp_aeq [aw=hhweight], n(5)		// OECD aeq coefficient

* Save expenditures file
save "${temp}/expenditures_temp.dta", replace

