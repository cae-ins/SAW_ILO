********************************************************************************
*						III. Calorie & Price Part I- Food Consumption    
* Author: Layembe Parfait & Doho Latif
* Date: Novembre, 2024
********************************************************************************

* 1. Call the parameters
*------------------------
//include "$do_files/1. config.do"

*2. Food consumption data
*---------------------------------------

use "${food}", clear // Open raw data containing information about food consumption in the household

* 2.1. Price - per unit of food item 

* NOTE: Do not take alcoholic beverages into account.
//Retirer les boissons alcoolisés
*drop boisson_alcool
drop if inlist(codpr,164,165) //Bières et vins traditionnels ou Bières industrielles
 

*. 2.1.1. Quantity in Kg - consumed items
gen	quantity_Kg=.	
//Calculer les facteurs de conversion des différents produits
	preserve
		use "${data}/ehcvm_nsu_CIV2021.dta", clear
		rename (produitID uniteID tailleID) (codpr unite taille)
		collapse (median) poids, by(codpr unite taille)
		sort codpr unite taille
		save "${temp}/ehcvm_nsu_nat_CIV2021.dta", replace /* niveau national */
	restore
merge m:1 codpr unite taille using "${temp}/ehcvm_nsu_nat_CIV2021.dta"
keep if _merge==3
drop _merge
replace quantity_Kg=qte*poids/1000 //Mettre en kilogramme
*replace quantity_Kg=VARIABLE_NAME_QUANTITY*CONVERTION_COEFF if VARIABLE_NAME_UNIT==CATEGORY_NUMBER

*NOTE: In case there is no conversion coefficient, impute values.
*REMARQUE : S’il n’y a pas de coefficient de conversion, imputez les valeurs.

* 2.1.2. Gen price per unit (Kg)
	preserve
		use "${data}/ehcvm_nsu_CIV2021.dta", clear
		rename (produitID uniteID tailleID) (codpr unite_achat taille_achat)
		collapse (median) poids, by(codpr unite_achat taille_achat)
		sort codpr unite_achat taille_achat
		merge 1:m codpr unite_achat taille_achat using "${food}"
		keep if _merge==3
		gen qte_achat_kg=qte_achat*poids/1000
		gen price_unit=price_achat/qte_achat_kg
		collapse (median) price_unit, by(codpr)
		drop if inlist(codpr,164,165) //Suprimer les boissons alcoolisés
		save "${temp}/price_codpr.dta", replace /* niveau national */
	restore
collapse (sum) quantity_Kg, by(grappe menage codpr)
merge m:1 codpr using "${temp}/price_codpr.dta"
drop if _merge==1 //Nous supprimons les produits non acheté par aucun ménage mais consommé ( 21 sur 301 801)
//(Noix de Karité,Autre farine de céréales, autres sémoules de céréales)
drop _merge

/*
*gen price_unit= /*VARIABLE_NAME_EXPENDITURES*//quantity_Kg
egen price_imput= median(price_unit), by(codpr) // impute prices with median price by food item
replace price_unit=0 if price_unit==.
gen price=price_unit
replace price=price_imput if price==.
*/




*NOTE: In case there is no price available, impute values.


* 2.2.5. Consumption - outlier correction

* Generate consumption percapita per food item
keep grappe menage codpr quantity_Kg price
//Récuperer la taille du ménage
merge m:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(hhsize)
keep if _merge==3 //Il y a des ménages qui n'ont que la consommation hors du ménage (326 ménages sur 12 965)
drop _merge
gen q_kg_pc=quantity_Kg/hhsize

* Winsorize data (ramène les valeurs extrêmes à une valeur plus proche du centre de la distribution)
ssc install winsor2
winsor2 q_kg_pc, cuts(1 99) by(codpr)

* Generate consumption for household
//Générer de la consommation pour le ménage
gen q_kg_adj=q_kg_pc*hhsize

save "${temp}/food_consumption_hh.dta", replace
