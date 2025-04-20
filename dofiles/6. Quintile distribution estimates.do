********************************************************************************
* 							VI. Quintile distribution
* Author: Layembe Parfait & Doho Latif
* Date: Novembre, 2024
********************************************************************************

* 1. Call the parameters
*------------------------
*include "$do_files/1. config.do"

* Log to save file in stata
*log using "${outpts}/COTE D'IVOIRE_log.log", replace

* 2. Import final datasets
use "${temp}/expenditures_temp.dta", clear

merge 1:1 $var_lst_hh using "${temp}/cal_intake_hh.dta"
drop _merge

* Generate aditional variables
gen food_exp_aeq=food_exp/aeq_cal_hh 
gen educ_exp_pc=educ_exp_hh_month/effectif_depan_educ
gen health_exp_pc=health_exp_month/effectif_depan_health
gen other_exp_month_aeq=other_exp_month/ae_coef_hh

save "${temp}/expenditures_temp_pc.dta", replace
* 3. Tabulate distribution of relevant variables
 //recuperer la taille du ménage et le poids du ménage
merge m:1 grappe menage using "$data\ehcvm_welfare_2b_CIV2021.dta", keepusing(hhsize hhweight) nogen

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
drop _merge
*gen food_exp_aeq=food_exp/ae_coef_hh 
tabstat total_exp_aeq food_exp_aeq hhsize cal_day_aeq ae_coef_hh [aweight =hhweight], by(quintile)
tabstat total_exp_aeq food_exp_aeq [aweight =hhweight], by(quintile) s(sum mean)
tabstat cal_day_aeq [aweight =hhweight], by(quintile) s(sum mean)
collapse (mean)  total_exp_aeq food_exp_aeq hhsize cal_day_aeq ae_coef_hh (count) freq [aweight =hhweight], by (quintile)
*collapse (mean)  total_exp_aeq food_exp_aeq hhsize cal_day_aeq ae_coef_hh (count) freq , by (quintile)
export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 2_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) hhsize aeq_cal_hh (count) freq [aweight =hhweight], by (quintile)
export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 6_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) ae_coef_hh aeq_cal_hh (count) freq [aweight =hhweight], by (quintile)
export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 7_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) health_exp_pc educ_exp_pc (count) freq [aweight =hhweight], by (quintile)
export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 16_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
use "${temp}/expenditures_temp_pc.dta", clear
gen freq=1
collapse (mean) other_exp_month other_exp_month_aeq (count) freq [aweight =hhweight], by (quintile)
export excel "${outpts}\COUNTRY_ESTIMATES.xlsx", sheet("Table 17_raw") cell(C3) firstrow(var) sheetmodify
restore
