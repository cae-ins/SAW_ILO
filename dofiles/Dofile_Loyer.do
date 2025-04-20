/*global dim_logement "C:\Users\spcom\OneDrive\Bureau\Projet Salaire vital" // Insert the working path

* 2. Directory paths
*-------------------

global data    	"$dim_logement\data" // Insert the path from the raw data
global outpts 	"$dim_logement\outpts" // Insert the path to the outputs (Excel File)
global temp 	"$dim_logement\temp" // Insert the path to the temporary files
global do_files "$dim_logement\do_files" // Insert the path to the do-files


* Raw data by category 
*global hh_ind "$data\hh_ind\data_hh.dta"
*global housing "$data\housing\data_housing.dta"

global hh_ind "$dim_logement\data\hh_ind" // Insert the path from the raw data
global housing "$dim_logement\data\housing" 
glo pays "CIV2021"

*/
*use "${data}\s11_me_${pays}.dta", clear
use "${data}/s11_me_CIV2021", clear

*drop if s11q01==. | s11q01==.a /* conserver les questionnaires valides */
destring grappe, replace
/*merge m:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta"
keep if _merge==3
drop _merge  

****Rappel contenu des variables
* s11q04 (statut d'occupation) 
*s11q05 (loyer potentiel propriétaire) *s11q06 (loyer mensuel locataire)
* s11q23a s11q23b (facture eau et périodicité); s11q25 (eau revendeur) 
* s11q36a s11q36b (facture elec. et périod.) 
* s11q44a s11q44b (telephone fixe et périod.)
* s1147a et s1147b (internet et period.) 
* s11q51a s11q51b (cable et périod.) 

sum s11q05 s11q06 s11q23a s11q25 s11q36a s11q44a  /// 
s11q47a s11q51a 
recode s11q05 s11q06 s11q23a s11q25 s11q36a s11q44a s11q47a s11q51a (99 999 9999 99999 999999 . .a=0)

clonevar s11q5a=s11q05
clonevar s11q6a=s11q06
clonevar s11q25a=s11q25

gen s11q5b=5
gen s11q6b=2
gen s11q25b=2


*****loyer annuel pour les propriétaires
gen depan5=s11q05*12

*****loyer annuel pour les locataires
gen depan6=s11q06*12

****dépenses annuelles auprès des revendeurs
gen depan25=s11q25*365/30

****dépenses annuelles de facture éau (s11q23a); facture électricité (s11q36a); fcature telephone (s11q44a), facture abonnement internet (s11q47a); facture abonnement cable(s11q51a)

foreach x in 23 36 44 47 51 {
 tab1 s11q`x'b 
 gen depan`x'=s11q`x'a*52 if s11q`x'b==1
 replace depan`x'=s11q`x'a*12 if s11q`x'b==2
 replace depan`x'=s11q`x'a*6 if s11q`x'b==3
 replace depan`x'=s11q`x'a*4 if s11q`x'b==4
   }
 
 
merge m:1 grappe menage using "$datain_men\s00_me_${pays}.dta", ///
  keepusing(vague s00q08)
  drop if s00q08==3
  drop _merge
*
keep grappe menage depan5 depan6 depan23 depan25 depan36 depan44 depan47 depan51 vague zae region milieu
reshape long depan, i(grappe menage vague zae region milieu) j(codpr)

recode codpr (5=330) (6=331) (23=332) (25=333) (36=334) (44=335) (47=336) (51=337)
drop if depan==0 | depan==.
sum depan  
sum depan if codpr!=330 
lis grappe menage codpr depan if depan>=100000000 & codpr!=330 //aucun cas
gen modep=1
order grappe menage codpr modep
sort grappe menage codpr
compress
save "$dataout_temp\Dep_Logement.dta", replace
*/

***********
*********** Partie 4: loyer impute (propro et gratuit) - Section 11 ************
***********

*use "$hh_ind\s01_co_${pays}.dta", clear
use "${data}/Commune/s01_co_CIV2021", clear
duplicates report grappe                        
keep grappe s01q05 s01q06 s01q08__1 s01q08__2 s01q08__3 s01q08__4 s01q11 ///
     s01q12 s01q13a__1 s01q13a__2 s01q13a__3 s01q13a__6 s01q13b__1 s01q13b__2 s01q13b__3 s01q13b__6 s01q13b__7

