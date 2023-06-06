/* ============================================================================================
 * Program: did_paral.do
 * Data:	workingdata/did_data.dta
 * Aim:     parallel
 * Revised: 5/22/2023
 * =========================================================================================== */
use workingdata/did_data, clear
xtset id year
	* pre post
	forvalues l = 0/$post {
		gen post_`l' = policy == `l'
	}
	replace post_$post = $post if policy > $post & !mi(policy)	
	forvalues l = $pre(-1)1 {
		gen pre_`l' = policy== -`l'
	}
	replace pre_$pre = -$pre if policy < -$pre & !mi(policy)
	
	* reg
	eststo clear
	cap drop _est*
	eststo a1: qui: reghdfe $y1 pre_* post_* $xlist if !mi(evm), ab(year id) $cond
	eststo a3: qui: reghdfe $y3 pre_* post_* $xlist if !mi(evm), ab(year id) $cond
	eststo a4: qui: reghdfe $y4 pre_* post_* $xlist if !mi(evm), ab(year id) $cond
	esttab a* using tables/$result.rtf, append ///
		scalar(N r2_a) b(%9.3f) ar2(%9.3f) se compress nogap ///
		star(* 0.1 ** 0.05 *** 0.01) title("parallel test: pre$pre post$post")

// graph
	coefplot a1, keep(pre_* post_*) levels(95) ///
		vertical recast(connect) lc(black) lp(dash) mfcolor(black) msymbol(h) msize(small) ///
		ciopts(recast(rcap) lc(gs0)) blcolor(black) ///
		yline(0, lc(black) lw(thin)) ///
		coeflabels(pre_4 = "{&le}-4"   ///
		pre_3 = -3             ///
		pre_2 = -2              ///
		pre_1 = -1             ///
		post_0  = 0             ///
		post_1  = 1              ///
		post_2  = 2             ///
		post_3  = 3              ///
		post_4  = "{&ge}4")            ///
		plotr(lcolor(black) lpattern(1) lwidth(*1.5)) ///
		ytitle("Coefficient estimates", size(*1)) ///
		xtitle("Years relative to treatment", size(*1)) /// 
		ysize(1) xsize(1.25) graphregion(color(white)) ///
		legend(order (2 "Coefficient" 1 "95% CI")) ///
		title(PM{sub:2.5})
	graph export figs/paral_pm25.png, replace
	
	coefplot a3, keep(pre_* post_*) levels(95) ///
		vertical recast(connect) lc(black) lp(dash) mfcolor(black) msymbol(h) msize(small) ///
		ciopts(recast(rcap) lc(gs0)) blcolor(black) ///
		yline(0, lc(black) lw(thin)) ///
		coeflabels(pre_4 = "{&le}-4"   ///
		pre_3 = -3             ///
		pre_2 = -2              ///
		pre_1 = -1             ///
		post_0  = 0             ///
		post_1  = 1              ///
		post_2  = 2             ///
		post_3  = 3              ///
		post_4  = "{&ge}4")            ///
		plotr(lcolor(black) lpattern(1) lwidth(*1.5)) ///
		ytitle("Coefficient estimates", size(*1)) ///
		xtitle("Years relative to treatment", size(*1)) /// 
		ysize(1) xsize(1.25) graphregion(color(white)) ///
		legend(order (2 "Coefficient" 1 "95% CI")) ///
		title(CO{sub:2})
	graph export figs/paral_co2.png, replace
	
	coefplot a4, keep(pre_* post_*) levels(95) ///
		vertical recast(connect) lc(black) lp(dash) mfcolor(black) msymbol(h) msize(small) ///
		ciopts(recast(rcap) lc(gs0)) blcolor(black) ///
		yline(0, lc(black) lw(thin)) ///
		coeflabels(pre_4 = "{&le}-4"   ///
		pre_3 = -3             ///
		pre_2 = -2              ///
		pre_1 = -1             ///
		post_0  = 0             ///
		post_1  = 1              ///
		post_2  = 2             ///
		post_3  = 3              ///
		post_4  = "{&ge}4")            ///
		plotr(lcolor(black) lpattern(1) lwidth(*1.5)) ///
		ytitle("Coefficient estimates", size(*1)) ///
		xtitle("Years relative to treatment", size(*1)) /// 
		ysize(1) xsize(1.25) graphregion(color(white)) ///
		legend(order (2 "Coefficient" 1 "95% CI")) ///
		title(Effluent)
	graph export figs/paral_efflu.png, replace
	
