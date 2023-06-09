/* ============================================================================================
 * Program: main.do
 * Data:    workingdata/did_data.dta
 * Aim:     all results
 * Revised: 6/22/2023
 * =========================================================================================== */
clear
clear matrix
set more off
capture log close

cd "D:\data&code"
*-------------------------------------------------------------------*
*                             settings                              *
*-------------------------------------------------------------------*
* evm
	global evm evm
	global treat treat
	global evm1 evm_1
	global evm2 evm_2

* y ln value
	global y1 lpm25
	global y3 lcarbonpc
	global y4 leffluentpc

*------------------------------------controls----------------------------------
	global wage lwage_add
	global pop lpopden
	global gdppc lgdppcraw

	global xlist $gdppc gdpgr struc $pop open city_news temp temp2 precip
*-------------------------------------------------------------------------------

*** vce
	global cond cluster(id)
	
// baseline
	global result "did_evm_cid"
	do dofiles\did_baseline
	
// parallel pre-trend test
	global pre 4
	global post 4
	do dofiles\did_paral

// heter
	do dofiles\did_heter

// robust
	do dofiles\did_robust


*-------------------------------------------------------------------------------
// Descriptive Statistics
preserve
foreach v of varlist evm $xlist{
	drop if missing(`v')
}
logout, save(tables/Descriptive Statistics) word replace: tabstat ///
			lpm25 lcarbonpc leffluentpc evm $xlist, ///
            stats(count mean sd min p50 max)  c(s) f(%6.3f)
restore
*-------------------------------------------------------------------*
*                               placebo                             *
*-------------------------------------------------------------------*
// permute
	cap erase placebo\simulations1.dta
	permute $evm beta = _b[$evm] se = _se[$evm] df = e(df_r), ///
	 reps(500) rseed(123) saving(placebo\simulations1): ///
	  reghdfe $y1 $evm $xlist, ab(id year) $cond
	  
preserve
	//coeffcient density
	use placebo\simulations1.dta, clear
	gen t_value = beta / se
	gen p_value = 2 * ttail(df, abs(beta/se))

	#delimit ;
	twoway (scatter p_value beta, msymbol(diamond) mcolor(black) msize(vsmall))
			(kdensity beta, yaxis(2) lcolor(navy)),  
	 xline(-.0612542) 
	 xscale(range(-0.06 0.08)) yscale(range(0 3))
	 title("PM{subscript:2.5}")
	 xtitle("estimates") xlabel(#10) 
	 ytitle("p value") ylabel(#3, nogrid)
	 legend(r(1) order(2 "kdensity of estimates" 1 "p value"))
	 graphregion(color(white)) ;
	#delimit cr
	graph export figs/placebo.png, replace
restore