tab1 s01q06 s01q08__1 s01q08__2 s01q08__3 s01q08__4 s01q11 ///
     s01q12 s01q13a__1 s01q13a__2 s01q13a__3 s01q13a__6 s01q13b__1 s01q13b__2 s01q13b__3 s01q13b__6 s01q13b__7, m	 
gen route_goud=s01q06==1	
gen route_late=s01q06==2

gen dist_vill=s01q05
gen ldist_vill=ln(dist_vill) if dist_vill>0
gen route_autre=inlist(s01q06,3,4,5,6) //ajout
gen trans_moto=s01q08__1==1	
gen trans_voit=s01q08__2==1
gen trans_autre=s01q08__3==1 | s01q08__4==1 //ajout
gen reseau_elec=s01q11==1
gen reseau_eau=s01q12==1
gen reseau_tel=s01q13a__1==1| s01q13a__2==1| s01q13a__3==1| s01q13a__6==1  

keep grappe dist_vill ldist_vill route_goud route_late route_autre trans_moto trans_voit trans_autre reseau_elec ///
     reseau_eau reseau_tel
	 
sort grappe
duplicates drop grappe, force
save  "$temp\Infra_com.dta", replace

*	 
*use "$housing\s11_me_${pays}.dta", clear
use "${data}/s11_me_CIV2021", clear

drop if s11q01==. | s11q01==.a /* conserver les questionnaires valides */
destring grappe, replace
merge 1:1 grappe menage using "${data}/ehcvm_welfare_2b_CIV2021.dta", keepusing(hhsize hhweight)
drop _m
*merge 1:1 grappe menage using "$dataout_temp\ehcvm_men_temp.dta", keepusing (zae region milieu hhsize )
*keep if _merge==3
*drop _merge  
/*
preserve
  use "$dataout_temp\Dep_Nalim.dta", clear
  keep if codpr==330 | codpr==331  /* On récupère le loyer payé et le loyer fictif autodéclaré */
  recode depan (.=0)
  gen loyer=depan if codpr==331
  gen loyer_auto=depan if codpr==330
  collapse (sum) loyer=loyer loyer_auto=loyer_auto, by(grappe menage)
  lab var loyer "loyer locataire"
  lab var loyer_auto "loyer auto-declaré"
  sort grappe menage
  sum loyer loyer_auto,det 
  save "$dataout_temp\Loyer.dta", replace
restore

merge 1:1 grappe menage using "$dataout_temp\Loyer.dta" /* 10 ménages dans le fichier ménage absent de la base temporaire loyer, car ils sont logés gratuitement*/
drop _merge
erase "$dataout_temp\Loyer.dta"
*/


/*
merge 1:1 grappe menage using "$temp\hh_wgt_size.dta"
*, keepusing (hhweight)
tab _m
drop _m
rename poids hhweight
*/

merge 1:1 grappe menage using "${data}/s00_me_CIV2021.dta", keepusing (s00q03 s00q01 s00q02 s00q05 s00q04 s00q08)
drop if s00q08==3
tab _m
drop _m
/*
ren s00q05 quartier 
ren s00q02 departement
ren s00q03 sous_prefecture
ren s00q01 region
*/
clonevar quartier = s00q05  
clonevar departement = s00q02 
clonevar sous_prefecture = s00q03 
clonevar region = s00q01 
clonevar milieu = s00q01


tab quartier,gen(quartier)

tab departement,gen(departement)

gen abj=.
replace abj=1 if inlist(quartier,201005,201006,201009,201007) //Abidjan sud

replace abj=2 if inlist(quartier,201002,201003) //Adjame et Attecoube
replace abj=3 if inlist(quartier,201004,203997) //Cocody et Bingerville

replace abj=4 if inlist(quartier,201001,202997) //Abobo et Anyama

replace abj=5 if inlist(quartier,201010,205012,202005) //Yopougon,Songon,Akoupe Zeudji

