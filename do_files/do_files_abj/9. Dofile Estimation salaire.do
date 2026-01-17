
*********************************
*
*	Estimation du salaire minimum
*
*********************************

*===========================================
* ETAPE 1: Estimer le coût total des besoins
*===========================================
use "${temp}/COUNTRY_YEAR_FB_HH_temp.dta", clear
duplicates drop grappe menage, force
merge 1:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(region milieu)
keep if _merge==3
drop _merge
/*Taille de famille de référencePrendre la moyenne au niveau 
nationale et arrondir au nombre entier le plus proche
*/


tabstat food_exp_aeq educ_exp_pc health_exp_pc other_exp_month_aeq [aw=hhweight], statistics(mean)    save 

// Pour obtenir les dépenses totales de chaque dimension
scalar define food_aeq =  r(StatTotal)[1,1]
scalar define education_pc =  r(StatTotal)[1,2]
scalar define health_pc =  r(StatTotal)[1,3]
scalar define other_aeq =  r(StatTotal)[1,4] 
scalar define CT_log_scoremin = 9149.2138671875 

                                        
scalar define cout_total =  food_aeq * aeq_calhh + CT_log_scoremin *  ae_coefhh + education_pc * 5 + health_pc * 5 + other_aeq * ae_coefhh  // En utlisant les coûts de logement avec pondération dépenses

scalar define salaire_v = cout_total / nb_emploi_tps_plein

/* gen cout_total=(total_exp_aeq+CT_familleaeq)*ae_coef_hh */


*===================================================================
* Etape no 2: Estimer le montant du salaire permettant de couvrir 
*le coût total des besoins des travailleurs et de leur famille
*===================================================================

//Hypothèse1: 1 travailleurs à temps plein par ménage
gen salaire1=cout_total

//Hypothèse2: 1,5 travailleurs à temps plein par ménage
gen salaire2=cout_total/1.5

//Hypothèse3: 2 travailleurs à temps plein par ménage
gen salaire3=cout_total/2

//Hypohtèse : Estimation locale du nombre de personnes en emploi en équivalent temps plein
gen salaire_v = cout_total/nb_emploi_tps_plein

tabstat salaire1 salaire2 salaire3 salaire_v, statistics(mean)    save 
