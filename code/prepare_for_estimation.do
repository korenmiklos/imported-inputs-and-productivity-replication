/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Variable definitions to be done once before a sequence of estimations.
*/

foreach global in datafile Ni IAPgroup bygroup states dummies {
	di "`global'"
	confirm existence $`global'
}

use $datafile, clear
tab year
d

* we have no data for 1991, so do not bother creating year dummies for that
drop if year<=1991

* 3-year periods
gen period = year
recode period min/1994 = 1994 1995/1997=1997 1998/2000=2000 2001/max=2003

/* variable definitions */

tsset id year


ren $Ni Ni
gen lnN = ln(1+Ni)
tsset id year
gen lag_log_n1 = ln(1+L.Ni)

* merge tradable share from I-O tables
ren nace2 nace2temp
gen byte nace2 = $sector
tab nace2, missing
csvmerge nace2 using ../data/io/trshare.csv, nokeep
tab _m
table nace2, c(mean goodshare)
keep if _m==3
drop _m
drop nace2
ren nace2temp nace2
ren goodshare Gmax

tsset id year

/* winsorize import share here */
gen winsor_Pimp = cond(Pimp>Gmax,Gmax,Pimp)
gen byte winsorized = Pimp>Gmax

gen byte exporter = Pexport>0
gen expshare = Pexport/Psales

gen byte egy=1

/* has the firm imported before? */
egen firstimport = min(cond(Ni>0,year,.)), by(id)
/* this will be zero for all nonimporters, as well as years before importing */
gen byte importedbefore = (firstimport<year)
drop firstimport

/* before and after foreign ownership */
foreach X of var foreign  {
    egen first`X' = min(cond(`X',year,.)), by(id)
    gen byte before`X' = year<first`X' & !missing(first`X')
    gen byte after`X' = year>=first`X' & !missing(first`X')
    egen byte always`X' = max(before`X'), by(id)
    replace always`X'=1-always`X'
    replace always`X' = 0 if missing(first`X')
    gen byte `X'categ = 1+before`X'+2*after`X'+always`X'
    label def `X'categ 1 "No `X'" 2 "Firm to be `X'" 3 "Firm already `X'" 4 "Always `X'"
    label val `X'categ `X'categ
}

gen byte importer = Ni>0

tab foreigncateg afterforeign

* demand shifters may not be specified
if "$demand"!="" {
	/* generate demand proxies */
	global numdemand : word count $demand
	forval i = 1/$numdemand {
		local expression : word `i' of $demand
		gen demand_`i' = `expression'
		label var demand_`i' "`expression'"
	}
	su demand_*
}


/* IAPgroup should index firms with the same IAP */
egen IAPgroup = group($IAPgroup)
egen bygroup = group($bygroup)
bysort IAPgroup: su $IAPgroup
su bygroup
global Ngroups `r(max)'
su IAPgroup
global IAPgroups `r(max)'

noi tab IAPgroup afterforeign

tsset id year

* log investment rate
gen inv = F.lnK-lnK
su inv
replace inv = r(min) if missing(inv)



/* only narrow down sample after dynamic definitions */
drop if missing(foreign,lnK,lnL,PlnM, Ni)
drop if proc_sales
drop if meanmanuf<0.5
* cannot classify foreign ownership for these firms
* with current definition, foreign==1
egen sometimes_zero_commonstock = max(commonstock==0), by(id)
drop if sometimes_zero_commonstock

egen byte tag = tag(id)

/* if specification calls for more sample restrictions */
keep if $sample

* create dummy groups
egen nace2year = group(nace2 year)
egen nace4year = group(nace98 year)


* fill in missing Nis, linearly interpolating Gn
su Ni
local max = r(max)
local obs = r(N)+r(max)+1
su nace2
set obs `obs'
su nace2

replace Ni = _n-r(N)-1 if _n>r(N)

gen relimp = .


gen byte survival = !missing(F.sales)
tab survival

/* create lagged values */
tsset id year
* if no linear variables are defined in specification, use an empty list
if "$linear"=="" {
	local linear "" 
}
else {
	unab linear : $linear
}

