/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Runs repetitions of a given specification.
  `1' gives the specification filename, e.g., table3_baseline
  `2' is the random seed for bootstrap, if 0, no bootstrap
*/

capture log close
set more off
clear all

* if running in MP mode use only 1 proc
if c(MP) {
    set processors 1
}

local dir ../doc/mapreduce
local inputfile `dir'/`1'/inputfile.dta
local resultfile `dir'/`1'/`2'.csv

/* load parameters and set globals*/
* if do-file is sectoral, do some preprocessing
if substr("`1'",length("`1'")-5,4)=="nace" {
	local function = substr("`1'",1,length("`1'")-2)
	local sector = substr("`1'",length("`1'")-1,2)
	do map/`function'.do `sector'
}
else {
	do map/`1'.do
}

if (`2'==0) {
	/* if directory for inputfile does not exist, create it */
	capture confirm new file `inputfile'
	if (_rc==603) {
		mkdir `dir'/`1'
	}

    /* invoke pre-estimation cleanup */
    do prepare_for_estimation
	        
    /* save input file for future repetitions */
    save `inputfile', replace
}
else {
   use `inputfile', clear
}

if `2'!=0 {
    /* this is a bootstrap */
    set seed `2'
    bsample, cluster(id) idcluster(newid)
    drop id
    ren newid id
	tsset id year
}
/* run the regression */
* pass all parameters to estimation so that TFP is not calculated in boostrap
do run_the_estimation `1' `2'
gen long seed = `2'

/* save results into a single csv file*/
outsheet using `resultfile', replace comma

set more on
exit, clear

