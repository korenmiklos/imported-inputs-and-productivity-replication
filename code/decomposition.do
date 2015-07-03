/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Decomposition reported in Table 8.
*/

capture log close
log using ../doc/decomposition, text replace

clear all

local ahat ahat
if ("`1'"!="") {
	local ahat a
}

local vars import_effect_tfp

/* load parameters and set globals*/
do map/table5_year.do

insheet using ../doc/mapreduce/table5_year/0.csv, comma case

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

use ../data/impmanuf

/* variable definitions */
tsset id year
ren $Ni Ni
/* winsorize here */
gen winsor_Pimp = cond(Pimp>Gmax,Gmax,Pimp)
* 3-year periods
gen period = year
recode period min/1994 = 1994 1995/1997=1997 1998/2000=2000 2001/max=2003
/* before and after foreign ownership */
foreach X of var foreign  {
    egen first`X' = min(cond(`X',year,.)), by(id)
    gen byte after`X' = year>=first`X' & !missing(first`X')
}
/* IAPgroup should index firms with the same IAP */
egen IAPgroup = group($IAPgroup)
gen byte importer = Ni>0



* create firm-specific variables
qui su IAPgroup
local IAPgroups = r(max)
foreach X in a ahat shat B {
	gen `X' = .
	forval j=1/`IAPgroups' {
		replace `X' = `X'`j' if IAPgroup==`j'
	}
}
GN Gn, n(Ni)

gen Qbar = exp(alphastar*lnK+betastar*lnL+gammastar*PlnM)
gen tfp = PlnQ-ln(Qbar)
su tfp, d
gen importshare = winsor_Pimp

gen import_effect_tfp = gammastar*`ahat'

* drop outliers
replace tfp = . if abs(tfp-r(mean))>3*r(sd)

gen weight = Qbar*exp(tfp)
drop if missing(weight)

/* weight by sales */
foreach X of var importer Gn tfp importshare {
	replace `X' = `X' * weight
}

collapse (mean) `vars' (sum) importer Gn tfp weight importshare importi, by(period afterforeign)
foreach X of var importer Gn tfp importshare {
	replace `X' = `X'/weight
}

* Gn conditional on importing
gen cond_Gn = Gn/importer

reshape wide importer *Gn `vars' weight tfp importshare importi, i(period) j(afterforeign)


gen weight=weight0+weight1
gen wshare = weight1/weight

gen tfp = tfp0*(1-wshare)+tfp1*wshare
gen importshare = importshare0*(1-wshare)+importshare1*wshare

gen importer = wshare*importer1+(1-wshare)*importer0
gen wimportershare = wshare*importer1/importer

gen Gn = wshare*Gn1+(1-wshare)*Gn0
gen wGshare = wshare*Gn1/Gn

su

l period w*


foreach X of var w*share importer *Gn {
    su `X' if period==1994, meanonly
    scalar `X'1992=r(mean)
}

foreach X of any `vars' {
	gen intensive_`X' = (wGshare1992*`X'1+(1-wGshare1992)*`X'0)*Gn1992
	gen extensive_`X' = (wGshare1992*`X'1+(1-wGshare1992)*`X'0)*Gn  - intensive_`X'
	gen foreignimport_`X' = (wGshare*`X'1+(1-wGshare)*`X'0)*Gn - extensive_`X'-intensive_`X'
}
gen FDI = wshare*b_afterforeign
gen other = tfp-intensive_import_effect_tfp-extensive_import_effect_tfp-foreignimport_import_effect_tfp-FDI

l period tfp intensive_import_effect_tfp extensive_import_effect_tfp foreignimport_import_effect_tfp FDI

foreach X of var tfp intensive_import_effect_tfp extensive_import_effect_tfp foreignimport_import_effect_tfp FDI other {
    su `X' if period==1994, meanonly
    replace `X'=`X'-r(mean)
	replace `X' = exp(`X')*100-100
}

keep period tfp intensive_import_effect_tfp extensive_import_effect_tfp foreignimport_import_effect_tfp FDI
order period tfp intensive_import_effect_tfp extensive_import_effect_tfp foreignimport_import_effect_tfp FDI
outsheet using ../text/tables/table8-decomposition`1'.csv, replace

log close