replace abj=6 if quartier==201008 //Port Bouet

label define abj 1"Abj sud" 2"Adj attec" 3"cocody binge" 4"abobo anyama" 5"yop songon" 6"port bouet"
label val abj abj 

clonevar  loyer=s11q06
clonevar loyer_auto=s11q05
recode loyer (.=0)
tabulate region, gen(region)
*tabulate zae, gen(zae)
*gen urbain=(milieu==1)

tab1 s11q01 s11q04 s11q03__1 s11q03__2 s11q03__3 s11q18 s11q19 s11q20 ///
     s11q21 s11q33 s11q53 s11q54 s11q55 s11q57 s11q58 s11q59, m 
sum s11q02 

gen locat=(inlist(s11q04,5,9))
gen flag=(locat==1 & loyer==0)  /* Identification de locataires sans loyer */
tab flag     /* aucun cas dans cette situation */
drop flag
gen flag=(locat!=1 & loyer>0 & loyer<.) /* Identification de non locataires avec loyer */
tab flag   /* aucun cas dans cette situation */
list grappe menage locat loyer if flag==1
replace locat=0 if locat==1 & loyer==0
drop flag 


gen lnloyer=ln(loyer) if locat==1


//on recode les types de logement
recode s11q01 (1 2 6=1) (3 4=2) (5=3) (7 8=4) (9=5), gen(typlog)
label define typlog 1 "Maison moderne" 2 "Bande de maison" 3 "Cour commune" 4 "Maison isolée" 5 "Autre"
label val typlog typlog
tab typlog, m

*/


lis grappe menage s11q02 if s11q02>25 
gen npiece=s11q02
egen mnpiece=median(npiece), by(milieu)
replace npiece=mnpiece if s11q02>25 & s11q02<. 
gen lnpiece=ln(npiece)

// Pour les 3 variables, on a remplacé la commande clonevar par gen, créer une variable 0/1 

gen clim=s11q03__1
gen chauffe=s11q03__2
gen ventilo=s11q03__3

gen eau=(s11q21==1)
gen elec_direct=(s11q33==1)
gen elec_paral=(inlist(s11q33,2,3))

recode s11q18 (1 2 3 4=1) (5 6 7 8=2), gen(mur) 
label define mur 1 "Moderne" 2 "Non moderne"
label val mur mur

recode s11q19 (1 2 3=1) (4 5 6 7 8 9=2), gen(toit) 
label define toit 1 "Moderne" 2 "Non moderne"
label val toit toit

recode s11q20 (1=1) (2=2) (3/5=3), gen(sol) 
label define sol 1"marbre" 2"ciment" 3"non moderne"
label val sol sol

recode s11q53 (1=1) (2=2) (3 4 5 6=3), gen(ordures)
label define ordures 1 "Dépotoir public" 2 "Ramassage" 3 "Non moderne"
label val ordures ordures

recode s11q54 (1 3=1) (2 4=2) (5 6 7=3) (8 9 10 12=4) (11=5), gen(toilet) 
label define toilet 1"WC interne" 2"WC externe" 3"Latrines modernes" 4"Toilettes non modernes" 5"Pas de toilettes"
label val toilet toilet

recode s11q58 (1=1) (2 3 4 5 6 7=2), gen(excre) 
label define excre 1"moderne" 2"non moderne"
label val excre excre

recode s11q59 (1=1) (2 3 4 5=2), gen(eausee)
label define eausee 1"moderne" 2"non moderne"
label val eausee eausee 

tabulate typlog, gen(typlog)
tabulate toit, gen(toit)
tabulate mur, gen(mur)
tabulate sol, gen(sol)
tabulate toilet, gen(toilet)
tabulate ordures, gen(ordures)
tabulate excre, gen(excre)
tabulate eausee, gen(eausee)
tabulate abj, gen(abj)

merge m:1 grappe using "$temp\Infra_com.dta"
drop _merge

recode route_goud route_late trans_moto trans_voit reseau_elec reseau_eau reseau_tel (.=0)

gen zone=.
replace zone=1 if region==1
replace zone=2 if region!=1 & s00q04==1
replace zone=3 if region!=1 & s00q04==2


