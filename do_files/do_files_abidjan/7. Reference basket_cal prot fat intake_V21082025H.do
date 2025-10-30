********************************************************************************
* 							VII. Reference food basket
* Author: Layembe Parfait & Doho Latif
* Date: Novembre, 2024
********************************************************************************

* 1. Call the parameters
*------------------------
*include "$do_files/1. config.do"


* 2. Median Price - Food items
*-----------------------------
/*
use "${temp}/food_temp.dta", clear
*use "${food}", clear

* Quantity units - purchased items
gen	quantity_Kg=.						
*replace quantity_Kg=VARIABLE_NAME_QUANTITY*CONVERTION_COEFF if VARIABLE_NAME_UNIT==CATEGORY_NUMBER

* Gen price per unit (Kg)
gen price_unit=/*EXPENDITURE_VARIABLE*//quantity_Kg
egen median_price= median(price_unit), by(/*FOOD_ITEM_VARIABLE*/)
keep /*FOOD_ITEM_VARIABLE*/ median_price
duplicates drop /*FOOD_ITEM_VARIABLE*/ median_price, force
sort /*FOOD_ITEM_VARIABLE*/
drop /*FOOD_ITEM_VARIABLE*/=/*ALCOHOLIC_VARIABLES*/
*/
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
	
* Quantity units - purchased items
gen	quantity_Kg=.						
replace quantity_Kg=qte*poids/1000

* Gen price per unit (Kg)
gen price_unit=s07bq08/quantity_Kg
egen median_price= median(price_unit), by(food_item)
keep food_item median_price
duplicates drop food_item median_price, force
sort food_item

drop if inlist(food_item,164,165)
*drop /*FOOD_ITEM_VARIABLE*/=/*ALCOHOLIC_VARIABLES*/
save "${temp}/median_price.dta", replace


* 3. Reference basket - quintile of reference
*--------------------------------------------

* 3.1 Create a database with the food items for the households in quintile X
//3.1 Créer une base de données avec les produits alimentaires pour les ménages du quintile X
use "${temp}/cal_intake_foot.dta", clear
merge m:1 $var_lst_hh using "${temp}/expenditures_temp.dta"
sort  $var_lst_hh food_item
drop if _merge==2
drop _merge
merge m:1 food_item using "${temp}/median_price.dta"
keep if _merge==3
gen cons_tot_kq_aeq=q_kg_adj/aeq_cal_hh
gen cons_tot_kg_aeq_daily= cons_tot_kq_aeq /7

gen cal_int = fd_kcal * cons_tot_kg_aeq_daily * 10
gen diff_cal = cal_int - cal_day_aeq_2
egen conso_cal_aeq_daily = sum(cal_int), by(grappe menage)
/*
tabstat cal_day_aeq  if food_item!=300 [aw=hhweight*hhsize], by( quintile)
tabstat cal_day_aeq  [aw=hhweight*hhsize], by( quintile)
*/

//Quintile de référence
keep if quintile==5 //Quintile dont la quantité de calorie est de 2300kcal qui correspond au seuil de pauvreté
*keep $var_lst_hh food_item

*Consommation calorique du quintile 3 sans les fafh
local coef
preserve 
	duplicates drop $var_lst_hh, force 
	summarize conso_cal_aeq_daily [aweight =hhweight]
	local coef = 2300/r(mean)
	display "Le coefficient d'ajustement est `coef'"
	drop _merge

restore


*d = .9924144 
*gen y=1
drop if inlist(food_item,164,165) //Suprimer les boissons alcoolisés
*reshape wide y, i($var_lst_hh) j(food_item)
*gen cons_tot_kq_aeq=q_kg_adj/aeq_cal_hh
*gen cons_tot_kg_aeq_daily= cons_tot_kq_aeq /7

* Obtenir le nombre de ménage dans le quintile
local nb_men
preserve 
	quietly bysort grappe menage: keep if _n==1
	quietly summarize hhweight, meanonly
	local nb_men = r(sum)
	display "Nombre de ménage du quintile: `nb_men'"
restore



egen refbask_unadjq = sum(cons_tot_kg_aeq_daily * hhweight), by(food_item)
* Quantité consommée non ajustée moyenne par produit
replace refbask_unadjq = refbask_unadjq / `nb_men'
*** gen refbask_unadjq_final = refbask_unadjq / 2719
*** duplicates drop food_item, force
*** gen cal_unadjq = fd_kcal * refbask_unadjq_final * 10
*** egen val_ref_unadjust = sum(cal_unadjq)

egen refbask_unadjq_cal = sum(cal_int * hhweight), by(food_item)

* Quantité de calorie non ajustée moyenne par produit
replace refbask_unadjq_cal = refbask_unadjq_cal / `nb_men'

