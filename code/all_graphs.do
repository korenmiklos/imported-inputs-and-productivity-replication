/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

This do-file creates all graphs in the paper.
Run it after all the estimations have been completed.
*/

net install graphexportpdf, from(http://fmwww.bc.edu/RePEc/bocode/g)

capture log close
set more off
clear all
log using ../doc/all_graphs.log, text replace

local options scheme(white)
local format pdf, dropeps replace

do load_specification table3_baseline 0

* Figures 1 and 2, import share as a function of N
local sample Ni<=200

drop sum_weight

egen Ntag = tag(Ni afterforeign)
egen grid = cut(Ni), group(500)

egen sum_import = sum(winsor_Pimp*Pintermed), by(Ni)
egen sum_weight = sum(Pintermed), by(Ni)
gen s_hat = sum_import/sum_weight
 
gen fitted = s1*Gn
 
tw (line s_hat fitted Ni if Ntag & `sample', sort), legend(order(1 "Average import share" 2 "Estimated SG(n)")) `options'
graphexportpdf ../text/graphs/figure1.`format'

do load_specification table4_foreign 0

drop sum_weight

egen Ntag = tag(Ni afterforeign)
egen grid = cut(Ni), group(500)

egen sum_import = sum(winsor_Pimp*Pintermed), by(Ni afterforeign)
egen sum_weight = sum(Pintermed), by(Ni afterforeign)
gen s_hat = sum_import/sum_weight

gen fitted = cond(afterforeign,shat2,shat1)*Gn

label var afterforeign "foreign status"
label def foreign 0 "Domestic firms" 1 "Foreign firms"
label val afterforeign foreign
tw 	(line s_hat fitted Ni if Ntag & `sample', sort by(afterforeign, note(""))), ///
		legend(order(1 "Average import share" 2 "Estimated SG(n)")) `options'
graphexportpdf ../text/graphs/figure2.`format'

* Figure 3: switcher event study
graph use ../text/graphs/switcher_event_study_omegastar.gph, `options'
graphexportpdf ../text/graphs/figure3.`format'

* Figure 4: fixed cost schedule
graph use ../text/graphs/fixed_cost_function.gph, `options'
graphexportpdf ../text/graphs/figure4.`format'

* Figure 5: domestic inputs
clear
tempfile domestic
save `domestic', replace emptyok
foreach t in -0.10 -0.08 -0.06 -0.04 -0.02 -0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.20 0.24 0.28 0.32 0.36 {
	forval comp=0/2 {
		clear
		insheet using "../doc/simulations/use+logtau~`t'+complementarity~`comp'+foreignpresence~1+offset~0+global+specification+table3_baseline.csv"
		append using `domestic'
		save `domestic', replace
	}
}

su sum_domestic_inputs0 if logtau==0 & complementarity==1
scalar base = r(mean)
gen tau_pp = exp(logtau)*100-100

gen domestic = log(sum_domestic_inputs1)-log(base)
label var domestic "Domestic input demand (log, relative to baseline)"
label var tau_pp "Change in tariff (pp)"

tw (line domestic tau_pp if complementarity==1, sort) (line domestic tau_pp if complementarity==2, sort) (line domestic tau_pp if complementarity==0, sort), legend(order(1 "Benchmark" 2 "Imperfect substitution" 3 "Quality")) `options'
graphexportpdf ../text/graphs/figure5.`format' 

