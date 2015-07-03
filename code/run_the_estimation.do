/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Run the estimation with prespecified parameters.
*/

set maxiter 100

* check state first
confirm existence $free $instruments

* check if seed is passed
confirm existence `1'
confirm number `2'

confirm variable survival PlnQ  IAPgroup winsor_Pimp Pintermed Ni
foreach X in $free {
	confirm variable `X'
}

tab year

su IAPgroup
global IAPgroups `r(max)'

* resolve variable lists
if "$free"=="" {
	local free ""
}
else {
	unab free : $free
}
* linear variables may not be defined
if "$linear"=="" {
	local linear "" 
}
else {
	unab linear : $linear
}


noi di in gre "Variables to be estimated in first stage: "
global free_resid ""
foreach X in `free' {
	noi di in ye "`X'"
	global free_resid "$free_resid `X'_resid"
}










noi tab IAPgroup afterforeign

* refactored Gn estimation into estimate_Gn.do
do estimate_Gn

* follow Gandhi, Navarro, Rivers and estimate gammastar from shares
foreach X of var nominal_*{
	su `X' if !missing(nominal_revenue, nominal_intermediate, nominal_wagebill)
	scalar total_`X' = r(sum)
}
scalar b_PlnM = total_nominal_intermediate/total_nominal_revenue

di b_PlnM

/* this defines the program to remove proxy-related variation */
capture prog drop removevar
do removevar

* test whether demand shifters are state variables
* if lagged demand variables are significant, they should be included in 2nd stage
confirm variable demand_1
if _rc==0 {
	foreach X of var demand_? {
		gen L`X' = L.`X'
		removevar `X' L`X'
		noi reg `X'_resid L`X'_resid, nocons cluster(id)
		drop L`X'*
	}
}

* after stage 0, subtract effect of material on production
gen PlnQ_novarinputs = PlnQ - b_PlnM*PlnM

removevar survival PlnQ_novarinputs `free' Gn_* 

/* production function equation */
reg PlnQ_novarinputs_resid $free_resid Gn_*_resid, nocons
* unobserved productivity
predict epsilonstar, resid
    scalar RSS1 = e(rss)
    scalar N1 = e(N)
    /* save parameters */
	foreach X in $free {
		tempname b_`X'
		scalar b_`X' = _b[`X'_resid]
		noi di in gre "b_`X'=" in ye b_`X'
	}
    forval m=1/$IAPgroups {
        scalar a`m' = _b[Gn_`m'_resid]/b_PlnM
    }

    /* import demand equation */
reg winsor_Pimp $Gnlist [w=Pintermed], nocons
    scalar RSS2= e(rss)
    scalar N2  = e(N)
    forval m=1/$IAPgroups {
    	scalar s`m' = _b[Gn_`m']
    }
	
global parameters : all scalars

/* now estimate the state variable coefs */
global Gnhat "0"
global Gnhatfit "0"
forval m=1/$IAPgroups {
    global Gnhat "$Gnhat+a`m'*Gn_`m'"
    global Gnhatfit "$Gnhatfit+a`m'*Gn_`m'_fit"
}
/* build predicted values */
global free_predicted "0"
global free_fit "0"
foreach X in `free' {
	global free_predicted "$free_predicted+b_`X'*`X'"
	global free_fit "$free_fit+b_`X'*`X'_fit"
}


gen phi = PlnQ_novarinputs_fit-($free_fit)-b_PlnM*($Gnhatfit)
gen A = PlnQ_novarinputs-($free_predicted)-b_PlnM*($Gnhat)

tsset id year
gen lagphi = L.phi

/* save h function for OP equation 13 */
tempvar missing
* flag if any of the RHS variables is missing
gen byte `missing' = 0
* include linearly additive state variables
unab states : $states
foreach X in `states' `linear' {
	replace `missing'=1 if missing(`X')
	replace `missing'=1 if missing(L.`X')
}

replace `missing'=1 if missing(survival_fit)
replace `missing'=1 if missing(lagphi)

* demean all variables going into second stage - productivity means may be different
foreach X of var A lagphi survival_fit `states' `linear' {
	qui areg `X' i.me, a(nace2)
	qui predict within_`X', resid
}

* inner loop of gmm, conditional on production function coefficients
program gmm_innerloop

	version 12

	syntax varlist [if] , at(name) rhs(varlist)

	tempvar h lagh
	quietly gen double `h' = within_A `if'
	quietly gen double `lagh' = within_lagphi `if'

	* h is our estimate of productivity, given parameters in `at'
	local i 1
	foreach var of varlist `rhs' {
		quietly replace `h' = `h' - within_`var'*`at'[1,`i'] `if'
		quietly replace `lagh' = `lagh' - L.within_`var'*`at'[1,`i'] `if'
		local `++i'
	}


	local polylist ""
	local kmax 3
	forval i=0/`kmax' {
		forval j=`i'/`kmax' {
			tempvar poly`i'`j'
			qui gen `poly`i'`j'' = `lagh'^`i'*survival_fit^(`kmax'-`j')
			local polylist "`polylist' `poly`i'`j''"
		}
	}
	* estimating equation 13 of OP
	qui reg `h' `polylist' $spectestvars `if'
	scalar Ftest = e(F)
	
	tempvar resid
	qui predict `resid', resid
	
	* return the coefficient of specification tests
	if "$spectestvars"!="" {
		foreach X of var $spectestvars {
			scalar `X' = _b[`X']
		}
	}

	quietly replace `varlist' = `resid' `if'

