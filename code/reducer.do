/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Read .csv files with outputs of individual bootstrap repetitions and aggregate them.
  `1' is name of script to run.
 */

local dir ../doc/mapreduce/`1'
tempfile reduced
clear
save `reduced', replace emptyok

forval i=0/500 {
	capture confirm file `dir'/`i'.csv
	if !_rc {
		insheet using `dir'/`i'.csv, case clear
		append using `reduced'
		save `reduced', replace
	}
}

outsheet using `dir'/reduced.csv, comma replace

do sterrors
outsheet using `dir'/estimates.csv, comma replace
