/* ============================================================================================
 * Program: did_robust.do
 * Data:	workingdata/did_data.dta
 * Aim:     robustness check
 * Revised: 5/22/2023
 * =========================================================================================== */
use workingdata/did_data, clear
xtset id year
*-------------------------------------------------------------------*
*                         exogeneity check                          *
*-------------------------------------------------------------------*	
// Reverse Causality Test
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $evm L.$y1 L2.$y1, ab(year id) $cond
	eststo a2: qui: reghdfe $evm L.$y1 L2.$y1 $xlist, ab(year id) $cond
	eststo a5: qui: reghdfe $evm L.$y3 L2.$y3, ab(year id) $cond
	eststo a6: qui: reghdfe $evm L.$y3 L2.$y3 $xlist, ab(year id) $cond
	eststo a7: qui: reghdfe $evm L.$y4 L2.$y4, ab(year id) $cond
	eststo a8: qui: reghdfe $evm L.$y4 L2.$y4 $xlist, ab(year id) $cond
	eststo a9: qui: reghdfe $evm L.$y1 L2.$y1 L.$y3 L2.$y3 L.$y4 L2.$y4, ab(year id) $cond
	eststo a10: qui: reghdfe $evm L.$y1 L2.$y1 L.$y3 L2.$y3 L.$y4 L2.$y4 $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		keep(L.* L2.*) scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 4 Reverse causality test")

// Omitted Variable Test: city level
* Panel A: Experienced
	gen evm_envir1 = (envir_capacity_v1 == 1 & $evm == 1) if !mi($evm)
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm evm_envir1 $xlist, ab(year id) $cond
	eststo a3: qui: reghdfe $y3 $evm evm_envir1 $xlist, ab(year id) $cond
	eststo a4: qui: reghdfe $y4 $evm evm_envir1 $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm evm_envir1)  ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 5 Panel A")

* Panel B: Promoted
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm evm_pro $xlist, ab(year id) $cond
	eststo a3: qui: reghdfe $y3 $evm evm_pro $xlist, ab(year id) $cond
	eststo a4: qui: reghdfe $y4 $evm evm_pro $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm evm_pro)  ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 5 Panel B")

* Panel C: Familiar
	gen evm_cwyr_20 = workcitytime >= 20 if !mi(workcitytime)
	replace evm_cwyr_20 = 0 if (mi(workcitytime) & $evm ==0 ) | (evm_cwyr_20 == 1 & $evm == 0)
	global evm_cwyr evm_cwyr_20
		
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm $evm_cwyr $xlist, ab(year id) $cond
	eststo a3: qui: reghdfe $y3 $evm $evm_cwyr $xlist, ab(year id) $cond
	eststo a4: qui: reghdfe $y4 $evm $evm_cwyr $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm $evm_cwyr)  ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 5 Panel C")
** robustness check for Panel C: Familiar
foreach v of numlist 5 10 30{
	gen evm_cwyr_`v' = workcitytime >= `v' if !mi(workcitytime)
	replace evm_cwyr_`v' = 0 if (mi(workcitytime) & $evm ==0 ) | (evm_cwyr_`v' == 1 & $evm == 0)
	global evm_cwyr evm_cwyr_`v'
		
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm $evm_cwyr $xlist, ab(year id) $cond
	eststo a3: qui: reghdfe $y3 $evm $evm_cwyr $xlist, ab(year id) $cond
	eststo a4: qui: reghdfe $y4 $evm $evm_cwyr $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm $evm_cwyr)  ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table A2")
}

* Panel D: Neighboring PM2.5 concentration level
	eststo clear
	cap drop _est*
forvalues n = 5(1)10{
	use workingdata/sur_pm25, clear
	keep if sss <= `n'
	collapse (mean) pm25, by(city year)
	replace pm25 = ln(pm25)
	rename pm25 sur_lpm25_`n'
	save tempdata/sur_lpm25_`n', replace
	
	use workingdata/did_data, clear
	merge 1:1 city year using tempdata/sur_lpm25_`n'
	drop if _m == 2
	drop _m

	xtset id year
	eststo a`n': qui: reghdfe $y1 $evm sur_lpm25_`n' $xlist, ab(year id) $cond
}
	esttab a5 a10 using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm sur_lpm25*) ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 5 panel D")
** robustness check for Panel D
	esttab a6 a7 a8 a9 using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm sur_lpm25*) ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table A3")
		

// Omitted Variable Test: province level
	eststo clear
	cap drop _est*
	eststo a2: qui: reghdfe $y1 $evm prov_news $xlist, ab(year id) $cond
	eststo a6: qui: reghdfe $y3 $evm prov_news $xlist, ab(year id) $cond
	eststo a8: qui: reghdfe $y4 $evm prov_news $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm prov_news) ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 6 panel A")
		
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm prov_evm $xlist, ab(year id) $cond
	eststo a5: qui: reghdfe $y3 $evm prov_evm $xlist, ab(year id) $cond
	eststo a7: qui: reghdfe $y4 $evm prov_evm $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		keep($evm prov_evm) ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 6 panel B")

	
// Measurement Error
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm1 $xlist, ab(year id) $cond
	eststo a2: qui: reghdfe $y1 $evm2 $xlist, ab(year id) $cond
	eststo a5: qui: reghdfe $y3 $evm1 $xlist, ab(year id) $cond
	eststo a6: qui: reghdfe $y3 $evm2 $xlist, ab(year id) $cond
	eststo a7: qui: reghdfe $y4 $evm1 $xlist, ab(year id) $cond
	eststo a8: qui: reghdfe $y4 $evm2 $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		keep($evm1 $evm2) scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 7")