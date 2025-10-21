
clear
set more off


* 1. Define working directory
global projet "D:\OTF\OIT-Estimation salaire\Analyse BIT" // Insert the working path

* 2. Directory paths
*-------------------

global data "$projet\data" // Insert the path from the raw data
global output "$projet\outpts" // Insert the path to the outputs (Excel File)
global temp "$projet\temp" // Insert the path to the temporary files
global do_files "$projet\do_files"
*global do_files `"/Users/erika_chaparro/Downloads/wb_data/02_world_bank_mplcs-hh_member.dta"' // Insert the path to the do-files


include "${do_files}/1. config.do"
include "${do_files}/2. Adult equivalent.do"
include "${do_files}/3. Food and calorie consumption I.do"
include "${do_files}/4. Total Expenditure Estimation.do"
include "${do_files}/5. Food and calorie consumption II.do"
include "${do_files}/6. Quintile distribution estimates.do"
include "${do_files}/7. Reference basket_cal prot fat intake.do"
include "${do_files}/8. Housing.do"
include "${do_files}/Dofile Estimation salaire.do"






