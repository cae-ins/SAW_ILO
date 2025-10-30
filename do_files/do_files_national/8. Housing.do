********************************************************************************
*							VIII. Estimation of housing needs
* Author: Erika Chaparro
* Date: September, 2023
********************************************************************************

* 8.1. Call the parameters
*------------------------
*include "$do_files/1. config.do"

*use "${housing}", clear
use "${temp}/housing_temp.dta", clear
merge 1:1  $var_lst_hh using "${housing}"
drop _merge




* 8.2 Construction of Housing Score 

/* NOTE: To construct the housing score we use different dwelling characteristics.  It might be the case
that for the same charachteristic we have several variables. If so, we asign a score for each variable and
then round the average of all the variables.
*/

/* REMARQUE : Pour construire le score de logement, nous utilisons différentes caractéristiques de logement.  C’est peut-être le cas
que pour la même caractéristique, nous avons plusieurs variables. Si c’est le cas, nous attribuons un score pour chaque variable et
puis arrondissez la moyenne de toutes les variables.
*/
*keep $var_lst_hh $var_lst_housing 										// Keep relevant variables

* 8.2.1 Space
*on determine le nombre de personnes par pièces
merge 1:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(hhsize region milieu)
drop _m

***************************************************************************************************************************
** CREATION DE ZONE AGROECOLIGIQUE         
***************************************************************************************************************************

*Creation des zones agro-ecologique (zae)*/
recode region (4 7 11 21 29 33=1 "CENTRE") ///
			  (2 6 12 18 27=2 "CENTRE-OUEST")  ///
              (3 8 10 14 19 20 22 23 24 28 32=3 "NORD") ///
			  (1 5 13 16 26 30=4 "SUD-EST") ///
			  (9 15 17 25 31=5 "SUD-OUEST") ///
			  (0=6 "ABIDJAN"), gen(zae)
replace zae=6 if region==1 & milieu==1 

label var zae "Zone agroecologique"


*Creation de zaemil (croisemment entre ZAE et le milieu de resisdence)
egen zaemil = group(zae milieu)
tab zaemil zae
label def zaemil 1 "CENTRE (urbain)" 2 "CENTRE (rural)" ///
				 3 "CENTRE-OUEST (urbain)" 4 "CENTRE-OUEST (rural)" ///
				 5 "NORD (urbain)" 6 "NORD (rural)" ///
				 7 "SUD-EST (urbain)" 8 "SUD-EST (rural)" ///
				 9 "SUD-OUEST (urbain)" 10 "SUD-OUEST (rural)" ///
				 11 "ABIDJAN", replace
label val zaemil zaemil

* Creation de milieu2 
	gen     milieu2 = (region==1 & milieu==1)
	replace milieu2 = 2 if milieu==1 & milieu2 ==0
	replace milieu2 = 3 if milieu==2 & milieu2 ==0
	label define milieu2 1 "Abidjan urbain" 2 "Autre urbain" 3 "Rural" 
	label values milieu2 milieu2


****
*******Création de système de notation de decence de logement*
****
	gen h_space=hhsize/s11q02    /* calcul du nombre de personne par pièce */



* NOTE: Create the scores 1 to 5  for space with the variables available in the survey 
* replace h_score_space=/*VARIABLE_CATEGORY*/ if /*SPACE_VARIABLE*/	/*=><=*/ 	/*RANGE_CATEGORY*/
gen h_score_space=.
	replace h_score_space=5 if h_space<1.5 
	replace h_score_space =4 if h_space>=1.5 & h_space<2
	replace h_score_space =3 if h_space>=2 & h_space<3  
	replace h_score_space =2 if h_space>=3 & h_space<4 
	replace h_score_space =1 if h_space>=4


*8.2.2 Material

* NOTE: Create the scores 1 to 5 for each material with the variables available in the survey. Here we can recode the categories.
* recode MATERIAL_VARIABLE  (CLASSIFY_CATEGORIES), gen (h_score_material)
	recode s11q18 (1 =5) (2=4) (3=3) (4 5 6=2) (7 8=1),gen (h_score_mur) 
	recode s11q19 (1=5) (2 3=4) (4 5 6 7=2) (8 9=1),gen (h_score_toit)  
	recode s11q20 (1=5) (2=4) (3=1) (4 5=2),gen (h_score_sol) 

	egen h_score_mat=rowtotal(h_score_mur h_score_toit h_score_sol)
	gen h_score_material=round(h_score_mat/3)

*8.2.3 Water accessibility

* NOTE: Create the scores 1 to 5 for each water access category with the variables available in the survey. Here we can recode the categories.
* recode WATER_VARIABLE  (CLASSIFY_CATEGORIES), gen (h_score_water)
	recode s11q26a(18=1)  /*coorection modalité*/
	recode s11q26a (1 2 =5) (3 4 9 10=4) (14 7 8 11 16=3) (5 6 15=2) (12 13 17=1), gen (h_score_water)


