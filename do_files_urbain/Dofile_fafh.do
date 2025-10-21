	//Consommation hors ménage pour l'ensemble du ménage
	use "$data\s07a_1_me_CIV2021", clear
	gen hh_no = grappe * 100 + menage
	keep hh_no s07aq02b s07aq03b s07aq05b s07aq06b s07aq08b s07aq09b s07aq11b s07aq12b s07aq14b s07aq15b s07aq17b s07aq18b s07aq20b s07aq21b
	ren (s07aq02b s07aq03b s07aq05b s07aq06b s07aq08b s07aq09b s07aq11b s07aq12b s07aq14b s07aq15b s07aq17b s07aq18b s07aq20b s07aq21b) (s07aq2 s07aq3 s07aq5 s07aq6 s07aq8 s07aq9 s07aq11 s07aq12 s07aq14 s07aq15 s07aq17 s07aq18 s07aq20 s07aq21)
	reshape long s07aq, i(hh_no) j(item_cod1)
	drop if s07aq==. | s07aq==0
	recode item_cod1 (2/3=1001 "Petit dejeuner") (5/6=1002 "Dejeuner") (8/9=1003 "Diner") (11/12=1004 "Collation") (14/15=1005 "Boisson chaude") (17/18=1006 "Boisson non alcol") (20/21=1007 "Boisson alcol"), gen(item_cod)
	
	merge m:1 hh_no using "$output\hh.dta", keepusing(hh_size guest) keep (1 3) nogen
	replace s07aq=s07aq*hh_size/(hh_size+guest) //??????
	
// 	graph box s07aq, over( item_cod)
// 	*outlier detection...
	save "$output\fafh_hh", replace
	
	//Consommation hors ménage pour chaque individu du ménage
	use "$data\s07a_2_me_CIV2021", clear
	gen hh_no = grappe * 100 + menage
	keep hh_no s01q00a s07aq02 s07aq03 s07aq05 s07aq06 s07aq08 s07aq09 s07aq11 s07aq12 s07aq14 s07aq15 s07aq17 s07aq18 s07aq20 s07aq21
	ren (s07aq02 s07aq03 s07aq05 s07aq06 s07aq08 s07aq09 s01q00a) (s07aq2 s07aq3 s07aq5 s07aq6 s07aq8 s07aq9 hm_no)
	reshape long s07aq, i(hh_no hm_no) j(item_cod1)
	drop if s07aq==. | s07aq==0
	recode item_cod1 (2/3=1001 "Petit dejeuner") (5/6=1002 "Dejeuner") (8/9=1003 "Diner") (11/12=1004 "Collation") (14/15=1005 "Boisson chaude") (17/18=1006 "Boisson non alcol") (20/21=1007 "Boisson alcol"), gen(item_cod)	
// 	graph box s07aq, over( item_cod)
	save "$output\fafh_ind", replace
	
	//Fusion des deux bases de consommation hors ménage
	use "$output\fafh_hh", clear
	append using "$output\fafh_ind"
	ren (s07aq) (fd_mv) //Consommation en valeur monétaire
	
	//Later in the syntaxs I will estimate the quantities consumed for 1005, 1006 and 1007 based on at-home purchases. So,
	//I collapse the foods away from home with only monetary values into one item.
	
	//Plus loin dans les syntaxes, j’estimerai les quantités consommées pour 1005, 1006 et 1007 en fonction des achats à domicile.
	//Alors, je regroupe les aliments à l’extérieur de la maison avec seulement des valeurs monétaires en un seul article
	recode item_cod (1004 1003 1002=1001) 
	
	la def mealtype 1001 "Breakfast, Lunch, Diner and Snacks" 1005 "Warm Beverages" 1006 "Non alcoholic Drinks" 1007 "Alcoholic Drinks"
	la val item_cod mealtype
	
	collapse (sum) fd_mv, by(hh_no item_cod)
	gen fd_qty =.
	gen f_source=4
	lab def lf_source 1"Purchased" 2"own production" 3"Received in kind" 4"Prepared away from home"
	la val f_source lf_source
	save "$output\fafh_all", replace
