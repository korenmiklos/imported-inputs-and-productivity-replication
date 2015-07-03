/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

This program calculates an industry equilibrium with estimated and counterfactual parameters.
*/

prog drop _all
do load_fixed_costs
do load_specification $specification 0

merge 1:1 id year using ../data/simulated_fixedcosts, keep(match)
drop _m

foreach X in ahat1 ahat2 shat1 shat2 {
	capture scalar drop `X'
}

confirm numeric variable pi0 ahat shat afterforeign u_jt mean_log_fixed_cost
confirm scalar theta foreignpresence b_afterforeign offset complementarity
confirm file simulate_entry.do 
confirm matrix exp_mu_n

assert afterforeign==0|afterforeign==1
assert foreignpresence==0|foreignpresence==1|foreignpresence==2
assert complementarity==0|complementarity==1|complementarity==2

drop Gn

* check that theta, ahat and shat are consistent
tempvar A_tau_theta_1
gen `A_tau_theta_1' = exp((theta-1)*ahat)-1
assert abs(shat-(1-1/(1+`A_tau_theta_1')))<0.01


* save factual and counterfactual value side by side
expand 2, gen(counterfactual)

* allow for tariffs even in baseline scenario
capture confirm scalar logtau 
if (_rc!=0) {
	confirm scalar logtau0 logtau1
	gen logtau_var = logtau0 if !counterfactual
	replace logtau_var = logtau1 if counterfactual
	scalar logtau = logtau1
}
else {
	scalar logtau_scalar = logtau
	gen logtau_var = 0 if !counterfactual
	replace logtau_var = logtau_scalar if counterfactual
}

* set variables to counterfactual values
if foreignpresence==0 {
    /* no foreign firms. replace ahat, shat, fixed costs and pi0. */
    foreach X of var ahat shat {
    	qui su `X' if !afterforeign
    	qui replace `X' = r(mean)
    }
	replace pi0 = pi0/exp(b_afterforeign*afterforeign)
	replace afterforeign = 0
}
if foreignpresence==1 {
    /* foreign firms as in the sample */
}
if foreignpresence==2 {
    /* all firms foreign. replace ahat shat, fixed costs and pi0. */
    foreach X of var ahat shat {
    	qui su `X' if afterforeign
    	qui replace `X' = r(mean)
    }
	replace pi0 = pi0*exp(b_afterforeign*(1-afterforeign))
	replace afterforeign = 1
}

* if new theta is given, overwrite existing one
gen theta = theta /* converts from scalar to variable */
scalar drop theta
* set variables to counterfactual values
if complementarity==0 {
    /* no complementarity. theta=20 */
	replace theta = 20
}
if complementarity==1 {
    /* as in the sample */
}
if complementarity==2 {
    /* complementarity strongest */
	su ahat
	replace theta = 1+ln(2)/r(max)
}


/* shift fixed costs by amount of offset. +0.1 increases both fixed costs by 10% */
replace u_jt = u_jt+offset


* if theta changes, ahat is fixed, shat is recalibrated
replace `A_tau_theta_1' = exp((theta-1)*ahat)-1
replace `A_tau_theta_1' = `A_tau_theta_1'/exp((theta-1)*logtau_var)
replace shat = 1-1/(1+`A_tau_theta_1')
replace ahat = -ln(1-shat)/(theta-1)

* calculate derived variables in both factual and counterfactual
foreach X in N GN importer {
	capture drop `X'
}

do simulate_entry

gen log_tfp = omegastar+epsilonstar+gammastar*ahat*GN
gen base_size = exp(PlnQ+log(price_2digit/100)-log_tfp)
gen nominal_output = base_size*exp(log_tfp)

gen foreign_inputs = nominal_output*gammastar*shat*GN
gen domestic_inputs = nominal_output*gammastar*(1-shat*GN)

* drop all tempvars to prevent reshape errors
drop __*
reshape wide importer logtau_var ahat shat theta GN N log_tfp afterforeign base_size nominal_output foreign_inputs domestic_inputs pi0 u_jt, i(id year) j(counterfactual)
* log TFP gain
gen tfp_gain = log_tfp1-log_tfp0
* intensive margin
gen intensive_margin = gammastar*(ahat1-ahat0)*GN0
gen extensive_margin = gammastar*ahat1*(GN1-GN0)
gen import_price_gain = gammastar*(logtau_var1-logtau_var0)*(-shat0)*GN0

foreach X of var tfp_gain intensive_margin extensive_margin import_price_gain {
	su `X' [aw=base_size0]
	scalar `X' = r(mean)
}

* level TFP gain
gen level1 = exp(log_tfp1)*base_size0
gen level0 = exp(log_tfp0)*base_size0
su level1 if !missing(level0), meanonly
scalar level1mean = r(mean)
su level0 if !missing(level0), meanonly
scalar level_gain = level1mean/r(mean)-1


* change in domestic input demand
foreach X of var domestic_inputs? foreign_inputs? {
	su `X' if !missing(domestic_inputs0,domestic_inputs1), d
	scalar sum_`X' = r(sum)
}
scalar change_in_domestic_inputs = log(sum_domestic_inputs1/sum_domestic_inputs0)
scalar domestic_input_share = sum_domestic_inputs1/(sum_domestic_inputs1+sum_foreign_inputs1)

* import margins for debug purposes
su importer1
scalar share_of_importers = r(mean)
su GN1 if importer1
scalar average_GN = r(mean)
su N1 if importer1
scalar average_N = r(mean)

* save ahat1, ahat2, shat1, shat2
forval j=1/2 {
	foreach X in ahat shat {
		su `X'1 if afterforeign1==`j'-1, meanonly
		scalar `X'`j' = r(mean)
	}
}
