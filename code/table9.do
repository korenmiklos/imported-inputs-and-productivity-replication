/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Create Table 9.
*/
clear all
set more off

capture prog drop transformations 
prog define transformations 
	gen tariff = round((exp(logtau)*100-100)/2)*2
	tsset tariff
	foreach X of var outcome? {
		gen D_`X' = 100*exp(L10.`X'-`X')-100
	}
	keep if tariff==40 | tariff==10
end

* top panel of Table 9
use ../doc/offset_tfp_gain, clear

transformations

keep tariff D_outcome*
ren tariff Reducing_10_percent_from
ren D_outcome1 Low_fixed_cost
ren D_outcome2 Baseline
ren D_outcome3 High_fixed_cost

gsort -Reducing
order Reducing High Baseline Low 
outsheet using ../text/tables/table9-top.csv, comma replace

* bottom panel of Table 9
use ../doc/foreignpresence_tfp_gain, clear

transformations

keep tariff D_outcome*
ren tariff Reducing_10_percent_from
ren D_outcome1 No_foreign_firms
ren D_outcome2 Baseline
ren D_outcome3 All_firms_foreign

gsort -Reducing
order Reducing No Baseline All
outsheet using ../text/tables/table9-bottom.csv, comma replace

set more on
