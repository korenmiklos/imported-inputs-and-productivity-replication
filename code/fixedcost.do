/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Estimate fixed costs of importing.
*/

capture log close
set more off
clear all
log using ../doc/fixedcost.log, text replace

do load_specification table4_foreign 0
scalar eta = 1/b_demand_1

global conditioning omegastar $states $linear


tempvar Gn Gnminus Gnplus lower upper gammaimax
local N Ni

gen byte nonimporter = (Ni==0)*100
drop importer

forval j = 0/1 {
	su lnL if Ni==0 & afterforeign==`j'
	scalar lnL_`j' = r(mean)
	su nonimporter if afterforeign==`j'
	local nonimporters_`j' `r(mean)'
}

foreach X in u_jt mean_U_jt median_u_jt mean_log_fixed_cost conditional_mean_fixed_cost f_lower f_upper lower_bound upper_bound {
	gen `X' = .
}
gen cumulated_exp_mu = 0

matrix exp_mu_n = J(366,2,0)

* separately for domestic and foreign
forval foreign=0/1 {
	* estimate distribution of fixed costs by ordered probit
	oprobit Ni lnpi0 if afterforeign==`foreign'
	local number_of_cutoffs = e(k_cat)-1
	scalar sigma = 1/_b[lnpi0]
	scalar sigma_`foreign' = sigma
	matrix B = e(b)
	matrix k = e(cat)

	tempvar predict
	predict `predict', xb
	* this is zeta'z_j 
	gen mean_log_fixed_cost_`foreign' = lnpi0-sigma*`predict'
	replace mean_log_fixed_cost = mean_log_fixed_cost_`foreign' if afterforeign==`foreign'

	su ahat if afterforeign==`foreign'
	scalar a_scalar = r(mean)

	* initalize running variables
	scalar previous_n = 0

	forval i=1/`number_of_cutoffs' {
		matrix alpha = B["y1", "cut`i':_cons"]
		* marginal gain of moving from n-1 to n
		scalar current_n = k[1,`i'+1]

		* after a gap, say, 152, 153, 160, assign marginal cost to 154
		* marginal cost in between, n=155,...,160 is zero
		* we know that 154 has not been chosen
		matrix exp_mu_n[previous_n+1,`foreign'+1] = exp(alpha[1,1]*sigma)*(exp(a_scalar*gammastar/(1-gammastar)*Gn[current_n+1,1]) - exp(a_scalar*gammastar/(1-gammastar)*Gn[previous_n+1,1]))
		
		qui replace lower_bound = lnpi0-mean_log_fixed_cost-sigma*alpha[1,1] if Ni==previous_n & afterforeign==`foreign'
		qui replace upper_bound = lnpi0-mean_log_fixed_cost-sigma*alpha[1,1] if Ni==current_n & afterforeign==`foreign'
		
		qui replace cumulated_exp_mu = cumulated_exp_mu+exp_mu_n[current_n,`foreign'+1] if Ni>=current_n & afterforeign==`foreign'
		
		scalar previous_n = current_n
	}
	qui replace f_lower = cumulated_exp_mu*exp(mean_log_fixed_cost+lower_bound) if afterforeign==`foreign'
	qui replace f_upper = cumulated_exp_mu*exp(mean_log_fixed_cost+upper_bound) if afterforeign==`foreign'
	* draw random realization of u_jt
	qui replace upper_bound = 10*sigma if missing(upper_bound) & afterforeign==`foreign'
	qui replace u_jt = invnormal(normal(lower_bound/sigma)+uniform()*(normal(upper_bound/sigma)-normal(lower_bound/sigma)))*sigma if afterforeign==`foreign'
	* use the formula for truncated lognormal to calculate the conditional mean
	qui replace mean_U_jt = exp(sigma^2/2)*(normal(sigma-lower_bound/sigma)-normal(sigma-upper_bound/sigma))/(normal(upper_bound/sigma)-normal(lower_bound/sigma)) if afterforeign==`foreign'
	qui replace median_u_jt = invnormal(normal(lower_bound/sigma)+0.5*(normal(upper_bound/sigma)-normal(lower_bound/sigma)))*sigma if afterforeign==`foreign'
	qui replace conditional_mean_fixed_cost = cumulated_exp_mu*exp(mean_log_fixed_cost)*mean_U_jt if afterforeign==`foreign'

}

table Ni afterforeign if Ni<=10, c(mean u_jt)

* only save fixed costs, no other parameters
preserve
keep id year pi0 u_jt mean_log_fixed_cost
save ../data/simulated_fixedcosts, replace
restore

* overall fixed costs vs overall gains
gen total_profit_gain = pi0*(exp(ahat*gammastar/(1-gammastar)*Gn)-1)
gen total_cost_saving = totalcost*(exp(ahat*gammastar*eta/(eta-1)*Gn)-1)


* report fixed costs
gen f1 = .
gen fnext = .
forval foreign=0/1 {
	* 0->1
	qui replace f1 = exp(mean_log_fixed_cost)*exp_mu_n[1,`foreign'+1]*exp(median_u_jt) if afterforeign==`foreign'
	* n->n+1
	forval n=1/366 {
		qui replace fnext = exp(mean_log_fixed_cost)*exp_mu_n[`n',`foreign'+1]*exp(median_u_jt) if afterforeign==`foreign' & Ni==`n'-1
	}
}
* conert all nominals to 1998 USD
foreach X of var totalcost wages sales f_lower conditional_mean_fixed_cost f_upper  total_profit_gain total_cost_saving f1 fnext {
	replace `X' = `X'/210.51*1e+6
}
su f_lower conditional_mean_fixed_cost f_upper  total_profit_gain total_cost_saving  wages totalcost sales  if Ni>0
foreach X of var total_profit_gain total_cost_saving wages totalcost sales {
	su conditional_mean_fixed_cost if !missing(conditional_mean_fixed_cost,`X',pi0) & Ni>0, meanonly
	scalar mean_cost = r(mean)
	su `X' if !missing(conditional_mean_fixed_cost,`X',pi0) & Ni>0, meanonly
	di in gre "Fixed costs as a percentage of `X' = " in ye mean_cost/r(mean)*100
	gen share_in_`X' = conditional_mean_fixed_cost/`X'
	su share_in_`X', meanonly
	di in gre "Fixed costs as a percentage of `X' (unweighted) = " in ye r(mean)*100
}

gen byte importer = Ni>0

preserve
* save fixed costs estimates in table 7
collapse (median) f1 fnext, by(importer afterforeign)
reshape long f, i(importer afterforeign) j(measure) string
reshape wide f, i(afterforeign measure) j(importer)

ren f0 Nonimporter
ren f1 Importer
replace measure="Cost of importing first product" if measure=="1"
replace measure="Cost of importing next product" if measure=="next"
gen row=cond(afterforeign, "Foreign", "Domestic")
drop afterforeign

order measure row Nonimporter Importer
outsheet using ../text/tables/table7-fixed-costs.csv, replace comma
restore

* hypethetical fixed costs for the median firms
forval foreign=0/1 {
	gen median_importers_fixed_cost_`foreign' = .
	su mean_log_fixed_cost if afterforeign==`foreign' & Ni>0, d 
	local median = r(p50)
	su u_jt if afterforeign==`foreign' & Ni>0, d 
	local median = r(p50)+`median'
	forval n=1/366 {
		qui replace median_importers_fixed_cost_`foreign' = 1e+6/210.51*exp(`median')*exp_mu_n[`n',`foreign'+1] if afterforeign==`foreign' & Ni==`n'
	}
}
tempvar tag
egen `tag' = tag(afterforeign Ni)
line median_importers_fixed_cost_0 median_importers_fixed_cost_1 Ni if Ni<=10 & Ni>=1 & `tag', sort xlabel(1 2 3 4 5 6 7 8 9 10) legend(order(1 "Domestic firms" 2 "Foreign firms")) ytitle("Fixed cost of median importer (USD)") xtitle(Number of products)
graph save ../text/graphs/fixed_cost_function.gph, replace

preserve

* save fixed cost cutoffs
clear
svmat exp_mu_n
gen n = _n
ren exp_mu_n1 exp_mu_n_0
ren exp_mu_n2 exp_mu_n_1
order n exp*
outsheet using ../data/fixed_cost_mu_estimates.csv, comma names replace

* automated tests
do load_fixed_costs
do load_specification table4_foreign 0
merge 1:1 id year using ../data/simulated_fixedcosts, keep(match)
drop _m
drop importer
do simulate_entry
ren N Ntest
table Ni if Ni<=10 | (Ni<=155&Ni>=145), c(min Ntest max Ntest)
** test that fixedcost-Ni relation properly inverts
forval i=1/150 {
	su Ntest if Ni==`i', meanonly
	capture assert r(mean)==`i'
	if _rc {
		di in red `i'
		su Ntest if Ni==`i'
	}
}

restore

set more on
capture log close
