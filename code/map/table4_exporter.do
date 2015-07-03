/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Set necessary constants for a specification. 
This do-file cannot be run by itself, it is called by "estimate_specification.do".
*/
do map/table4_foreign.do
global states lnK lnL afterforeign exporter
global instruments lnK L.lnK lnL L.lnL afterforeign L.afterforeign exporter L.exporter demand_1  L.demand_1 demand_2 
