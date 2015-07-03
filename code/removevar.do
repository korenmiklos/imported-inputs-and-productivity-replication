/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Partial out variation related to proxy and state variables.
*/
confirm existence $states
confirm existence $dummies
confirm existence $proxy
confirm variable bygroup

* resolve varlist
unab states : $states

su bygroup
global Ngroups `r(max)'
su IAPgroup
global IAPgroups `r(max)'

capture prog drop partial
program define partial
	* partial out variation from dummies and groups
    version 9
    syntax varlist
	
	tempvar resid 
	
	local absorb : word 1 of $dummies
	local Num : word count $dummies
	
	* to speed up, first demean by lots of dummies
	foreach Z of var `varlist' {
		* first take out variation in first dummy
		qui areg `Z', a(`absorb')
		qui predict `resid', resid
		qui replace `Z' = `resid'
		drop `resid'
		* then the rest
		if `Num'>1 {
			qui reg `Z' I_*, nocons
			qui predict `resid', resid
			qui replace `Z' = `resid'
			drop `resid'
		}
	}

end


* create a flag for demeaning problems
gen byte demean_flag = 0

program define removevar
    version 9
    syntax varlist

    tempvar LHS resid
	

    * remove variation from proxy
    foreach X of var `varlist' {
        capture drop `X'_resid
        capture drop `X'_fit
        qui gen `X'_resid = .
        qui gen `X'_fit = .
        qui gen `X'_Nvars = .
		
		* partial out left-hand-side variable
		gen `LHS' = `X'
		partial `LHS'

        forval i=1/$Ngroups {
            * run a separate regression for each group
			* include a linearly separable term
            capture xi: reg `LHS' _x* $linear if bygroup==`i' 
            if (_rc==0) {
                qui predict `resid' if bygroup==`i', resid
                qui replace `X'_resid = `resid' if bygroup==`i'
                qui replace `X'_fit = `X'-`resid' if bygroup==`i'
                qui replace `X'_Nvars = e(rank) if bygroup==`i'
                qui replace `X'_Nvars = e(N) if bygroup==`i' & e(rank)==0                
                drop `resid'
            }
			else if (_rc==2001) {
				* if regression fails because of insufficient obs, we can predict X perfectly
                qui replace `X'_resid = 0 if bygroup==`i'
                qui replace `X'_fit = `X'-`X'_resid if bygroup==`i'
                qui replace demean_flag = 1 if bygroup==`i'
			}
        }
		
		drop `LHS'
    }

end

/* create combination of proxies */
local longlist _egy `states' $proxy
local Nlist : word count `longlist'
* this is all possible products up to ^3
capture drop _egy
gen byte _egy = 1
forval i=1/`Nlist'  {
    forval ii=`i'/`Nlist' {
        forval iii=`ii'/`Nlist' {
                local vari : word `i' of `longlist'
                local varii : word `ii' of `longlist'
                local variii : word `iii' of `longlist'
                qui gen double _x`i'_`ii'_`iii' = `vari'*`varii'*`variii'
        }
    }
}
/* this is the constant anyway */
drop _x1_1_1

* demean for each set of dummies separately
local Dnum : word count $dummies
local absorb : word 1 of $dummies
local i_rest ""
forval i=2/`Dnum' {
	local next : word `i' of $dummies
	local i_rest "`i_rest' i.`next'"
}

* create indicators so that they can be demeaned
if "`i_rest'"!="" {
	* only do this if there are other indicators
	xi: su `i_rest'
	ren _I* I_*
	foreach X of var I_* {
		tempvar resid
		qui areg `X', a(`absorb')
		qui predict `resid', resid
		qui replace `X' = `resid'
		drop `resid'
	}
}
* only partial out _x's once
partial _x*
