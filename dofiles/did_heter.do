/* ============================================================================================
 * Program: did_heter.do
 * Data:	workingdata/did_data.dta
 * Aim:     heter results
 * Revised: 5/22/2023
 * =========================================================================================== */
use workingdata/did_data, clear
xtset id year
*-------------------------------------------------------------------*
*                      Heterogeneous Impacts                        *
*-------------------------------------------------------------------*
*----- compared with provincial level
	// by gdp per capita
	gen tp_Lgdppc = (Lgdppcraw >= Lprovgdppcraw) if !mi(Lgdppcraw)
	// by emission level
	sort id_pro year
	foreach v of varlist pm25 carbonpc effluentpc {
		by id_pro year: egen prov_`v'_med = median(`v')
		gen tpmed_`v'_1 = (`v' >= prov_`v'_med) if !mi(`v')
	}
	sort id year
	foreach v of varlist pm25 carbonpc effluentpc{
		by id: gen tpmedL_`v'_1 = L.tpmed_`v'_1
	}

	xtset id year
	// Panel A: Economic level
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm $xlist if tp_Lgdppc == 0, ab(year id) $cond
	eststo a2: qui: reghdfe $y1 $evm $xlist if tp_Lgdppc == 1, ab(year id) $cond
	eststo a5: qui: reghdfe $y3 $evm $xlist if tp_Lgdppc == 0, ab(year id) $cond
	eststo a6: qui: reghdfe $y3 $evm $xlist if tp_Lgdppc == 1, ab(year id) $cond
	eststo a7: qui: reghdfe $y4 $evm $xlist if tp_Lgdppc == 0, ab(year id) $cond
	eststo a8: qui: reghdfe $y4 $evm $xlist if tp_Lgdppc == 1, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		keep($evm) scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		mtitle(low high low high low high) ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 3 Panel A: Economic level")
	// Panel B: Emission level
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 $evm $xlist if tpmedL_pm25_1 == 0, ab(year id) $cond
	eststo a2: qui: reghdfe $y1 $evm $xlist if tpmedL_pm25_1 == 1, ab(year id) $cond
	eststo a5: qui: reghdfe $y3 $evm $xlist if tpmedL_carbonpc_1 == 0, ab(year id) $cond
	eststo a6: qui: reghdfe $y3 $evm $xlist if tpmedL_carbonpc_1 == 1, ab(year id) $cond
	eststo a7: qui: reghdfe $y4 $evm $xlist if tpmedL_effluentpc_1 == 0, ab(year id) $cond
	eststo a8: qui: reghdfe $y4 $evm $xlist if tpmedL_effluentpc_1 == 1, ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		keep($evm) scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		mtitle(low high low high low high) ///
		star(* 0.1 ** 0.05 *** 0.01) title("Table 3 Panel B: Emission level")