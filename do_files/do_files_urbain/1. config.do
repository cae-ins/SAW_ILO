********************************************************************************
* 							I. Initial configuration
* Author: Layembe Parfait
* Date: Novembre, 2024
* Note: Before running the codes, create four folders: (i) data: With the raw data (ii) do_files
* (iii) outputs: Empty folder (to export in Excel) (iv) temp: Empty folder to save temporary files.
********************************************************************************

* 1. Define working directory

global projet "C:\Users\user\OneDrive\CAE\EHCVM 2021\Last_Version"
*global projet "D:\DOCUMENTS\CAE\EHCVM 2021\Last_Version" // Insert the working path

* 2. Directory paths
*-------------------

global data "$projet\data" // Insert the path from the raw data
global outputs "$projet\Urbain\outputs" // Insert the path to the outputs (Excel File)
global temp "$projet\Urbain\temp" // Insert the path to the temporary files
global do_files "$projet\Urbain\do_files"
*global do_files `"/Users/erika_chaparro/Downloads/wb_data/02_world_bank_mplcs-hh_member.dta"' // Insert the path to the do-files


preserve
	use "${data}/s07b_me_CIV2021.dta", clear
	keep if s07bq02==1
	keep grappe menage s07bq01 s07bq03a s07bq03b s07bq03c s07bq07a s07bq07b s07bq07c s07bq08
	rename (s07bq01 s07bq03a s07bq03b s07bq03c) (codpr qte unite taille)
	rename (s07bq07a s07bq07b s07bq07c s07bq08) (qte_achat unite_achat taille_achat price_achat)
	save "${temp}/food.dta", replace
restore

//Repas pris à l'extérieur par l'ensemble du ménage
preserve
	use "${data}/s07a_1_me_CIV2021.dta", clear
	keep grappe menage s07aq02b s07aq03b s07aq05b s07aq06b s07aq08b s07aq09b s07aq11b s07aq12b s07aq14b s07aq15b s07aq17b s07aq18b s07aq20b s07aq21b
	ren (s07aq02b s07aq03b s07aq05b s07aq06b s07aq08b s07aq09b s07aq11b s07aq12b s07aq14b s07aq15b s07aq17b s07aq18b s07aq20b s07aq21b) (s07aq2 s07aq3 s07aq5 s07aq6 s07aq8 s07aq9 s07aq11 s07aq12 s07aq14 s07aq15 s07aq17 s07aq18 s07aq20 s07aq21)
	reshape long s07aq, i(grappe menage) j(item_cod1)
	drop if s07aq==. | s07aq==0
	recode item_cod1 (2/3=1001 "Petit dejeuner") (5/6=1002 "Dejeuner") (8/9=1003 "Diner") (11/12=1004 "Collation") (14/15=1005 "Boisson chaude") (17/18=1006 "Boisson non alcol") (20/21=1007 "Boisson alcol"), gen(item_cod)

	/*
	keep if inlist(s07aq01b,1,2,3) | inlist(s07aq04b,1,2,3) | inlist(s07aq07b,1,2,3) ///
	| inlist(s07aq10b,1,2,3) | inlist(s07aq13b,1,2,3)  | inlist(s07aq16b,1,2,3) | inlist(s07aq19b,1,2,3)
	foreach var in s07aq02b s07aq03b s07aq05b s07aq06b s07aq08b s07aq09b s07aq11b s07aq12b s07aq14b s07aq15b s07aq17b s07aq18b s07aq20b s07aq21b {
		recode `var' .=0
	}
	gen petit_dej=s07aq02b+s07aq03b //Petit dejeuné acheté et reçu en cadeau
	gen dejeuner=s07aq05b+s07aq06b //dejeuner acheté et reçu en cadeau
	gen diner=s07aq08b+s07aq09b //Diner acheté et reçu en cadeau
	gen collation=s07aq11b+s07aq12b //Collation acheté et reçu en cadeau
	gen boisson_chaude=s07aq14b+s07aq15b //Boisson chaude acheté et reçu en cadeau
	gen boisson_no_alcool=s07aq17b+s07aq18b //Boisson non alcoolisée acheté et reçu en cadeau
	gen boisson_alcool=s07aq20b+s07aq21b //Boisson alcoolisé acheté et reçu en cadeau
    keep grappe menage petit_dej dejeuner diner collation boisson_chaude boisson_no_alcool boisson_alcool
	*rename (s07bq01 s07bq03a s07bq03b s07bq03c) (ID_produit Qty Unite Taille)
	*/
	save "${temp}/food_ext1.dta", replace