*** gen adjustment_coef = 0.9924144
gen refbask_adjq = refbask_unadjq * `coef'

gen refbask_adjq_cal = refbask_unadjq_cal * `coef'

duplicates drop food_item, force
gen coef = `coef'

replace fd_kcal = fd_kcal*10
replace fd_pro=fd_pro*10
replace fd_fat=fd_fat*10
foreach i in fd_pro fd_fat fd_kcal{
	gen `i'_refbask_adj= refbask_adjq*`i'
}

drop _merge
/*
keep food_item
merge 1:m food_item using "${temp}/cal_intake_foot.dta"

keep food_item fd_kcal fd_pro cons_tot_kg_aeq_daily fd_fat median_price refbask_adjq refbask_unadjq coef

total cal_unadjq cal_adjq

gen cal_unadjq = fd_kcal * refbask_unadjq * 10
gen cal_adjq = fd_kcal * refbask_adjq * 10

egen val_ref_unadjust = sum(cal_unadjq)
egen val_ref_adjust = sum(cal_adjq)

egen  cal_unadjq cal_adjq
reshape long
drop y
*/

save "${temp}/FI_q3.dta", replace


merge m:1 food_item using "${temp}/cal_prot_fat_fi.dta"
keep if _merge==3
*drop if _merge==2
drop _merge


gen cost_refperitem=refbask_adjq*median_price
egen cost_refbasket=sum(cost_refperitem), by ($var_lst_hh)

* Create values for groups for the reference basket
//Créer des valeurs pour les groupes du panier de référence
*duplicates drop s5ano s5aitem, force ?????
gen group=.

* FOOD GROUP
* NOTE: Create the food groups for the food items in the survey
*replace group=/*GROUP_NBR*/ if /*FOOD_ITEM_VARIABLE*/	/*=><=*/ 	/*RANGE_CATEGORY*/
//Créer les groupes d'aliments pour les aliments de l'enquête
replace group=item_grp



order group refbask_unadjq refbask_unadjq_cal refbask_adjq fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj cost_refperitem

collapse (sum) refbask_unadjq refbask_unadjq_cal refbask_adjq fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj cost_refperitem (first) grp_desc, by(group)

* 3.4 Export Outcomes:

* Create table: adjustment of quantities to construct a basket of food items that yields 2'950 calories per day
//Créer table : ajustement des quantités pour construire un panier de denrées alimentaires qui donne 2'950 calories par jour
preserve
keep group refbask_unadjq refbask_unadjq_cal refbask_adjq fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj
xpose, clear varname
egen v_f_1=rowtotal(v1-v8)
xpose, clear
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 3_raw") cell(C3) firstrow(var) sheetmodify
restore

* Create table: Basket of food items that yields 2'950 calories per day
// Panier de denrées alimentaires qui produit 2'950 calories par jour