*8.2.4 Facilities

* NOTE: Create the scores 1 to 5 for each facilities category with the variables available in the survey. Here we can recode the categories.
* recode FACILITIES_VARIABLE  (CLASSIFY_CATEGORIES), gen (h_score_facilities)
	recode s11q54 (1 2 3 4 =5) (5 6=4) (7 8=3) (9=2) (10 11 12=1),gen(h_score_facilities)

*8.2.5 Total Score

	egen h_score=rowtotal(h_score_space h_score_material h_score_water h_score_facilities) 

	
****
****8.2.6 Identification du score minimum de decence (seuil de decence) d'un logement et du profil des logements*
****
**********8.2.6.a Identification du score minimum de decence d'un logement
preserve	

	gen surface_min=4  /* logt décent si moins 3 personne par pièce*/
	gen mur_min=5 /*logt dec mini si mur est Ciment/Béton/Pierres*/
	gen toit_min=4  /*logt dec mini si toit est Tôles//Tuile
 */
	gen sol_min=4  /*logt dec mini si sol est Ciment/Béton*/
	gen acc_eau_min=5 /* logt dec mini si acces eau est Forage dans la concession//Forage ailleurs//Borne fontaine/Robinet public

*/
	gen sanitaire_min=4 /* logt dec mini si sanitaire est Latrines ECO vip PLAT 
*/

	keep surface_min mur_min toit_min sol_min acc_eau_min sanitaire_min 
	duplicates drop

	egen material_min=rowmean(mur_min toit_min sol_min)
	replace material_min=round(material_min)

	egen seuil_decence=rowtotal(surface_min material_min acc_eau_min sanitaire_min )
	
	ta  seuil_decence,m
	order seuil_decence,before(surface_min)

	ta seuil_decence /* 17  le score minimum*/
	save "${outputs}\table_score_min.dta",replace
restore


**********8.2.6.b profil des logements D°*
	gen seuil_decence=17
	gen D°=100 if h_score<seuil_decence   /* 1:statut de logement non decent  */
	replace D°=0 if D°==.

	label var D° "profil_logement"
	merge 1:1 vague grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(hhweight hhid)
	drop _merge

	tab D°[aw=hhweight]   /*38.43% des ménages vivent dans des logements non décent*/
 
	tabstat D°[aw=hhweight]  ,by(region) 
	* table milieu [aw=hhweight], c(mean D°) row col /* profil des logements selon les milieux de residence  *//* 38.42512% des ménages vivent dans des logements non décent en CIV, les ménages vivant en mileu urbain vivent dans 21.12914% dans des logements non décents et contre 59.21393% pour les menages vivant en rural*/

** 
******8.2.6.c visualisation de la distribution des scores de logements ***
**
	histogram h_score , discrete  
	graph export "$outputs\Graph_distrib_des_scores.png", as(png) name("Graph") replace

	merge 1:1  $var_lst_hh using "${temp}/housing_temp.dta"
	drop _merge
	merge 1:1 $var_lst_hh using "${temp}/aeq_temp.dta"
	drop _merge

	gen rent_aeq= rent_month/ ae_coef_hh
	gen utilities_aeq= utilities_month/ ae_coef_hh
	gen freq=1
	save "${temp}\housing_score_temp.dta", replace

	merge 1:1 vague grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(hhweight)
	drop _merge

	*****determination de la taille equivalent adu de reference : le 3 quintile**
    xtile quintil_rent_aeq=rent_aeq[aw=hhweight], nq(5)
	tabstat D° ae_coef_hh rent_aeq utilities_aeq[aw=hhweight],by(quintil_rent_aeq) stat(mean)  

	*3.29 correspond a un adulte par equivalent adult***

 
preserve 

	collapse (mean) rent_aeq utilities_aeq (count) freq [aweight =hhweight], by (  h_score)
	twoway (scatter rent_aeq h_score),title(Loyer mensuel associé au score de logement décent,size(default) color(blue)) note(Estimation basée sur l’EHCVM 2021, size(small) color(black))

graph export "$outputs\Graph_Loyer mensuel associé au score.png", as(png) name("Graph") replace

	twoway (scatter utilities_aeq h_score),title(Dépenses mensuelles des charges par score de logement,size(default) color(blue))  note(Estimation basée sur l’EHCVM 2021, size(small) color(black))

	graph export "$outputs\Graph_Dépenses mensuelles des charges au score.png", as(png) name("Graph") replace 
	
	gen milieu2="National"
	order milieu2,before(h_score)
	export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 12a_raw") cell(C3) firstrow(var) sheetmodify
	save "${temp}\rent_charge_nat_temp.dta", replace


restore