restore


//Repas pris à l'extérieur par chaque membre du ménage
preserve
	use "${data}/s07a_2_me_CIV2021.dta", clear 
	keep grappe menage individu s07aq02 s07aq03 s07aq05 s07aq06 s07aq08 s07aq09 s07aq11 s07aq12 s07aq14 s07aq15 s07aq17 s07aq18 s07aq20 s07aq21
	ren (s07aq02 s07aq03 s07aq05 s07aq06 s07aq08 s07aq09 individu) (s07aq2 s07aq3 s07aq5 s07aq6 s07aq8 s07aq9 individu)
	reshape long s07aq, i(grappe menage individu) j(item_cod1)
	drop if s07aq==. | s07aq==0
	recode item_cod1 (2/3=1001 "Petit dejeuner") (5/6=1002 "Dejeuner") (8/9=1003 "Diner") (11/12=1004 "Collation") (14/15=1005 "Boisson chaude") (17/18=1006 "Boisson non alcol") (20/21=1007 "Boisson alcol"), gen(item_cod)	

	/*
	foreach var in s07aq02 s07aq03 s07aq05 s07aq06 s07aq08 s07aq09 s07aq11 s07aq12 s07aq14 s07aq15 s07aq17 s07aq18 s07aq20 s07aq21 {
		recode `var' (.=0)
	}
	gen petit_dej=s07aq02+s07aq03 //Petit dejeuné acheté et reçu en cadeau
	gen dejeuner=s07aq05+s07aq06 //dejeuner acheté et reçu en cadeau
	gen diner=s07aq08+s07aq09 //Diner acheté et reçu en cadeau
	gen collation=s07aq11+s07aq12 //Collation acheté et reçu en cadeau
	gen boisson_chaude=s07aq14+s07aq15 //Boisson chaude acheté et reçu en cadeau
	gen boisson_no_alcool=s07aq17+s07aq18 //Boisson non alcoolisée acheté et reçu en cadeau
	gen boisson_alcool=s07aq20+s07aq21 //Boisson alcoolisé acheté et reçu en cadeau
	keep grappe menage petit_dej dejeuner diner collation boisson_chaude boisson_no_alcool boisson_alcool
	collapse (sum) petit_dej dejeuner diner collation boisson_chaude boisson_no_alcool boisson_alcool, by(grappe menage)
	*rename (s07bq01 s07bq03a s07bq03b s07bq03c) (ID_produit Qty Unite Taille)
	*/
	save "${temp}/food_ext2.dta", replace
restore


use "${temp}/food_ext1.dta", clear
appen using "${temp}/food_ext2.dta"
collapse (sum) s07aq, by(grappe menage item_cod)
save "${temp}/food_ext.dta", replace


include "${do_files}/Dofile_poste_depense.do"

* Raw data by category 
global food "${temp}/food.dta"
global hh_ind "${data}/ehcvm_individu_CIV2021.dta"
global housing "${data}/s11_me_CIV2021.dta"
global health "${data}/s03_me_CIV2021.dta"
global educ "${data}/s02_me_CIV2021.dta"
global other "${temp}/Other_depan.dta"
global employment "${data}\s04_me_CIV2021.dta"

* 3. List of variables for each category
*-------------------------------------------------------

* 3.1. Define the variables to determine each household

global var_lst_hh "grappe menage" // Insert list of variable names for each household

* 3.2 List for Food 
global var_lst_food "codpr qte unite taille" // Insert list of variable names regarding food

global var_lst_fafh "petit_dej dejeuner diner collation boisson_chaude boisson_no_alcool boisson_alcool" // Insert list of variable names refarding food away from home - if it is the case

* 3.3 List for Housing
global var_lst_housing "s11q*" // Insert list of variable names regarding housing (include utilities and rent)

* 3.4 List for Education
global var_lst_educ "s02q*" // Insert list of variable names regarding education

* 3.5 List for Health
global var_lst_health "s03q*" // Insert list of variable names regarding health

* 3.6 List for other consumption
global var_lst_other "depan_other" // Insert list of variable names regarding other consumption

* 4. Nutritional values for food items
*------------------------------------------
* NOTE: This is the excel file constructed with information on calorie (cal), protein (prot) and fat (fat) for each food item in the data set.

preserve
*import excel "${data}/NUTRITIONAL_VALUES_FOOD_ITEMS.xlsx", sheet("Sheet1") firstrow clear
use "${data}/country_NCT.dta", clear
rename item_cod food_item
save "${temp}/cal_prot_fat_fi.dta", replace
restore
