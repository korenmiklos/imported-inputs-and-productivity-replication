/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Load the parameters estimated in a given specification, e.g.

	do load_specification table3_baseline 0
*/

set more off
clear
prog drop _all

local dir ../doc/mapreduce
local inputfile `dir'/`1'/inputfile.dta
local resultfile `dir'/`1'/`2'.csv

confirm file ../doc/mapreduce/`1'/TFP.dta
confirm file `inputfile'
confirm file `resultfile'
confirm file map/`1'.do


/* load parameters and set globals*/
do map/`1'.do

insheet using `resultfile', comma case

* name parameters consistenly with text
ren b_lnK alphastar
ren b_lnL betastar
ren b_PlnM gammastar

* count IAP groups
reshape long ahat shat, i(egy) j(IAPgroup)
su IAPgroup
local IAPgroups = r(max)
reshape wide

* save Gn into a matrix
reshape long Gn, i(egy) j(n)
tsset n
mkmat Gn

reshape wide

* save all other params into scalars
drop Gn*
unab params : _all
foreach param in `params' {
	scalar `param' = `param'[1]
}

clear

* define functions to calculate Gn and its inverse
/* mapping from N to GN and back */
prog def GN
    syntax newvarlist(max=1), n(string)

    qui gen `varlist' = .
    forval i=1/367 {
    	qui replace `varlist' = Gn[`i',1] if `n'+1==`i'
    }
end

use ../doc/mapreduce/`1'/TFP
drop __*

* create firm-specific variables
qui su IAPgroup
local IAPgroups = r(max)
foreach X in a ahat shat B {
	gen `X' = .
	forval j=1/`IAPgroups' {
		replace `X' = `X'`j' if IAPgroup==`j'
	}
}
drop Gn
GN Gn, n(Ni)

gen nu = (PlnQ+log(price_2digit/100))-gammastar*(PlnM+log(price_material/100))-gammastar*ahat*Gn-epsilonstar

* mean unobserved TFP shock
gen ee = exp(epsilonstar)

* ensure that total industry revenue is same in model as in data
* this does not have E(exp epsilon) yet
gen data_revenue = exp(PlnQ+log(price_2digit/100))
foreach X of var *_revenue {
	egen mean_`X' = mean(`X'), by(nace2 year)
}

gen weight = data_revenue/ee

egen sum_exp_e = sum(ee*weight) if !missing(ee,weight), by(nace2 year)
egen sum_weight = sum(weight) if !missing(ee,weight), by(nace2 year)
gen Eee = sum_exp_e/sum_weight

* See equation A6 in Appendix A
gen model_revenue = gammastar^(gammastar/(1-gammastar))*exp((nu+gammastar*ahat*Gn)/(1-gammastar))*Eee^(1/(1-gammastar))
gen pi0 = (1-gammastar)*gammastar^(gammastar/(1-gammastar))*exp(nu/(1-gammastar))*Eee^(1/(1-gammastar))
gen lnpi0 = ln(pi0)

*************** some automated tests
* lnpi0 should be collinear with nu
areg lnpi0 nu, a(nace2year)
assert e(r2)>0.9999
* nu should have values whenever its components have
count if !missing(PlnQ,PlnM,epsilonstar)
scalar n1 = r(N)
count if !missing(nu)
assert n1 == r(N)
* G(0)=0
su Gn if Ni==0
assert r(mean)==0
* each Ni has a G(Ni)
gen byte noGn = missing(Gn) & !missing(Ni)
su noGn
assert r(max)==0
drop noGn
* each IAPgroup has a separate ahat
tab IAPgroup
scalar n1 = r(r)
tab ahat
assert n1 == r(r)

set more on

