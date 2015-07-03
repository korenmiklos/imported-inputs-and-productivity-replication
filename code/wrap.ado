/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.
*/

program define wrap
/*

Wraps a Stata command to read inputs from CL parameters and write scalars to filename.

Usage:

	wrap /results/output scalar A=1 B=2 global input "inputfile.dta" : do long_estimation

This will save results in

	/results/output_A~1+B~2.csv
*/

* verify parameters
confirm exist `1'
confirm exist `2'

* to ensure a clean slate, drop all scalars and global macros
clear all
global drop _all
scalar drop _all
program drop _all

local _outputfile `1'
local input_string ""
macro shift 

scalar after = 0
local command ""
local mode "scalar"
while "`1'"!="" {
	if after==0 {
		if "`1'"==":" {
			scalar after=1
		}
		else {
			local _value = subinstr("`1'", "=", "~", .)
			local input_string "`input_string'+`_value'"
			di "`input_string'"
			if "`1'"=="global" {
				local mode "global-key"
			}
			else if "`1'"=="scalar" {
				local mode "scalar"
			}
			else {
				if "`mode'"=="scalar" scalar `1'
				if "`mode'"=="global-value" {
					global `_key' `1'
					local mode "global-key"
				}
				if "`mode'"=="global-key" {
					local _key `1'
					local mode "global-value" 
				}
			}
		}
	}
	else {
		local command "`command' `1'"
	}
	macro shift
}
scalar drop after
* run Stata command
`command'

drop _all
local outputs : all scalars
set obs 1
foreach param in `outputs' {
	gen `param' = `param'
}

* outsheet using "`_outputfile'", comma names replace
outsheet using "`_outputfile'`input_string'.csv", comma names replace
end