preserve
foreach i in refbask_adjq fd_kcal_refbask_adj cost_refperitem {
	gen `i'_m= (`i'*365)/12 
	egen `i'_m_t=total (`i'_m)
	gen sh_`i'=(`i'_m/`i'_m_t)*100
	drop `i'_m_t
}
keep group refbask_adjq_m fd_kcal_refbask_adj_m cost_refperitem_m sh_fd_kcal_refbask_adj sh_cost_refperitem
xpose, clear varname
egen v_f_1=rowtotal(v1-v8)
xpose, clear
order group refbask_adjq_m fd_kcal_refbask_adj_m cost_refperitem_m sh_fd_kcal_refbask_adj sh_cost_refperitem 
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 5_raw") cell(C3) firstrow(var) sheetmodify
restore




















/*************************

* 3.2 Create dataset for food consumption in quintile of reference and merge with adult equivalent coefficients
*3.2 Créer un ensemble de données pour la consommation alimentaire dans le quintile de référence et fusionner avec les coefficients équivalents adultes
use "${temp}/cal_hh_temp.dta", clear
merge 1:1 $var_lst_hh food_item using "${temp}/expenditures_temp_pc.dta"
*keep if _merge==3
drop _merge
keep if quintile==3
merge 1:1 $var_lst_hh food_item using "${temp}/FI_q3.dta"
keep if _merge==3
*drop if _merge==1
drop _merge
sort $var_lst_hh food_item
drop ae_coef_hh aeq_cal_hh
merge m:1 $var_lst_hh using "${temp}/aeq_temp.dta"
keep if _merge==3
*drop if _merge==2
drop _merge 
save "${temp}/COUNTRY_YEAR_FB_HH_temp.dta", replace

* 3.3 Reference food basket
use "${temp}/COUNTRY_YEAR_FB_HH_temp.dta", clear

*generate consumption per adult equivalent and day
*générer une consommation par équivalent adulte et par jour
gen cons_tot_kq_aeq=q_kg_adj/aeq_cal_hh
gen cons_tot_kg_aeq_daily= cons_tot_kq_aeq /7

egen weight=mean(hhweight), by ($var_lst_hh)
gen dailyquant_aeq= cons_tot_kg_aeq_daily
replace dailyquant_aeq=0 if cons_tot_kg_aeq_daily==.

//installation du package permettant de calculer des statistiques agrégées tout en tenant compte des pondérations et des groupes.
*ssc install asgen 
asgen qrefbask_udj = dailyquant_aeq, weight(hhweight) by(food_item)

merge m:1 food_item using "${temp}/cal_prot_fat_fi.dta"
keep if _merge==3
*drop if _merge==2
drop _merge

* Calorie intake for reference basket - unadjusted
//Apport calorique pour le panier de référence - non ajusté
*gen cal_refbask_udj= qrefbask_udj*cal_day
*gen cal_refbask_udj= qrefbask_udj*cal_day_aeq*10
tabstat cal_day_aeq [aw=hhweight], by( item_grp)

gen cal_refbask_udj=cal_day_aeq
gen cal_refbask_udj_2=cal_day_aeq_2
egen totcalrefbask_udj=sum(cal_refbask_udj_2), by($var_lst_hh)
sort grappe menage

	//Avant ajustement
	preserve
		collapse (mean)  cal_refbask_udj [aweight =hhweight]
		gen t=1
		save "${temp}/calorie_udj.dta", replace
	restore
	
	preserve
		collapse (sum)  cal_refbask_udj_2 [aweight =hhweight], by(item_grp)
		egen tot=sum(cal_refbask_udj_2)
		gen rapport=cal_refbask_udj_2/tot
		gen t=1
		merge m:1 t using "${temp}/calorie_udj.dta"
		drop _merge
		gen calorie_udj=cal_refbask_udj*rapport
		export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 3_caludj_raw") cell(C3) firstrow(var) sheetmodify
	restore

sort grappe menage food_item
*bysort grappe menage food_item: gen t=cal_refbask_udj_2/cal_refbask_udj
gen t=cal_refbask_udj_2/cal_refbask_udj
*bysort grappe menage item_grp: gen t=cal_refbask_udj_2/cal_refbask_udj
gen seuil=2300
gen cal_refbask_adj_2=t*seuil

sort grappe menage food_item
egen layebe=sum(cal_refbask_adj_2), by( grappe menage)

		//Après ajustement
	preserve
		collapse (mean)  layebe [aweight =hhweight]
		gen t=1
		save "${temp}/calorie_adj.dta", replace
	restore
	
	preserve
		collapse (sum)  cal_refbask_adj_2 (mean) seuil [aweight =hhweight], by(item_grp)
		egen tot=sum(cal_refbask_adj_2)
		gen rapport=cal_refbask_adj_2/tot
		gen t=1
		merge m:1 t using "${temp}/calorie_adj.dta"
		drop _merge
		gen calorie_adj=seuil*rapport
		keep item_grp calorie_adj
		export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 3_caladj_raw") cell(C3) firstrow(var) sheetmodify
	restore
		

* Create coefficient to reach 2950 cal/day
*egen moy_totcalrefbask_udj=mean(totcalrefbask_udj)
*gen adjcoef=2950/moy_totcalrefbask_udj
*gen adjcoef=2950/totcalrefbask_udj
gen adjcoef=cal_refbask_adj_2/(fd_kcal*10)


* Create cal, prot, and fat intake for the adjusted reference basket
//Créer l’apport cal, prot et lipides pour le panier de référence ajusté
*gen quantity_adj=qrefbask_udj*adjcoef
gen qrefbask_adj=qrefbask_udj*(1+adjcoef)
*gen cal_ajuste=totcalrefbask_udj*adjcoef

gen z=fd_kcal
gen x=qrefbask_udj
gen parfait=qrefbask_adj*z*10
/*
foreach i in cal prot fat {
	gen `i'_refbask_adj= qrefbask_adj*`i'
	egen tot`i'refbask_adj=sum( `i'_refbask_adj), by($var_lst_hh)
}
*/

*gen qrefbask_adj=cal_ajuste/(fd_kcal*10)

replace fd_kcal=fd_kcal*10
replace fd_pro=fd_pro*10
replace fd_fat=fd_fat*10
foreach i in fd_pro fd_fat fd_kcal {
	gen `i'_refbask_adj= qrefbask_adj*`i'
	egen tot`i'refbask_adj=sum(`i'_refbask_adj), by($var_lst_hh)
}

egen proteine=mean(fd_pro_refbask_adj),  by(item_grp)
egen lipide=mean(fd_fat_refbask_adj),  by(item_grp)
egen calorie_udj=mean(cal_refbask_udj_2), by(item_grp)
egen calorie_adj=mean(cal_refbask_adj_2), by(item_grp)

* Merge with median prices
merge m:1 food_item using "${temp}/median_price.dta"
keep if _merge==3
*drop if _merge==2
sort $var_lst_hh food_item
drop _merge

