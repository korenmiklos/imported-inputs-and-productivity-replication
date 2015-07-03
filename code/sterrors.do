/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Given a list of bootstrapped estimates, calculate standard errors and other statistics.
*/


* variable transformations
capture gen eta = 1/b_demand_1
capture gen markup = eta/(eta-1)
forval i=1/2 {
	capture gen b_lagGn_`i'_per_gamma = b_lagGn_`i'/b_PlnM
	capture gen long_run_a`i' = a`i' + b_lagGn_`i'_per_gamma
}

* variable names are moved to a string var
ren * coef*
ren coefseed seed
ren coefnace2 nace2
reshape long coef, i(seed nace2) j(variable) string


csvmerge variable using ../doc/variable_order.csv
keep if _m==3
drop _m

replace variable = string(order,"%02.0f")+variable
drop order
reshape wide coef, i(seed nace2) j(variable) string

* now that we have the order of variables, get rid of the prefix
forval i=1/9 {
	capture ren coef0`i'* *
}
forval i=10/49 {
	capture ren coef`i'* *
}

/* run some tests on B */
preserve
drop if seed==0

/* create a new observation for the tests */
gen total = _N+1
su total
set obs `r(mean)'

* set of parameters to test
local values 0 1
local against0 a?
local against1 B?

local pvalues ""
/* test1: B>1 */
foreach value in `values' {
foreach beta of var `against`value'' {
    /* simple EDF-based p-value */
    tempvar rank
    replace `beta' = `value' in L
    egen `rank' = rank(`beta')
    su `rank'
    replace `rank' = `rank'/(1+r(max))

    scalar A = `rank'[_N]
    if A<0.5 {
        scalar p_`beta'_EDF = A*2
    }
    else {
        scalar p_`beta'_EDF = (1-A)*2
    }
	local pvalues "`pvalues' p_`beta'_EDF"
    drop `rank'
    replace `beta' = . in L
}
}

/* if there are more Bs, test them against the previous B */
gen newdiff = -1+_n/_N*2
replace newdiff=0 in 1
sort newdiff

su B*

unab Bs: B*
local M: word count `Bs'
local j 1
forval i=2/`M' {
    gen diff`i' = B`i'-B`j'

    /* simple EDF-based p-value */
    tempvar rank
    replace diff`i' = 0 in L
    egen `rank' = rank(diff`i')
    su `rank'
    replace `rank' = `rank'/(1+r(max))

    scalar A = `rank'[_N]
    if A<0.5 {
        scalar p_B`i'_B`j'_EDF = A*2
    }
    else {
        scalar p_B`i'_B`j'_EDF = (1-A)*2
    }
	local pvalues "`pvalues' p_B`i'_B`j'_EDF"
    drop `rank'
    replace diff`i' = . in L

    drop diff`i'
    local j `i'
}

* confidence intervals of theta
egen theta_low = pctile(theta), p(2.5)
egen theta_high = pctile(theta), p(97.5)

foreach X of var theta_* {
	su `X', meanonly
	scalar `X' = r(mean)
}

restore

/* st errors from bootstrap */
unab varlist : _all
foreach X of var `varlist' {
    su `X' if seed==0, meanonly
    scalar `X'=r(mean)
    su `X' if seed>0
    scalar se_`X'=r(sd)
}
local N : word count `varlist'
clear
set obs `N'
gen str parameter=""
gen estimate=.
gen se=.
forval i=1/`N' {
    local X : word  `i' of `varlist'
    replace parameter="`X'" in `i'
    replace estimate=`X' in `i'
    replace se=se_`X' in `i'
}

preserve
* save other stats
clear
set obs 20
gen str parameter=""
gen estimate = .
scalar i=1
foreach X in `pvalues' theta_low theta_high {
	replace parameter = "`X'" if _n==i
	replace estimate = `X' if _n==i
	scalar i = i+1
}
tempfile params
save `params', replace
restore
append using `params'
