/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Given a set of parameter values, calculate the optimal number "n" of imported products for each firm.
*/

confirm numeric variable afterforeign pi0 ahat u_jt mean_log_fixed_cost
confirm new variable N GN importer
confirm scalar gammastar
confirm matrix cumulated_exp_mu

gen N = 0
replace N = . if missing(pi0,ahat,mean_log_fixed_cost,u_jt)
tempvar profitgain fperpi
gen `fperpi' = exp(mean_log_fixed_cost+u_jt)/pi0
gen `profitgain' = 0
forval foreign=0/1 {
	forval n=1/150 {
		local net_benefit exp(ahat*gammastar/(1-gammastar)*Gn[`n'+1,1])-1-`fperpi'*cumulated_exp_mu[`n',`foreign'+1] 
		qui replace N=`n' if `net_benefit'>`profitgain' &  !missing(`fperpi') & afterforeign==`foreign'
		qui replace `profitgain' = `net_benefit' if `net_benefit'>`profitgain'  & !missing(`fperpi') & afterforeign==`foreign'
	}
}

GN GN, n(N)
tab N if N<=10

qui gen byte importer = N>0

assert N==0 | N==1 | N==2 | N>=3
assert GN>=0 & (GN<=Gmax+0.01 | missing(GN))
assert importer==0 | importer==1


