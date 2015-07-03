/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Set necessary constants for a specification. 
This do-file cannot be run by itself, it is called by "estimate_specification.do".
*/

global datafile ../data/impmanuf
/* LHS variable*/
global output PlnQ

/* RHS variables identified in the first stage*/
global free ""
/* proxies for demand */
global demand lnQs2 corrected_firm_demand 

/* There are two kinds of state variables.
$states are in the production function.
$bygroup, $dummies
    affect the investment decision, hence are in the proxy, but do not directly affect TFP. */

/* proxy for productivity */
global proxy inv
/* proxy function is estimated separately for each group */
global bygroup year
/* simple linear dummies to include in both proxy and prod fcn */
global dummies nace2year me 
/* state variables */
global states lnK lnL afterforeign 
/* This is set of variables indexing IAP */
global IAPgroup egy

global linear demand_1 demand_2
global instruments lnK L.lnK lnL L.lnL afterforeign L.afterforeign demand_1 L.demand_1 demand_2

/* product count is based on the number of 4-digit categories */
global Ni N4i
/* which N to use */
global sector `1'

/* define expression for sample */
global sample nace2==$sector
