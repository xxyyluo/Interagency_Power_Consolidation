/* ============================================================================================
 * Program: did_baseline.do
 * Data:	workingdata/did_data.dta
 * Aim:     baseline
 * Revised: 5/22/2023
 * =========================================================================================== */
use workingdata/did_data, clear
xtset id year
*-------------------------------  DID -------------------------------*

// baseline
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm, ab(year id) $cond
	eststo a2: qui: reghdfe $y1 $evm $xlist, ab(year id) $cond
	eststo a5: qui: reghdfe $y3 $evm, ab(year id) $cond
	eststo a6: qui: reghdfe $y3 $evm $xlist, ab(year id) $cond
	eststo a7: qui: reghdfe $y4 $evm, ab(year id) $cond
	eststo a8: qui: reghdfe $y4 $evm $xlist, ab(year id) $cond
	esttab a* using tables/$result.rtf, replace ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 2 baseline")
