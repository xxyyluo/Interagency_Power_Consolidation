/* ============================================================================================
 * Program: main.do
 * Data:	workingdata/data.dta
 * Aim:     all results
 * Revised: 5/22/2023
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
	use workingdata/wdata, clear
	global evm evm
	global treat treat
	global evm1 evm_1
	global evm2 evm_2
		* 新建一个变量，使得第一期evm = 0, 之前为-1，-2...，之后为1，2...
		by id: gen fz1 = $evm - $evm[_n-1]
		gen fz2 = (fz1 == 1)*year
		rangestat (max) fz2, interval(year . .) by(id)
		rename fz2_max startyr
		replace startyr = . if startyr == 0
		drop fz1 fz2
		gen policy = year - startyr
		replace policy = . if startyr == 0 | mi($evm)
	save workingdata\did_data, replace

* y ln value
	global y1 lpm25
	global y3 lcarbonpc
	global y4 leffluentpc

*------------------------------------controls----------------------------------
	global struc struc_add
	global wage lwage_add
	global popden lpopden
	global gdp lgdppc
	global gdp2 lgdppc2
	global open open_add
	global fiscal fiscal_add
	global sales sales_add

	global xlist lgdppcraw gdpgr $struc $popden $open city_news tem tem2 rain
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