gen cost_refperitem=qrefbask_adj*median_price
egen cost_refbasket=sum(cost_refperitem), by ($var_lst_hh)

* Create values for groups for the reference basket
//Créer des valeurs pour les groupes du panier de référence
*duplicates drop s5ano s5aitem, force ?????
gen group=.

* FOOD GROUP
* NOTE: Create the food groups for the food items in the survey
*replace group=/*GROUP_NBR*/ if /*FOOD_ITEM_VARIABLE*/	/*=><=*/ 	/*RANGE_CATEGORY*/
//Créer les groupes d’aliments pour les aliments de l’enquête
replace group=item_grp

order group qrefbask_udj cal_refbask_udj cal_refbask_adj_2 layebe adjcoef qrefbask_adj fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj cost_refperitem


preserve
collapse (sum) qrefbask_udj cal_refbask_udj adjcoef qrefbask_adj fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj cost_refperitem (first) grp_desc [aweight =hhweight]
restore

tabstat fd_pro_refbask_adj [aw=hhweight], by( item_grp) s(mean)
tabstat fd_fat_refbask_adj [aw=hhweight], by( item_grp) s(mean)

* 3.4 Export Outcomes:
* Create table: adjustment of quantities to construct a basket of food items that yields 2'950 calories per day
//Créer table : ajustement des quantités pour construire un panier de denrées alimentaires qui donne 2'950 calories par jour
preserve
collapse (sum) qrefbask_udj cal_refbask_udj adjcoef qrefbask_adj fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj cost_refperitem (first) grp_desc [aweight =hhweight], by(group)

keep group qrefbask_udj qrefbask_adj fd_pro_refbask_adj fd_fat_refbask_adj
xpose, clear varname
*egen v_f_1=rowtotal(v1-v16)
*replace v_f_1=v_f_1/8
xpose, clear
export excel "${outpts}\COUNTRY_ESTIMATESsss.xlsx", sheet("Table 3_1_raw") cell(C3) firstrow(var) sheetmodify
restore

tabstat cal_day_aeq, by(group)

preserve
*keep if grappe==1 & menage==6
tabstat cal_refbask_udj cal_refbask_adj_2 adjcoef fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj, by(group) s(mean sum)

collapse (mean) qrefbask_udj cal_refbask_udj cal_refbask_adj_2 adjcoef qrefbask_adj fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj cost_refperitem (first) grp_desc [aweight =hhweight], by(group)
keep group cal_refbask_udj cal_refbask_adj_2 adjcoef fd_kcal_refbask_adj fd_pro_refbask_adj fd_fat_refbask_adj
xpose, clear varname
*egen v_f_1=rowtotal(v1-v13)
*replace v_f_1=v_f_1/8
xpose, clear
export excel "${outpts}\COUNTRY_ESTIMATESsss.xlsx", sheet("Table 3_2_raw") cell(C3) firstrow(var) sheetmodify
restore

//Cout du panier almientaire de référence pour une famille de référence (taille 5)
preserve
	keep if hhsize==5
	*collapse (mean) food_exp depan total_exp_month total_exp_aeq food_exp_aeq ae_coef_hh aeq_cal_hh, by(grappe menage)
	collapse (mean) food_exp food_exp_aeq ae_coef_hh
	//Tableau 6 du rapport
	export excel "${outpts}\COUNTRY_ESTIMATESsss.xlsx", sheet("Table 3_3_raw") cell(C3) firstrow(var) sheetmodify
restore


* Create table: Basket of food items that yields 2'950 calories per day
// Panier de denrées alimentaires qui produit 2'950 calories par jour
/*
preserve
foreach i in qrefbask_adj fd_kcal_refbask_adj cost_refperitem {
	gen `i'_m= (`i'*365)/12 
	egen `i'_m_t=total (`i'_m)
	gen sh_`i'=(`i'_m/`i'_m_t)*100
	drop `i'_m_t
}
keep group qrefbask_adj_m fd_kcal_refbask_adj_m cost_refperitem_m sh_fd_kcal_refbask_adj sh_cost_refperitem
xpose, clear varname
egen v_f_1=rowtotal(v1-v6)
*replace v_f_1=v_f_1/8
xpose, clear
order group qrefbask_adj_m fd_kcal_refbask_adj_m cost_refperitem_m sh_fd_kcal_refbask_adj sh_cost_refperitem 
export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 5_raw") cell(C3) firstrow(var) sheetmodify
restore
*/


//Tableau 7 du rapport
gen hhsize2=hhsize
replace hhsize2=10 if hhsize>10
tabstat ae_coef_hh aeq_cal_hh [aw=hhweight], by( hhsize2)
mean ae_coef_hh aeq_cal_hh [aw=hhweight]
drop hhsize2


/*************************