end


/* generate instruments */
global numdins : word count $instruments
forval i = 1/$numdins {
	local expression : word `i' of $instruments
	gen instrument_`i' = `expression'
	label var instrument_`i' "`expression'"
}
su instrument_*
* cannot do GMM with missing instruments
foreach X of var instrument_* {
	replace `missing'=1 if missing(`X')
}

/* only do two steps if the GMM is overid */
unab IVs : instrument_*
local Nmoments : word count `IVs'
local Nparams : word count `states' `linear'

if (`Nmoments'>`Nparams') {
	local method "twostep winitial(identity) "
}
else {
	local method "onestep winitial(identity) "
}

* a simple OLS first, not reported
reg within_*
* save OLS coefficients to use in the few cases when GMM does not converge
foreach X in `states' `linear' {
    scalar b_`X' = _b[within_`X']
}
scalar converged = 0

/* no constant. polynomial has it already. */
capture gmm gmm_innerloop  if !`missing', nequations(1) parameters(`states' `linear') instruments(instrument_*) rhs(`states' `linear') `method' conv_maxiter(20)
if _rc==0 {
	* include linearly additive state variables
	foreach X in `states' `linear' {
    	capture scalar b_`X' = _b[`X':_cons]
    	if _rc {
        	scalar b_`X' = _b[`X']
    	}
	}
	scalar converged = 1
}
* call inner loop one more time with correct parameters
matrix parameters = e(b)
tempvar resid
gen `resid' = .
gmm_innerloop `resid', at(parameters) rhs(`states' `linear')

if `2'==0 {
	******
	* save TFP time series to create event study graphs for switchers
	* NB: we also subtract demand shocks
	gen omegastar = phi
	gen omegastar_epsilonstar = A
	foreach X of var `states' `linear' {
		replace omegastar = omegastar-b_`X'*`X'
		replace omegastar_epsilonstar = omegastar_epsilonstar-b_`X'*`X'
	}
	save ../doc/mapreduce/`1'/TFP, replace
}

count
scalar Nfirms = r(N)
count if Ni>0
scalar Nimporters = r(N)
count if foreign
scalar Nforeign = r(N)
su lnL, d
scalar medL = exp(r(p50))

clear

* save all Gn values for bootstrap
svmat Gn_matrix, names(col)
drop Gnprime
gen byte egy=1
reshape wide Gn, i(egy) j(Ni)

di "First-stage parapemeters: " in gre "$parameters" in ye

foreach X in Nfirms Nimporters Nforeign medL $parameters $spectestvars converged Ftest {
	* named parameters
    gen `X' = `X'
}
* include linearly additive state variables
foreach X in `states' `linear' {
	* variables coefficients
    gen b_`X' = b_`X'
}



local IAP "0"
forval m=1/$IAPgroups {
    local IAP "`IAP'+exp({lnB`m'})*(IAPgroup==`m')"
}

reshape long a s, i(egy) j(IAPgroup)
expand 2
egen tag = tag(IAPgroup)
gen LHS = cond(tag,a,s)
/* weight by # of obs used in estimating param */
gen FW = cond(tag,Nfirms,Nimporters)

gen R2 = .
gen theta = .
gen B = .
gen Gmax = .

gen byte nace2 = $sector

csvmerge nace2 using ../data/io/trshare.csv, nokeep
drop _m
drop if missing(IAPgroup)

local Gmax goodshare

/* minimum distance estimate of structural parameters */
capture nl (LHS = cond(tag,ln(1+(`IAP')^exp({logtheta}) )/exp({logtheta}),(`IAP')^exp({logtheta})/(1+(`IAP')^exp({logtheta}) ))) [fw=FW], iterate(100)
if (_rc==0)|(_rc==430) {
    replace R2 = e(r2)
    replace theta = 1+exp(_b[/logtheta])
    replace Gmax = `Gmax'
    forval m=1/$IAPgroups {
        replace B = exp(_b[/lnB`m']) if IAPgroup==`m'
    }
}

keep if tag
drop LHS

gen shat = B^(theta-1)/(1+B^(theta-1))
gen ahat = ln(1+B^(theta-1))/(theta-1)

reshape wide a s B shat ahat, i(nace2) j(IAPgroup)
order b_* ahat* B* shat* theta