tab zone locat  /* Effectif locataires: 680 à Abidjan, 1 659 autre urbain et 368 rural; on essaye les régressions */

// Comparaison des caracteristiques du logement des proprietaires et locataires 

*** Abidjan


sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* abj* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==1 & locat==0   // Proprietaire à Abidjan

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* abj* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==1 & locat==1   // Locataire à Abidjan

reg lnpiece locat [w=hhweight*hhsize] if zone == 1  // p=0.000	 

*** Urban	

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==2 & locat==0   // Proprietaire dans le reste du milieu urbain
		
sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==2 & locat==1   // Locataire dans le reste du milieu urbain
	
reg lnpiece locat [w=hhweight*hhsize] if zone == 2 // p=0.000	
	
*** Rural 

sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==3 & locat==0   // Proprietaire en milieu rural
		
sum lnloyer locat lnpiece typlog* clim chauffe ventilo eau elec_direct elec_paral mur* toit* sol* ///
	toilet* ordures* excre* eausee* route_goud route_late ///
	trans_moto trans_voit reseau_elec reseau_eau reseau_tel [w=hhweight*hhsize] ///
	if zone==3 & locat==1   // Locataire en milieu rural 
	
reg lnpiece locat [w=hhweight*hhsize] if zone == 3 // p=0.000	
*	
*
******** Regression Abidjan


****zone 1


***abidjan global (r2=0.75 n=662 )
stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel abj1-abj5 if zone==1 
* Stocker la liste des variables de stepwise

mat list e(b)
mat A_Abidjan = e(b)  // 15 variables, y compris la constante _cons

local ncols = colsof(A_Abidjan)
local nvars = `ncols'-1
matselrc A_Abidjan A_vars_Abidjan, c(1/`nvars')  // sans la constante _cons 
local var1: colnames A_vars_Abidjan

reg 	lnloyer `var1' if zone==1 
predlog loyer `var1' if zone==1 

rename YHTSMEAR Abidjan_YHTSMEAR_new1   
drop YH*	

// Comparer les techniques d'imputation - Abidjan
gen loyer_imp=Abidjan_YHTSMEAR_new1 if locat==0 & zone==1 
gen loyer_eff=loyer if locat==1 & zone==1  

tabstat loyer_eff loyer_imp loyer_auto if zone==1 , stat(count min p25 mean median p75 max)  
/*
twoway (kdensity Abidjan_YHTSMEAR_new1 if locat==0 & zone==1 , title(Abidjan) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 , legend(label (2 "actual rent"))) 

graph export "$prog\rent_Abidjan_1.tif", replace

twoway (kdensity Abidjan_YHTSMEAR_new1 if locat==0 & zone==1 , title(Abidjan) legend(label (1 "imputed rent"))) ///
(kdensity loyer if locat==1 & zone==1 , legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==1, legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_Abidjan_2.tif", replace	*/

***********************

******** Regresssion Intérieur du pays - URBAN (n=1556 r2=0.68)

// Rejet des variables non significatives au seuil de 10% (p>.1)

stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel region2-region32 departement3-departement6 departement8-departement12 departement14-departement15 departement17-departement22 departement25-departement26 departement28-departement31 departement34-departement36 departement38 departement41-departement42 departement44-departement48 departement50 departement53-departement55 departement58-departement62 departement64 departement68-departement76 departement78 departement80 departement82 departement85-departement86 departement88-departement101 departement105-departement107  if zone==2


* Stocker la liste des variables de stepwise
mat list e(b) 
mat A_urb = e(b)  // 40 variables, y compris la constante _cons

local ncols = colsof(A_urb)
local nvars = `ncols'-1
matselrc A_urb A_vars_urb, c(1/`nvars')  // sans la constante _cons 
local var_urb: colnames A_vars_urb

reg 	lnloyer `var_urb' if zone==2
predlog loyer `var_urb' if zone==2

rename YHTSMEAR URB_YHTSMEAR_new
drop YH*

// Comparer les techniques d'imputation - Autre urbain

replace loyer_imp=URB_YHTSMEAR_new if locat==0 & zone==2
replace loyer_eff=loyer if locat==1 & zone==2

