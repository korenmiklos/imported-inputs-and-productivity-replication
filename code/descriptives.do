/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Descriptives reported in Table 1.
*/

capture log close
log using ../doc/descriptives, text replace
do load_specification table3_baseline 0

tab year afterforeign [aw=Psales]

codebook id

scalar exchange_rate = 1/210.51*1e+3
* express nominal variables in thousand 1998 dollars
replace sales = sales*exchange_rate
gen KperL = exp(lnK-lnL)*exchange_rate
gen QperL = exp(lnQ-lnL)*exchange_rate
gen MperQ = nominal_intermediate/nominal_revenue
gen lnYL = ln((nominal_revenue-nominal_intermediate)*exchange_rate/price_2digit*100)-lnL

gen byte state = stateowned>0.33*commonstock & !missing(stateowned)

tab afterforeign proc_s

codebook id
codebook id if !importer
codebook id if importer

su empl sales KperL QperL MperQ exporter expsh importer impsh Ni afterforeign state
su empl sales KperL QperL MperQ exporter expsh importer impsh Ni afterforeign state if !importer
su empl sales KperL QperL MperQ exporter expsh importer impsh Ni afterforeign state if importer

table year afterforeign, c(mean importer)
table year afterforeign, c(mean impsh)

/* simple XS regressions */
local sample "year==1999"
local controls "lnL matimporter"


* regressions for |Fact 1
reg lnN afterforeign lnL

di exp(_b[afterforeign])-1
di exp(_b[lnL]*ln(2))-1

log close
