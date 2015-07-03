/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Estimate G(n) from import shares.
*/

su Ni, d
if r(max)>200 {
	local Nbar 150
}
else {
	local Nbar = r(p99)
}
local sigma {sigma}
local CES 1-(1-(Ni/`Nbar')^normal(`sigma'))^(1/normal(`sigma'))
nl (winsor_Pimp = cond(afterforeign,{s2},{s1})*cond(Ni<`Nbar',`CES',1)) if !missing(afterforeign,winsor_Pimp,Ni) [w=Pintermed]

local sigma = _b[/sigma]
local CES 1-(1-(Ni/`Nbar')^normal(`sigma'))^(1/normal(`sigma'))
scalar lambda = normal(`sigma')

su Gmax
assert r(sd)<0.00001
scalar Gmaxscalar = r(mean)

preserve
clear
set obs 367
gen Ni = _n-1
gen Gmax = Gmaxscalar
gen Gn = cond(Ni<`Nbar',`CES',1)*Gmax

tsset Ni
gen Gnprime = F.Gn-Gn
replace Gnprime = 0 in -1

mkmat Ni Gn Gnprime, matrix(Gn_matrix)

restore
* drop dummy observations
drop if missing(year,PlnQ)

* create estimated Gn
gen Gn=.
local N = rowsof(Gn_matrix)
forval nplus1=1/`N' {
	mat scalarmatrix = Gn_matrix[`nplus1',"Gn"]
	qui replace Gn = scalarmatrix[1,1] if Ni+1==`nplus1'
}

tsset id year
gen lagGn = L.Gn

global Gnlist ""
forval m=1/$IAPgroups {
	gen Gn_`m' = (IAPgroup==`m')*Gn
	global Gnlist "$Gnlist Gn_`m'"
	gen lagGn_`m' = (IAPgroup==`m')*lagGn
}
