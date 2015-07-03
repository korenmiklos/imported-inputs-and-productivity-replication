/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Draw graph from a set of simulated scenarios.
*/

* using specification `1'
* group by variable in `2'
* plot variable in `3' as a function of logtau
* restrict sample to `4'..
local files : dir "../doc/simulations" files "use*.csv"
confirm exist `3'

drop _all
tempfile graph
save `graph', replace emptyok
foreach file in `files' {
	insheet using "../doc/simulations/`file'", clear comma case names
	gen str filename="`file'"
	append using `graph'
	save `graph', replace
}

keep if strpos(filename,"`1'")
foreach test in `4' `5' `6' `7' `8' {
	keep if `test'
}

egen categ = group(`2')
su categ
local max = r(max)
local legend ""
forval i=1/`max' {
	su `2' if categ==`i', meanonly
	local categ_`i' = r(mean)
	local legend `legend' `i' "`2'=`categ_`i''"
}

ren `3' outcome
keep `2' outcome logtau categ
reshape wide `2' outcome, i(logtau) j(categ)

gen tau_pp = exp(logtau)*100-100


if "`3'"=="tfp_gain" {
	local ytitle "Change in log aggregate productivity"
}
if "`3'"=="change_in_domestic_inputs" {
	local ytitle "Change in log domestic input demand"
}

line outcome? tau_pp if tau_pp<=40, sort legend(order(`legend')) ytitle(`ytitle') xtitle("Change in tariff (pp)")
graph save "../text/graphs/`2'_`3'.gph", replace

save "../doc/`2'_`3'", replace
