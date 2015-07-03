/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Create Figure 3.
*/

capture log close
set more off
log using ../doc/switcher_event_study, text replace

do load_specification table3_baseline 0
scalar deltastar = ahat1*gammastar

capture drop __*

confirm numeric variable omegastar epsilonstar
confirm numeric variable firstforeig

capture prog drop ewindow
program define ewindow
	version 10
	syntax varlist [, window(integer 4)]
	
	
	local T `window'
	
	gen byte `varlist'time = year - `varlist'

	/* drop time outside the event window */
    drop if `varlist'time<-`T' & !missing(`varlist'time)
    drop if `varlist'time>`T' & !missing(`varlist'time)
	
	gen byte `varlist'before = `varlist'time<0 & `varlist'time>=-`T'
	gen byte `varlist'after = `varlist'time>=0 & `varlist'time<=`T'
	
	/* create dummies manually for better reading */
	gen byte `varlist'0 = `varlist'time==0
	forval t = 1/`T' {
		gen byte `varlist'`t' = `varlist'time==`t'
		gen byte `varlist'_`t' = `varlist'time==-`t'
	}

	/* flag firms that are always treated.
	   these have only after dummies, not before dummies */
	egen byte always`varlist' = min(`varlist'after), by(id)
end

/* first switch in the sample */
egen int smp_foreign = min(cond(foreign>0 & !missing(foreign),year,.)), by(id)
/* first switch in original data */
ren firstforeign pop_foreign

/* create event window */
local T 3
local foreign pop_foreign
ewindow `foreign', window(`T')

assert pop_foreignafter==afterforeign

scalar eta = 1/b_demand_1
gen omega_quantity = omegastar*eta/(eta-1)
gen omegastar_revenue = omegastar+b_demand_1*demand_1+b_demand_2*demand_2

drop if missing(`foreign')
drop if always`foreign'
drop if missing(demand_1,demand_2)

* interaction regression to save difference in coefficients
foreach X of var `foreign'_? `foreign'? {
	gen byte treatmentX`X' = importer*`X'
}
reg omega_quantity `foreign'_? `foreign'? treatmentX*, nocons cluster(id)
matrix Bq_ = e(b)
matrix varq_ = vecdiag(e(V))


test (treatmentXpop_foreign1+treatmentXpop_foreign2+treatmentXpop_foreign3)/3==(treatmentXpop_foreign_1+treatmentXpop_foreign_2+treatmentXpop_foreign_3)/3

reg omegastar_revenue `foreign'_? `foreign'? treatmentX*, nocons cluster(id)
matrix Br_ = e(b)
matrix varr_ = vecdiag(e(V))
test (treatmentXpop_foreign1+treatmentXpop_foreign2+treatmentXpop_foreign3)/3==(treatmentXpop_foreign_1+treatmentXpop_foreign_2+treatmentXpop_foreign_3)/3

clear
foreach X in q r {
	svmat B`X'_, names(matcol)
	svmat var`X'_, names(matcol)
}

drop B*_`foreign'*
drop var*_`foreign'*

gen egy = 1

reshape long Bq_treatmentX`foreign' Br_treatmentX`foreign' varq_treatmentX`foreign' varr_treatmentX`foreign', i(egy) j(timestr) string
/* convert timestring like "_1" to numerical 1 */
gen eventtime = .
forval t = 0/`T' {
	replace eventtime = `t' if timestr=="`t'"
	replace eventtime = -`t' if timestr=="_`t'"
}

ren Bq Bq
ren Br Br

* normalize Bq[-1]=Br[-1]=0
foreach X of var Bq Br {
	qui su `X' if eventtime==-1
	replace `X' = `X'-r(mean)
}


label var Bq "Quantity TFP premium of importers relative to nonimporters"
label var Br "Revenue TFP premium of importers relative to nonimporters"
label var eventtime "Years since foreign acquisition"
line Bq Br eventtime, sort scheme(s2mono) legend(cols(1)) xlabel(-3 -2 -1 0 1 2 3) xline(-0.5, lpattern(.))
graph save ../text/graphs/switcher_event_study_omegastar.gph, replace

set more on

