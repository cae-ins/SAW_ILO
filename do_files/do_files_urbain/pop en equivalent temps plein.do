

use "${data}\s01_me_CIV2021.dta" , clear


merge 1:1 vague grappe menage individu using "$employment"
	keep if _merge==3
	drop _merge

merge m:m vague grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta"
	keep if _merge==3
	drop _merge
	
merge m:1 grappe menage using "${temp}/expenditures_temp.dta"
	keep if _merge==3
	drop _merge


********************************************************************************
********************************************************************************
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*			      Working age population ('ilo_wap')	                       *
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------

	gen ilo_wap=.
		replace ilo_wap=1 if s01q03c<=2008
			    label define label_ilo_wap 1 "1 - Working-age Population"
				label value ilo_wap label_ilo_wap
				label var ilo_wap "Working-age population"

* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*			       Labour Force Status ('ilo_lfs')                             *       
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------

    * Employment

    * Labour Force Status	parmi ceux en age de travailler
	gen ilo_lfs=.
        replace ilo_lfs=1 if ilo_wap==1 & (s04q06==1 | s04q07==1 | s04q08==1 | s04q09==1 | s04q13==1 | s04q14==1) | s04q11==1												// Employed: ILO definition ou temporary absent 
		replace ilo_lfs=2 if ilo_wap==1 & s04q17==1  & inlist(s04q20,1,2) & ilo_lfs!=1 	// Unemployed: three criteria
		* replace ilo_lfs=2 if ilo_lfs_notemp_futur==1 & ilo_lfs_notemp_avail==1 & ilo_lfs!=1 	// Unemployed: available future starters
	    replace ilo_lfs=3 if ilo_wap==1 & !inlist(ilo_lfs,1,2) 												// Outside the labour force
				label define label_ilo_lfs 1 "1 - Employed" 2 "2 - Unemployed" 3 "3 - Outside Labour Force"
				label value ilo_lfs label_ilo_lfs
				label var ilo_lfs "Labour Force Status" 

* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*			       Status in employment ('ilo_ste')                            * 
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------

   * MAIN JOB
   
	 gen ilo_job1_ste_icse93=.
		 replace ilo_job1_ste_icse93=1 if inlist(s04q39,1,2,3,4,5,6,7) & ilo_lfs==1 // Employees
		 replace ilo_job1_ste_icse93=2 if s04q39==10 & ilo_lfs==1          			// Employers
		 replace ilo_job1_ste_icse93=3 if s04q39==9 & ilo_lfs==1          			// Own-account workers
		 * replace ilo_job1_ste_icse93=4 if  & ilo_lfs==1          					// Members of producers' cooperatives
		 replace ilo_job1_ste_icse93=5 if s04q39==8 & ilo_lfs==1          			// Contributing family workers
		 replace ilo_job1_ste_icse93=6 if ilo_job1_ste_icse93==. & ilo_lfs==1   	// Workers not classifiable by status
		 
		 replace ilo_job1_ste_icse93=. if ilo_lfs!=1
				 label def label_ilo_ste_icse93 1 "1 - Employees" 2 "2 - Employers" 3 "3 - Own-account workers" ///
				                                4 "4 - Members of producers' cooperatives" 5 "5 - Contributing family workers" ///
												6 "6 - Workers not classifiable by status"
				 label val ilo_job1_ste_icse93 label_ilo_ste_icse93
				 label var ilo_job1_ste_icse93 "Status in employment (ICSE 93) - Main job"
		
		
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*	Population en équivalent temps plein ('pop_etp')                           *       
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------		

preserve
keep if ilo_job1_ste_icse93 == 1
gen ind = 1
collapse (sum) ind, by(quintile region vague grappe menage hhsize hhweight milieu)

svyset 	[pw = hhweight]
svy: mean ind 

restore

preserve
keep if ilo_lfs == 1
gen indi = 1
collapse (sum) indi, by(quintile region vague grappe menage hhsize hhweight milieu)

svyset 	[pw = hhweight]
svy: mean indi  

restore



* Garder seulement que les ménages ayant au moins un salarié

bysort vague grappe menage: egen au_moins_un_salarie = max(ilo_job1_ste_icse93 == 1)
keep if au_moins_un_salarie == 1

gen nb_heure_travail_mensuelle =  cond(missing(s04q56), 0, s04q56) * cond(missing(s04q55), 0, s04q55) + cond(missing(s04q36), 0, s04q36) * cond(missing(s04q37), 0, s04q37)

gen pop_etp=.
		 replace pop_etp=1  if nb_heure_travail_mensuelle >= 160
		 replace pop_etp= nb_heure_travail_mensuelle/160 if nb_heure_travail_mensuelle < 160


collapse (sum) pop_etp, by(quintile region vague grappe menage hhsize hhweight milieu)

svyset 	[pw = hhweight]
svy: mean pop_etp , 
                                             // Nombre moyen d'individu en équivalent temps plein par region
svy: mean pop_etp  

*matrix list e(b)
*scalar nb_emploi_tps_plein = e(b)[1,1]                                                             // Nombre moyen d'individu en équivalent temps plein total
*scalar define nb_emploi_tps_plein = e(b)[1,1]
*table region, statistic(sum hhweight)                                            // Nombre de ménage ayant au moins un salarié, par region


svy: mean pop_etp
matrix results = r(table)  // Sauvegarde les résultats dans une matrice
scalar nb_emploi_tps_plein = results[1,1]  // La moyenne estimée est à la première ligne et première colonne
	
		