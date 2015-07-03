/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Report all numbers in text that are not in separate tables.
*/

capture log close
set more off
clear all
log using ../doc/numbers-in-text.log, text replace

/* frame of firms */
tempfile frame
use ../data/impmanuf, clear
collapse (min) birth = year (max) death=year, by(id)
save `frame', replace
clear

/* sample definition */
tempfile sample
do load_specification table3_baseline 0
save `sample', replace

scalar eta = 1/b_demand_1

di in gre "Importing all varieties increases revenue productivity by " in ye (exp(ahat1*Gmax*gammastar)-1)*100 in gre " percent"
di in gre "Importing all varieties increases quantity productivity by " in ye (exp(eta/(eta-1)*ahat1*Gmax*gammastar)-1)*100 in gre " percent"

foreach t in 1992 2003 {
	su afterforeign [aw=sales] if year==`t', meanonly
	di in gre "Sales share of foreign firms in `t' " in ye r(mean)*100 in gre " percent"
}

gen byte L_less_than_20 = employment<20
su L_less_than_20 [aw=sales] if year<=1999, meanonly
di in gre "Sales share of small firms in 1992-1999: " in ye r(mean)*100 in gre " percent"

count
di in gre "Number of obersvations in sample " in ye r(N)

count if foreign==1 & L.foreign==0
di in gre "Number of firms becoming foreign " in ye r(N)
count if foreign==0 & L.foreign==1
di in gre "Number of firms becoming domestic " in ye r(N)
egen divestment = max(afterforeign==1 & foreign==0), by(id)
egen firmtag = tag(id)
count if firmtag & !missing(firstforeign)
scalar number_of_foreign_firms = r(N)
count if firmtag & !missing(firstforeign) & divestment==1
di in gre "Of the " in ye number_of_foreign_firms in gre " foreign firms, " in ye r(N) in gre " divest for at least 1 year."

egen death = max(year), by(id)
egen dies_as_domestic = max(death==year&afterforeign==1&foreign==0), by(id)
count if dies_as_domestic & !missing(firstforeign ) & firmtag
di in gre "Of the " in ye number_of_foreign_firms in gre " foreign firms, " in ye r(N) in gre " exits our sample as a domestic firm."


gen logN = ln(Ni)
reg logN lnL afterforeign
di in gre "Doubling employment raises the number of products by " in ye exp(ln(2)*_b[lnL])*100-100 in gre " percent"
di in gre "Foreign firms import " in ye exp(_b[afterforeign])*100-100 in gre " percent more products"

di in gre "Share of quality in TFP gain of importing " in ye (B1-1)/(exp(ahat1)-1)*100 in gre " percent"
di in gre "Markup implied by eta " in ye eta/(eta-1)*100-100 in gre " percent"

gen TFP_loss = ahat1*Gn*gammastar
su TFP_loss [aw=sales], meanonly
di in gre "Stopping all imports would reduce aggregate revenue TFP by " in ye 100-exp(-r(mean))*100

**** switch to balanced sample
use ../data/impmanuf, clear
merge 1:1 id year using `sample'

su proc_s, meanonly
di in gre "Fraction of processers in balanced firm sample " in ye r(mean)*100 in gre " percent"

* other specifications
clear all
do load_specification table4_foreign 0
di in gre "Foreign firms gain " in ye B2/B1*100-100 in gre " percent more for each dollar of imported input."

clear all
insheet using ../doc/mapreduce/table5_year/estimates.csv
keep parameter estimate
gen egy = 1
ren estimate b_

reshape wide b_, i(egy) j(parameter) string
ren b_* *
keep egy a? ahat? s? shat?
reshape long a ahat s shat, i(egy) j(IAP)

foreach X in a s {
	gen absdiff_`X' = abs(`X'-`X'hat)
	su absdiff_`X'

	di in gre "Mean absolute difference between `X' and `X'hat is " in ye r(mean)
}

capture log close

