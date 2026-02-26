********************************************************************************
* 							VI. Quintile distribution
* Author: Layembe Parfait & Doho Latif
* Date: Novembre, 2024
********************************************************************************

* 1. Call the parameters
*------------------------
*include "$do_files/1. config.do"

* Log to save file in stata
*log using "${outputs}/COTE D'IVOIRE_log.log", replace

* 2. Import final datasets
use "${temp}/expenditures_temp.dta", clear

merge 1:m $var_lst_hh using "${temp}/cal_intake_hh.dta"
/* DROP LES MENAGES DEPUIS LA BASE INITIALE AVANT DE FAIRE DE LA DISTRIBUTION DES QUINTILE SUR LA BASE DES DEPENSES DE CONSOMMATION */
*
drop if missing(cal_day_aeq)
/* DROP LES MENAGES DEPUIS LA BASE INITIALE AVANT DE FAIRE DE LA DISTRIBUTION DES QUINTILE SUR LA BASE DES DEPENSES DE CONSOMMATION */
drop _merge

* Generate aditional variables
gen food_exp_aeq=food_exp/aeq_cal_hh 
gen educ_exp_pc=educ_exp_hh_month/hhsize
gen health_exp_pc=health_exp_month/hhsize
gen other_exp_month_aeq=other_exp_month/ae_coef_hh

save "${temp}/expenditures_temp_pc.dta", replace
* 3. Tabulate distribution of relevant variables
 //recuperer la taille du ménage et le poids du ménage
merge m:1 grappe menage using "$data\ehcvm_welfare_2b_CIV2021.dta", keepusing(hhsize hhweight)
keep if _merge==3
tabulate quintile [aweight = hhweight*hhsize], summarize(total_exp_aeq) nostandard nofreq
tabulate quintile [aweight = hhweight*hhsize], summarize(food_exp_aeq) nostandard nofreq
tabulate quintile [aweight = hhweight*hhsize], summarize(hhsize) nostandard nofreq
tabulate quintile [aweight =hhweight*hhsize], summarize(aeq_cal_hh) nostandard nofreq
tabulate quintile [aweight = hhweight*hhsize], summarize(cal_day_aeq) nostandard nofreq
tabulate hhsize [aweight = hhweight*hhsize], summarize(aeq_cal_hh) nostandard nofreq
tabulate hhsize [aweight = hhweight*hhsize], summarize(ae_coef_hh) nostandard nofreq
tabulate quintile [aweight = hhweight*hhsize], summarize(educ_exp_pc) nostandard nofreq
tabulate quintile [aweight = hhweight*hhsize], summarize(health_exp_pc) nostandard nofreq
tabulate quintile [aweight = hhweight*hhsize], summarize(other_exp_month) nostandard nofreq
tabulate quintile [aweight = hhweight*hhsize], summarize(other_exp_month_aeq) nostandard nofreq

* 4. Export excel files

gen freq=1
preserve
use "${temp}/expenditures_temp_pc.dta", clear
merge 1:1 $var_lst_hh using "${temp}/cal_intake_hh.dta"
gen freq=1
drop _merge
merge m:1 $var_lst_hh using "${temp}/aeq_temp.dta"
keep if _merge==3
drop _merge
*gen food_exp_aeq=food_exp/ae_coef_hh 
tabstat total_exp_aeq food_exp_aeq hhsize cal_day_aeq ae_coef_hh [aweight =hhweight], by(quintile)
tabstat total_exp_aeq food_exp_aeq [aweight =hhweight], by(quintile) s(sum mean)
tabstat cal_day_aeq [aweight =hhweight], by(quintile) s(sum mean)

collapse (mean)  total_exp_aeq food_exp_aeq hhsize cal_day_aeq aeq_cal_hh (count) freq [aweight =hhweight], by (quintile)
*collapse (mean)  total_exp_aeq food_exp_aeq hhsize cal_day_aeq ae_coef_hh (count) freq , by (quintile)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 2_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
collapse (mean)  total_exp_aeq food_exp_aeq hhsize cal_day_aeq aeq_cal_hh (count) freq [aweight =hhweight]
*collapse (mean)  total_exp_aeq food_exp_aeq hhsize cal_day_aeq ae_coef_hh (count) freq , by (quintile)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 2_1_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) hhsize aeq_cal_hh (count) freq [aweight =hhweight], by (quintile)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 6_raw") cell(C3) firstrow(var) sheetmodify
restore



preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) ae_coef_hh aeq_cal_hh (count) freq [aweight =hhweight], by (quintile)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 7_raw") cell(C3) firstrow(var) sheetmodify
restore


preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) ae_coef_hh aeq_cal_hh (count) freq [aweight =hhweight], by (quintile milieu)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 7_1_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) health_exp_pc educ_exp_pc (count) freq [aweight =hhweight], by (quintile)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 16_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) other_exp_month other_exp_month_aeq (count) freq [aweight =hhweight], by (quintile)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 17_raw") cell(C3) firstrow(var) sheetmodify
restore



preserve
use "${temp}/expenditures_temp_pc.dta", clear
keep if quintile == 2

collapse (mean) aeq_cal_hh ae_coef_hh [aweight =hhweight], by (hhsize)
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table aeq") cell(C3) firstrow(var) sheetmodify
restore







***** Coûts des autres biens et services par groupe


use "${temp}/expenditures_temp_pc.dta", clear
drop depan
merge 1:m $var_lst_hh using  "${temp}/Other_depan.dta", keepusing(depan codpr poste_depense)
keep if _merge==3
drop _merge
* Déflateur
replace depan = depan / 12 // En mensuel
replace depan = depan / ae_coef_hh // En équivalent adulte
replace depan = depan * deftemp[2,1] * deftemp[2,2] * deftemp[2,3] * deftemp[2,4]
keep if quintile==2

* Obtenir le nombre de ménage dans le quintile
local nb_men
preserve 
	quietly bysort grappe menage: keep if _n==1 
	quietly summarize hhweight, meanonly
	local nb_men = r(sum)
	display "Nombre de ménage du quintile: `nb_men'"
restore

egen depenses = sum(depan * hhweight), by(poste_depense)
* Quantité consommée non ajustée moyenne par produit
replace depenses = depenses / `nb_men'

duplicates drop poste_depense, force
collapse (sum) depenses, by(poste_depense)

export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table postes depenses") cell(C3) firstrow(var) sheetmodify



