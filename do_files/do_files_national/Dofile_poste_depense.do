
**6.1.	Consommation des ménages 

***6.1.1.	Structure de la consommation des ménages
*Création des postes de dépenses sur la base de la classification de la COICOP
			*================
			*		2021	*
			*================
	use "${data}\ehcvm_conso_CIV2021.dta",clear
	
	// Les biens et services vitaux uniquement
	keep if inlist(codpr, 835, 318, 804, 511, 317, 510, 512, 207, 803, 418, 417, 818, 820, 504, 503, 650, 621, 505, 810, 502, 506, 402, 307, 822, 616, 622, 507, 625, 819, 651)
	
	/* drop if (codpr>=603 & codpr<=608) | (codpr>=611 & codpr<=614) |  /// Supression des dépenses d'investissement de logement
	(codpr>=617 & codpr<=619) | /// Appareils électromenagers, plaque solaire et batterie pour plaque solaire
	(codpr>=626 & codpr<=627) | /// Achat de voiture et moto personnelle
	(codpr>=637 & codpr<=639) | /// Téléphone portable, appreil musique, ordinateur
	(codpr==645 | codpr==656) | /// Pélérinage, formation, frais particulier, bijoux de luxe
	(codpr>=774 & codpr<=777) | ///Hospitalisation, accouchement, correcteur, béquille
	(codpr>=901) ///Dépenses fêtes et cérémonies
*/
	gen poste_depense=.
	replace poste_depense =1 if ( (codpr >= 1 & codpr<=163) | (codpr>=166 & codpr<=177) | (codpr>=191 & codpr<=196) | codpr==217 | codpr==333 )
	replace poste_depense =2 if ( codpr==164 | codpr==165 | codpr==197 | codpr==201 | codpr==301 | codpr==302)		
	replace poste_depense =3 if (codpr ==309 | codpr ==401 | (codpr>=501 & codpr<=512) |codpr ==521 )		
	replace poste_depense =4 if ((codpr >= 202 & codpr<=205) | codpr ==304 | codpr ==310 | codpr ==331 | codpr ==332 | codpr ==334 | ///
		codpr ==601 | codpr ==602 | (codpr>=609 & codpr<=612) | codpr ==653)
	replace poste_depense =5 if (codpr ==206 | codpr ==207|codpr ==303|codpr ==307 |codpr ==308 |codpr ==320 |codpr ==402 |(codpr >=613 & ///
		codpr<=625) |codpr ==640 |codpr ==641 | (codpr >=801 & codpr <=819) | (codpr >=824 & codpr <=827))	
	replace poste_depense =6 if (codpr ==322| codpr ==415 | codpr ==416 | codpr ==419 | codpr ==656 | (codpr >=761 & codpr<=777))		
	replace poste_depense =7 if ((codpr >=208 & codpr <=215)|codpr ==311|codpr ==312|(codpr >=403 & codpr<=409)|codpr ==421|(codpr >=626 & ///
		codpr <=628)| (codpr >=630 & codpr <=636)| (codpr >=828 & codpr <=830))
	replace poste_depense =8 if (codpr ==305|codpr ==313| (codpr >=335 & codpr <=338) | codpr ==637 | codpr ==639 | (codpr >=820 & ///
		codpr <=823) | (codpr >=834 & codpr<=838))	
	replace poste_depense =9 if (codpr ==216|codpr ==314|codpr ==315 | (codpr >=410 & codpr <=414)| codpr==638 | codpr== 642 | ///
		codpr ==643 | codpr ==644 | (codpr >=831 & codpr <=833) | codpr ==839 |codpr ==842 | codpr ==843)		
	replace poste_depense =10 if (codpr ==646 | codpr ==647 | (codpr>=701 & codpr<=748))
	replace poste_depense =11 if codpr ==648	
	replace poste_depense =12 if (codpr ==629| codpr ==652 |codpr ==654 | codpr ==655)			
	replace poste_depense =13 if (codpr ==306| (codpr >=316 & codpr <=319)|codpr ==321|codpr ==323|codpr ==324|codpr ==417| codpr ==418| ///
		codpr ==420| codpr ==645| (codpr >=649 & codpr<=651) | codpr ==657)

	label define poste 1"Alimentation" 2"Boissons alcoolisées et tabac" 3"Habillement et chaussures" ///
	4"Logement, eau, gaz, électricité et autres combustibles" 5"Ameublement, équipement ménager et entretien courant de la maison" 6"Santé" ///
	7"Transport" 8"Communications" 9"Loisirs et culture" 10"Éducation" 11"Hôtellerie" 12"Assurance et autres services financiers" ///
	13"Soins personnels, protection sociale et autres biens"
	label values poste_depense poste
	
	keep if inlist(poste,3,4,5,7,8,9,11,12,13)
	tab codpr if poste_depense==4
	/*
                           Code produit |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                   202. Pétrole lampant |         22        0.07        0.07
           203. Charbon de bois/minéral |      2,263        7.46        7.53
            204. Bois de chauffe acheté |        882        2.91       10.43
           205. Bois de chauffe ramassé |      5,879       19.37       29.80
       304. Carburant pour groupe elec. |          5        0.02       29.82
           310. Frais ramassage ordures |        263        0.87       30.68
                      331. Loyer maison |     12,965       42.71       73.40
              332. Facture eau courante |      2,678        8.82       82.22
               334. Facture electricite |      3,052       10.05       92.27
601. Matériel entretien/répar. du logem |      1,562        5.15       97.42
602. Main-oeuvre entretien/répar. logem |        540        1.78       99.20
       609. Frais abonnement réseau eau |         67        0.22       99.42
      610. Frais abonnement électricité |        165        0.54       99.96
          653. Taxes habitation/voiries |         11        0.04      100.00
----------------------------------------+-----------------------------------
                                  Total |     30,354      100.00
	*/
	drop if inlist(codpr,310,331,332,334) //A reverser dans Housing
	
	tab codpr if poste_depense==8
	/*
                           Code produit |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                 305. Piles électriques |      2,644        6.37        6.37
         313. Communication tél. cabine |        422        1.02        7.39
            335. Facture telephone fixe |         14        0.03        7.42
                  336. Facture internet |        249        0.60        8.02
          337. Facture abonnement cable |      3,956        9.53       17.55
         338. Recharge telephone mobile |     11,941       28.77       46.32
                    820. VU Appareil TV |      5,465       13.17       59.49
            821. VU Magnetoscope/CD/DVD |        439        1.06       60.55
   822. VU Antenne parabolique/decodeur |      3,050        7.35       67.90
        823. VU Lave-linge, seche linge |        271        0.65       68.55
                 834. VU Telephone fixe |         33        0.08       68.63
             835. VU Telephone portable |     12,498       30.11       98.74
                       836. VU Tablette |        150        0.36       99.11
                     837. VU Ordinateur |        330        0.80       99.90
                 838. VU Imprimante/Fax |         41        0.10      100.00
----------------------------------------+-----------------------------------
                                  Total |     41,503      100.00
	*/
	drop if inlist(codpr,335,336,337) //A reverser dans housing*/
	
	save "${temp}/Other_depan.dta", replace

