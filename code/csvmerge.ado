program define csvmerge
    /* this ado program merges directly from .csv file */
    syntax varlist using/ [, nokeep]

    tempfile mergefile
    preserve
    clear
    insheet using "`using'"
    sort `varlist'
    save `mergefile', replace

    restore
    sort `varlist'
    merge `varlist' using `mergefile', `nokeep'


end
