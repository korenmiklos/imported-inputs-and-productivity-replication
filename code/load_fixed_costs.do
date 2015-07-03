/*
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Load estimated fixed costs into memory.
*/
insheet using ../data/fixed_cost_mu_estimates.csv, comma names clear
mkmat exp_mu_n_0 exp_mu_n_1, matrix(exp_mu_n)
matrix cumulated_exp_mu = J(366,2,0)
forval foreign = 1/2 {
	matrix cumulated_exp_mu[1,`foreign'] = exp_mu_n[1,`foreign']
	forval n=2/366 {
		matrix cumulated_exp_mu[`n',`foreign'] = cumulated_exp_mu[`n'-1,`foreign']+exp_mu_n[`n',`foreign']	
	}
}