tabstat loyer_eff loyer_imp loyer_auto if zone==2, stat(count min p25 mean median p75 max)  
/*
twoway (kdensity URB_YHTSMEAR_new if locat==0 & zone==2, title(Urban) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==2, legend(label (2 "actual rent"))) 
graph export "$prog\rent_urb.tif", replace

twoway (kdensity URB_YHTSMEAR_new if locat==0 & zone==2, title(Urban) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==2, legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==2, legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_urb2.tif", replace
*/
*
******** Regression Intérieur du pays - Rural

// Rejet des variables non significatives au seuil de 10% (p>.10)

stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece clim chauffe ventilo typlog1-typlog3  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3 /// 
				ordures1 ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau region2-region32 if zone==3

****test
stepwise, pr(.10) pe(.09) forward : reg lnloyer lnpiece ldist_vill clim chauffe typlog1-typlog3 typlog5  ///
				eau elec_direct elec_paral mur1 sol1 sol2 ///
				toilet1-toilet3  /// 
				ordures1-ordures2 eausee1 /// 
				excre1 route_goud route_late ///
				trans_moto trans_voit reseau_elec reseau_eau reseau_tel region3-region32 departement3-departement6 departement8 departement9 departement11 departement12 departement14-departement15 departement17-departement22 departement25-departement26 departement28-departement31 departement34-departement36 departement38 departement41-departement42 departement44 departement45 departement47-departement48 departement50 departement53-departement55 departement58-departement62 departement68-departement76 departement78 departement80 departement82 departement86 departement88 departement89 departement90 departement92-departement98  departement100 departement101 departement107  if zone==3

* Stocker la liste des variables de stepwise
mat list e(b) 
mat A_rur = e(b)  // 20 variables, including _cons
local ncols = colsof(A_rur)
local nvars = `ncols'-1

matselrc A_rur A_vars_rur, c(1/`nvars')  // sans la constante _cons term
local var_rur: colnames A_vars_rur


reg 	lnloyer `var_rur' if zone==3
predlog loyer `var_rur' if zone==3

rename YHTSMEAR RUR_YHTSMEAR_new
drop YH*

// Comparer les techniques d'imputation - Rural

replace loyer_imp=RUR_YHTSMEAR_new if locat==0 & zone==3
replace loyer_eff=loyer if locat==1 & zone==3

tabstat loyer_eff loyer_imp loyer_auto if zone==3, stat(count min p25 mean median p75 max)  
/*
twoway (kdensity RUR_YHTSMEAR_new if locat==0 & zone==3, title(Rural) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==3, legend(label (2 "actual rent"))) 

graph export "$prog\rent_rur.tif", replace

twoway (kdensity RUR_YHTSMEAR_new if locat==0 & zone==3, title(Rural) legend(label (1 "revised imputation"))) ///
(kdensity loyer if locat==1 & zone==3, legend(label (2 "actual rent"))) ///
(kdensity loyer_auto if locat==0 & zone==3, legend(label (3 "imputed dec. rent")))

graph export "$prog\rent_rur2.tif", replace*/

bys zone: sum loyer 		if locat == 1, detail 
bys zone: sum loyer_imp 	if locat == 0, detail 
bys zone: sum loyer_auto 	if locat == 0, detail 

*** Conclusion: loyer auto-déclaré trop élevé, on retient le loyer imputé par régression
/*
drop quartier* departement* region* zae* typlog* locat lnloyer typlog npiece mnpiece /// 
lnpiece clim chauffe ventilo eau elec_direct elec_paral mur toit sol ordures toilet excre ///
eausee toit* mur* sol* toilet* ordures* excre* abj* route_goud route_late dist_vill ldist_vill ///
route_autre trans_moto trans_voit trans_autre reseau_elec reseau_eau reseau_tel zone ///
eausee1 Abidjan_YHTSMEAR_new1 URB_YHTSMEAR_new RUR_YHTSMEAR_new
*/

gen loyer_impute= loyer_eff
replace loyer_impute= loyer_imp if loyer_impute==.

count if loyer_impute==.
 