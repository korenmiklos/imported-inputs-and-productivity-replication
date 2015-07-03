/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Create Table 2.
*/

capture log close
log using ../doc/import_margins, text replace

local datastore ../data

/* sample definition */
tempfile sample
do load_specification table3_baseline 0
save `sample', replace

/* frame of firms */
tempfile frame
use ../data/impmanuf, clear
collapse (min) birth = year (max) death=year, by(id)
save `frame', replace

/* read import customs stats */
use `datastore'/customs/import/hs6imports, clear
ren id7 id

/* merge BEC codes */
csvmerge hs6 using `datastore'/customs/concordance/hs6bec.csv
tab _
drop _

/* for the count */
replace i_ft = . if i_ft==0

compress
tab bec
/* 1 is for intermediate, 2 for capital, 3 for consumption */

recode bec 11 21 22 31 32 42 53 = 1 /*
*/         41 51 52 = 2 /*
*/          12 61 62 63 = 1 /*
*/          * = 1

keep if bec==1

* collapse to 4 digit
gen hs4 = int(hs6/100)
collapse (sum) i_ft, by(id hs4 year)

/* appearance of HS4 in the entire sample. we want to understand HS revisions */
preserve
collapse (sum) i_ft, by(hs4 year)
drop if i_ft==0 | missing(i_ft)
collapse (min) product_entry = year, by(hs4)
tab product_entry
tempfile product_entry
save `product_entry', replace
restore

/* drop non-imported products */
drop if i_ft==0
drop if year==1991

* calculate share of top 1 and 5 products
egen N = count(i_ft), by(id year)
egen total = sum(i_ft), by(id year)
gen share = i_ft/total
egen rank = rank(-share), by(id year) unique

su share if N>=5 & rank==1, meanonly
di in gre "Share of top product " in ye r(mean)*100 in gre " percent"
su share if N>=5 & rank==5, meanonly
di in gre "Share of fifth product " in ye r(mean)*100 in gre " percent"

* merge manufacturing sample, drop processers
merge m:1 id year using ../data/impmanuf, keepusing(nace98 nace2 proc_sales meanmanuf pt price_2digit foreign commonstock lnK lnL PlnM) keep(match)

* for dynamic decomposition need firms in sample for all years or not at all
egen meanproc = mean(proc_s), by(id)
drop if meanproc>=0.5
drop if meanmanuf<0.5
egen sometimes_zero_commonstock = max(commonstock==0), by(id)
* define sometimeszero after processers are dropped to max obs
drop if sometimes_zero_commonstock
drop _merge

* deflate imports by producer price index
replace i_ft = i_ft/price_2digit*100

* emulate annual decomposition for entire sample
if "`1'"=="longrun" {
	keep if year==1992 | year==2003
	replace year=1993 if year==2003
}

egen firmproduct = group(id hs4)
tsset firmproduct year
gen newproduct = (L.i_ft==0 | missing(L.i_ft))*i_ft
gen droppedproduct = (F.i_ft==0 | missing(F.i_ft))*i_ft
* first time product ever appears
merge m:1 hs4 using `product_entry'
drop _m
gen new_hs4_code = (year==product_entry)*i_ft

* collapse by firms first
collapse (sum) i_ft newproduct droppedproduct new_hs4_code, by(id year)
merge m:1 id using `frame', keep(match)
drop _m

* emulate annual decomposition for entire sample
if "`1'"=="longrun" {
	gen enteringfirm = (birth>1992 & death>=2003)*i_ft
	gen exitingfirm = (birth<=1992 & death<2003)*i_ft
}
else {
	gen enteringfirm = (year==birth)*i_ft
	gen exitingfirm = (year==death)*i_ft
}
* now look at firm entry/exit
tsset id year
gen newfirm = (L.i_ft==0 | missing(L.i_ft))*i_ft
gen droppedfirm = (F.i_ft==0 | missing(F.i_ft))*i_ft

* if all products are new, do not double count them
replace newproduct=0 if newfirm
replace droppedproduct=0 if droppedfirm

ren i_ft totalimport

* change in imports w/o change in extensive margin
gen intensive = (totalimport-newproduct-newfirm)-(L.totalimport-L.droppedfirm-L.droppedproduct)
egen rank = rank(-newproduct), by(year) unique
l id newproduct if year==1996 & rank<=5
collapse (sum) totalimport intensive newproduct newfirm  droppedproduct droppedfirm enteringfirm exitingfirm new_hs4_code, by(year)
tsset year

* which firms enter and which start importing
replace newfirm = newfirm-enteringfirm
replace droppedfirm = droppedfirm-exitingfirm

gen Dimport = D.totalimport

foreach X of var dropped* exitingfirm {
    gen L`X' = -L.`X'
}

foreach X of var Dimport intensive newfirm newproduct enteringfirm Lexitingfirm Ldroppedfirm Ldroppedproduct new_hs4_code {
    replace `X' = `X'/L.totalimport*100
}
su totalimport if year==1995
* imports in millions of dollars
replace totalimport = totalimport/210.51/1e+6

order year totalimport Dimport intensive enteringfirm newfirm newproduct Lexitingfirm Ldroppedfirm Ldroppedproduct new_hs4_code

* round percentages to single digits
foreach X of var intensive enteringfirm newfirm newproduct Lexitingfirm Ldroppedfirm Ldroppedproduct new_hs4_code {
	replace `X' = round(`X'*10)/10 
}
* more human readable names
ren Dimport import_growth
ren intensive intensive_margin
ren enteringfirm new_firms
ren newfirm new_importers
ren newproduct new_products
ren Lexitingfirm stopping_firms
ren Ldroppedfirm stopping_importers
ren Ldroppedproduct dropped_products

outsheet using ../text/tables/table2`1'-import-margins.csv, comma names replace

log close
