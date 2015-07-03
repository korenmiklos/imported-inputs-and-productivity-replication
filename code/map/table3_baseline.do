/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Set necessary constants for a specification. 
This do-file cannot be run by itself, it is called by "estimate_specification.do".
*/

global datafile ../data/impmanuf

/* LHS variable*/
global output PlnQ


/* There are two kinds of state variables.
$states are in the production function.
$bygroup, $dummies
    affect the investment decision, hence are in the proxy, but do not directly affect TFP. */

/* proxies for demand */
global demand lnQs2 corrected_firm_demand 
/* RHS variables identified in the first stage*/
global free ""

/* proxy for productivity */
global proxy inv
/* proxy function is estimated separately for each group */
global bygroup year
/* simple linear dummies to include in both proxy and prod fcn */
global dummies nace2year me
/* state variables */
global states lnK lnL afterforeign
/* these states only enter linearly */
global linear demand_1 demand_2  
/* instruments should include all states and lags */
global instruments lnK L.lnK lnL L.lnL afterforeign L.afterforeign demand_1  L.demand_1 demand_2 
/* This is set of variables indexing IAP */
global IAPgroup egy

/* product count is based on the number of 4-digit categories */
global Ni N4i
/* this is not a sector-specific estimation */
global sector 0

/* define expression for sample */
global sample 1==1

