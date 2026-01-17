********************************************************************************
*						V. Calorie & Price Part II - Calorie intake   
* Author: Layembe Parfait & Doho Latif
* Date: Novembre, 2024
********************************************************************************

* 1. Call the parameters
*------------------------
*include "$do_files/1. config.do"

* Recall food file
*use "${temp}/food_data_hh.dta", clear
use "${temp}/food_consumption_hh.dta", clear //Utiliser la conso interieure
  
* 3.Estimate calorie intake
*--------------------------

* 3.1. Estimate calorie intake in the home
 //Quantité de calorie par produit et le total par ménage
* keep relevant variables 
rename codpr food_item
keep $var_lst_hh food_item price q_kg_adj
merge m:1 food_item using "${temp}/cal_prot_fat_fi.dta" // Merge with the file saved in the configuration for nutritional values	
////Conver
*drop if _merge==1	// Drop alcoholic consumption
drop if _merge==2 	// Drop items no consumed by any HH
drop _merge
*keep $var_lst_hh /*FOOD_ITEM_VARIABLE*/ price q_kg_adj cal prot fat
keep $var_lst_hh food_item price q_kg_adj fd_kcal fd_pro fd_fat 
sort $var_lst_hh food_item
*gen cal_int_hh=q_kg_adj*fd_kcal*10
gen cal_int_hh=q_kg_adj*fd_kcal*10
egen cal_cons_hh = total(cal_int_hh), by($var_lst_hh food_item) //
egen cal_cons_hh_bit = total(cal_int_hh), by($var_lst_hh)
gen cal_day=cal_cons_hh/7
gen cal_day_bit = cal_cons_hh_bit/7
*duplicates drop grappe menage, force (Ligne de base)
save "${temp}/cal_hh_temp.dta", replace



* 3.2. Estimate calorie intake - food away from home (FAFH)
* 3.2.1 Import data
	*use "${data}/DATA_FOOD.dta", clear
	*use "${temp}/food_ext.dta", clear
	*use "${temp}/food.dta", clear
	use "$data\s07b_me_CIV2021.dta", clear
	merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta" ,keepusing (region)
	keep if region == 1 // Pour ne rester que dans Abidjan
	drop _merge
	keep if s07bq02==1
	preserve
		use "${data}/ehcvm_nsu_CIV2021.dta", clear
		keep if s00q01 == 1 // Pour ne rester que dans Abidjan
		rename (produitID uniteID tailleID) (food_item unite taille)
		collapse (median) poids, by(food_item unite taille)
		sort food_item unite taille
		save "${temp}/base_nsu_abj.dta", replace
	restore
	rename (s07bq01 s07bq03a s07bq03b s07bq03c) (food_item qte unite taille)
	merge m:1 food_item unite taille using "${temp}/base_nsu_abj.dta"
	keep if _merge==3
	drop _merge
	
	rename s07bq08 f_exp_int
	merge m:1 food_item using "${temp}/cal_prot_fat_fi.dta" // Merge with the file saved in the configuration for nutritional values	
	keep if _merge==3
	drop _merge


	* 3.2.2 Estimate calories for purchased food and estimate prices per calorie
	
	* Quantity in Kg - consumed items
	gen	quantity_Kg=.						
	replace quantity_Kg=qte*poids/1000
	//La quantité de la conso hors ménage s'obtient en rapportant la depense pour la conso hors ménage au prix unitaire des produits proxy
	*replace quantity_Kg=f_exp_ext/med_depan_kg

	* Estimate calories for purchased food and estimate prices per calorie/ by food item
	//Estimez les calories pour les aliments achetés et estimez les prix par calorie/par aliment
	gen caloriesintake=quantity_Kg*fd_kcal*10 //(Multiplier par 10)
	*drop if quantity_Kg==.
	drop if caloriesintake==.
	gen price_percal=f_exp_int/caloriesintake
	drop if price_percal==.


	* Estimate price per calories by household and in total
	egen price_percal_hh=mean(price_percal), by ($var_lst_hh)
	keep price_percal_hh $var_lst_hh
	duplicates drop 
	preserve
		use "${temp}/food_ext.dta", clear
		merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta" ,keepusing (region)
		keep if region == 1 // Pour ne rester que dans Abidjan
		drop _merge
		collapse (sum) fafh_exp=s07aq, by(grappe menage)
		*gen fafh_exp_month=fafh_exp/30
		save "${temp}/food_exp_ext.dta", replace
	restore
	merge 1:1 $var_lst_hh using "${temp}/food_exp_ext.dta"
	*merge 1:1 $var_lst_hh using "${temp}/fafh_temp.dta"
	//On supprime les ménages pour lesquelle une conso hors ménage mais dont on a pas pu 
	//avoir de proxy (petit dejeuner dejeuner et diner)
	*keep if _merge==3 
	drop _merge
	egen medianprice=median(price_percal_hh)

	* Estimate calorie consumption from fafh using price per calorie
	//Estimez la consommation de calories à partir de fafh à l'aide du prix par calorie
	gen cal_fafh=fafh_exp/price_percal_hh //Quantité de calorie par ménage
	replace cal_fafh=fafh_exp/medianprice if price_percal_hh==.
	gen cal_fafh_d=cal_fafh/7
	keep $var_lst_hh cal_fafh_d
	save "${temp}/cal_fafh_temp.dta", replace


* 3.3. Estimate total calorie intake
use "${temp}/cal_hh_temp.dta", clear
*collapse (sum) cal_day , by(grappe menage)
merge m:1 $var_lst_hh using "${temp}/cal_fafh_temp.dta"
keep if _merge==3
drop _merge
save "${temp}/cal_intake_total_hh.dta", replace
*keep $var_lst_hh cal_fafh_d cal_day
*duplicates drop
replace cal_fafh_d=0 if cal_fafh_d==.
replace cal_day=0 if cal_day==.

* Calculate total calorie intake by hh
egen cal_day_sum=sum(cal_day), by($var_lst_hh)
egen cal_day_sum_test=total(cal_day), by($var_lst_hh)

egen cal_int_d= rowtotal(cal_day_sum cal_fafh_d)
egen cal_int_bit= rowtotal(cal_day_bit cal_fafh_d)
*drop cal_fafh_d cal_day
drop if cal_int_d==0
* Calculate calorie intake per adult equivalent
merge m:1 $var_lst_hh using "${temp}/aeq_temp.dta"
drop _merge
gen cal_day_aeq=cal_int_d/aeq_cal_hh
gen cal_day_aeq_2=cal_day/aeq_cal_hh

replace food_item=300 if food_item==.
label define s07bq01 300 "Outside consumption", add

*keep $var_lst_hh cal_day_aeq cal_day_aeq_2 food_item cal_day_sum
drop if missing(cal_day_aeq)
save "${temp}/cal_intake_foot.dta", replace
keep $var_lst_hh cal_day_aeq cal_int_d aeq_cal_hh
duplicates drop $var_lst_hh, force
save "${temp}/cal_intake_hh.dta", replace