preserve

	collapse (mean) rent_month  rent_aeq utilities_aeq (p50) med_rent_m=rent_month med_rent_aeq=rent_aeq h_space h_score_space h_score_mur h_score_toit h_score_sol h_score_mat h_score_material h_score_water h_score_facilities (count) freq [aweight = hhweight] ,by(h_score)     
	keep h_space h_score_space h_score_mur h_score_toit h_score_sol h_score_water h_score_facilities h_score
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table_comoditie_logt") cell(C3) firstrow(var) sheetmodify


restore

* NOTE: Rent estimations can be disaggregated to urban/rural or regions -> to do so, modify the code below. 
//* REMARQUE : Les estimations de loyer peuvent être désagrégées en urbain/rural ou régions 
//> pour ce faire, modifiez le code ci-dessous.

***
***** A- PRESENTATION DES STATISTIQUES SUR LES LOYERS A PARTIR DE L'EHCVM
***
preserve
collapse (mean) rent_month rent_aeq (p50) med_rent_m=rent_month med_rent_aeq=rent_aeq (count) freq [aweight = hhweight]
sort rent_month med_rent_m rent_aeq med_rent_aeq freq
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table 9_raw") cell(C3) firstrow(var) sheetmodify
restore

preserve
collapse (mean) rent_month rent_aeq (p50) med_rent_m=rent_month med_rent_aeq=rent_aeq (count) freq [aweight = hhweight], by(milieu)
sort rent_month med_rent_m rent_aeq med_rent_aeq freq
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table loyer_milieu") cell(C3) firstrow(var) sheetmodify
restore

preserve
collapse (mean) rent_month rent_aeq (p50) med_rent_m=rent_month med_rent_aeq=rent_aeq (count) freq [aweight = hhweight], by(region)
sort rent_month med_rent_m rent_aeq med_rent_aeq freq
export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table loyer_region") cell(C3) firstrow(var) sheetmodify
restore

***** B-EVALUATION DU COUT DE LOYER ET CHARGE  SELON LE SCORE DE DECENCE MINIMAL D°= 14 
********************************************************************************
      
	  
	  *** Winsorization
	  *ssc install winsor
	  winsor2 rent_aeq, cuts(5 95) suffix(_w)
	  winsor2 utilities_aeq, cuts(5 95) suffix(_w)
	   
	   
	   
	   ////*** ZONE NATIONALE ********////
			*1- Determination du cout de loyer décent de score  14 

			
		
		nl (rent_aeq_w={A}*(exp({b}*h_score))) /*regression exponentiel du cout loyer (rent_aeq) sur le score final*/
		ereturn list
		matrix list e(b)  /* on visualise et recupere les coef des parametres*/
		gen coef_A=_b[/A ]    
		gen coef_b=_b[/b]    
		di coef_A /*coef_A = 18.848841 */
		di coef_b /* coef_b = .36980841*/
	
	**calcul du cout loyer pour le score minimum de decence de logement de à partir des coef_A, coef_b des parametre de regression exponentiel***
	
		gen Ct_loyer_scormin=coef_A*exp(coef_b*17)
		di Ct_loyer_scormin
    /*le coût du loyer pour un logement minimum décent au niveau national s’élève à 3340.1436 F CFA pour 1 adulte par équivalent adulte.*/

			*2- Determination du cout de charge de score 14      
	
		nl (utilities_aeq_w={C}*(exp({d}*h_score))) /*regression exponentiel du cout des charge sur le score final*/
		
		matrix list e(b)
		gen coef_C=_b[/C ]
		gen coef_d=_b[/d]
		di coef_C /*coef_C= 14.249012*/
		di coef_d /*coef_d=  .30735463*/
		gen Ct_charg_scor_min=coef_C*exp(coef_d*17)
		di Ct_charg_scor_min /*1053.2673 FCFA est la charge pour un logement au niveau national*/
	
			*3-Estimation du cout mensuel total (loyer+charge = CT_log_scoremin)                                               *

		gen CT_log_scoremin=Ct_loyer_scormin+Ct_charg_scor_min
		di CT_log_scoremin   /*4393.4111 F CFA est le cout totalt mensuel eaqdu en côte d'ivoire */
	
			*4- estimation du cout total d'un logement décent de score 14 d'une famille de reference dont la taille est de 5 membres
		drop interview__key interview__id vague s11*
		keep  Ct_loyer_scormin Ct_charg_scor_min CT_log_scoremin
		duplicates drop
		gen tail_eaqu=3.29
		gen CT_familleaeq=CT_log_scoremin*tail_eaqu
		replace CT_familleaeq=round(CT_familleaeq)/* echelle OCED du menage cor 3.29*/
		di CT_familleaeq /*14630 fr cfa le cout total d'une famille de 5 personne en equi adui*/
		
		gen Pays="Côte d'Ivoire"
		order Pays,before(Ct_loyer_scormin)
		*save "${temp}\base_loyer_decence_National.dta",replace


export excel "${outputs}\COUNTRY_ESTIMATES.xlsx", sheet("Table CT_familleaeq") cell(C3) firstrow(var) sheetmodify


