
#delimit;
set more off;
clear;
set mem 400m;
set logtype text;
pause on;

cap log close;

************ LOCAL FOR RELEVANT FOLDERS - place path main folder here. Main folder should contain additional subfolders for regressions ("regs") and graphs ("graphs");
 local fileloc = "PLACE MAIN FILE PATH HERE";
 local gphtype eps;


local graphfold "`fileloc'/graphs";
local regsfold "`fileloc'/regs";

cd `fileloc' ;
log using APmainLog.txt, replace;

* LOCAL TO DEFINE OUTCOMES OF INTEREST;
local allvar "left_school suspended_ever 
		nextGPA probation_year1 totcredits_year1 hsgrade_pct age_at_entry 
		male english loc_campus3 loc_campus1 loc_campus2 bpl_north_america gradin4  gradin5 gradin6 probation_ever"; 

local covariates "hsgrade_pct totcredits_year1 age_at_entry male bpl_north_america english  loc_campus1  loc_campus2  loc_campus3  ";

local outcomes "left_school probation_year1 suspended_ever 
		nextGPA gradin4 gradin5 gradin6 probation_ever";
local ivoutcomes "suspended_ever gradin4 gradin5 gradin6";
/* Currently omitted outcomes:  gradin4orcont avgcoursegrade_year2 avgcoursegrade_year2noss  nextGPAminuscut_imp110 nextGPAminuscut_imp080 nextGPAminuscut_imp090 nextGPAminuscut_imp0
		   fallreg_year2 fallreg_year3 cumcredits2 cumcredits3 cumcredits4 */

local subgroups "lowHS highHS male female english noenglish"; *  Omitting:  maleXhighHS maleXlowabil femaleXhighHS femaleXlowabilenter18orless enter19ormore; 
* malemaleclasses malefemaleclasses femalemaleclasses femalefemaleclasses  easyhs hardhs  ;
local graduate "gradin4 gradin5 gradin6";
local leftpre "leftpre2any leftpre3any";

use `fileloc'/data_for_analysis.dta, clear;

***************************
*** REGRESSION ANALYSIS ***
***************************;
local outregoptions "se coe bdec(3) 3aster";
local regressors_ln "gpalscutoff gpaXgpalscutoff gpaXgpagrcutoff";
local stderropt "cluster(clustervar)";

local regressors_ln_noAP "gpaXgpalscutoff gpaXgpagrcutoff";

*local h1=1.4 ;
*forvalues k = 2/13 {;
*	local h`k' = round(`h1' - 0.10 * `k',0.1);
*};
*macro list;

local controls "male totcredits_year1 hsgrade_pct age_at_entry english loc_campus1 loc_campus3 bpl_north_america";

* temp1 is main used for saving main data set;
tempfile temp1;
* temp2 is limited to the subsample of interest;
tempfile temp2;

save `temp1';


*******************************************************;


*********** LOCAL LINEAR (USED IN AEJ DRAFT) ***************;


foreach strat in all {;

	use `temp1' if `strat'==1, clear;

	**** Covariates analysis;
	
	local append replace;

	foreach outcome in `covariates' {;

		reg `outcome' `regressors_ln' if dist_from_cut >= -0.6 & dist_from_cut <= 0.6, `stderropt' ;
		outreg using `regsfold'/`strat'_covariates_regs_ln.txt, `append' `outregoptions' ctitle(`outcome'_0.6);

		local append append;
		
	};

};

**** Main outcomes analysis of being placed on probation after 1st year;

foreach outcome in `outcomes' {;

	local append replace;

	foreach strat in all `subgroups' {;
		
		use `temp1' if `strat'==1, clear;

		reg `outcome' `regressors_ln' if dist_from_cut >= -0.6 & dist_from_cut <= 0.6, `stderropt' ;
		
		outreg using `regsfold'/`outcome'_regs_ln.txt, `append' `outregoptions' ctitle(`strat');
		local append append;
			
	};
	
};	


foreach strat in all `subgroups' {;

	use `temp1' if `strat'==1, clear;
		
	**** Total credits taken year 2, removing those who left school;
		
	reg totcredits_year2 `regressors_ln' if dist_from_cut < 0.6 & dist_from_cut > -0.6 & left_school ~= 1;

};




foreach strat in all `subgroups' {;

	**** Total credits taken year 2, all school;
		
	reg totcredits_year2 `regressors_ln' if dist_from_cut < 0.6 & dist_from_cut > -0.6;
	

};

********************************************************************
*****************************  GRAPHS ******************************
********************************************************************;

*********** DENSITY FIGURE *********;

* Regressions;
local outregoptions "pvalue coe bdec(3) 3aster";
local regressors_ln "gpalscutoff gpaXgpalscutoff gpaXgpagrcutoff";
local h=60;
foreach group in all `subgroups' {;
	use `temp1', clear;
	keep if `group'==1;
	drop if dist_from_cut > 1.2 | dist_from_cut<-1.2;
	gen freq=1;
	local append replace;
	foreach round in 01 02 04 05 10 {;
		gen dist_from_cut_round`round'=round(dist_from_cut - 0.`round'/2 + .0001, 0.`round') + 0.`round'/2;
		preserve;
		collapse (count) freq, by(dist_from_cut_round`round');
		gen gpalscutoff=dist_from_cut_round`round'<0;
		gen gpaXgpalscutoff=(dist_from_cut_round`round')*gpalscutoff;
		gen gpaXgpagrcutoff=(dist_from_cut_round`round')*(1-gpalscutoff);
		reg freq `regressors_ln' if dist_from_cut_round`round'<=(`h'/100) & dist_from_cut_round`round'>=-(`h'/100), robust;
		outreg gpalscutoff using `regsfold'/Mccrary_round_`group'_bwidth`h'.txt, `append' `outregoptions' ctitle(`round') addnote(Bandwidth=`h');
		local append append;
		restore;	
	};		
};		

	
* Figures;
local stepsize=0.05;
local totsteps=2*(1.2/`stepsize') + 1;
local bwidth=.6;
local circlesize "large";
local regressors_ln "gpalscutoff gpaXgpalscutoff gpaXgpagrcutoff";
local round 10;
	
foreach group in all `subgroups' {;	
	use `temp1', clear;
	keep if `group'==1;
	drop if dist_from_cut > 1.2 | dist_from_cut<-1.2;
	gen freq=1;
	gen dist_from_cut_round`round'=round(dist_from_cut - 0.`round'/2 + .0001, 0.`round') + 0.`round'/2;
	collapse (count) freq, by(dist_from_cut_round`round');
	gen dist_from_cut=.;
	gen gpalscutoff=dist_from_cut_round`round'<0;
	gen gpaXgpalscutoff=(dist_from_cut_round`round')*gpalscutoff;
	gen gpaXgpagrcutoff=(dist_from_cut_round`round')*(1-gpalscutoff);
	
	* Get predicted values by local linear regressions;
	local step=0;		
	forvalues myx=-1.2(`stepsize')1.2 {;
		local step=`step'+1;
		preserve;
			reg freq `regressors_ln' if dist_from_cut_round`round' >= `myx'-`bwidth' & dist_from_cut_round`round' <= `myx' + `bwidth';
			keep if _n==1;
			keep dist_from_cut;
			replace dist_from_cut=`myx';
			gen gpalscutoff=dist_from_cut<0;
			gen gpaXgpalscutoff=(dist_from_cut)*gpalscutoff;
			gen gpaXgpagrcutoff=(dist_from_cut)*(1-gpalscutoff);
			predict graph_freq;
			gen dist_from_cut_round`round'=`myx';
			save temp_pred`step', replace;
		restore;
	};
	preserve;
		use temp_pred1, clear;
		forvalues g=2(1)`step' {;
			append using temp_pred`g';
		};
		save temp_pred, replace;
	restore;
	append using temp_pred;
	twoway scatter freq dist_from_cut_round`round', msize(large) mfcolor(none) mlcolor(gray) xline(0, lpattern(dash) lcolor(gray)) graphregion(fcolor(white) lcolor(white))
			|| line graph_freq dist_from_cut_round`round' if dist_from_cut_round`round'<0, lcolor(black) 
			|| line graph_freq dist_from_cut_round`round' if dist_from_cut_round`round'>=0, lcolor(black)
			legend(off) ytitle(Frequency Count) xtitle(1st Year GPA Minus Probation Cutoff) plotregion(margin(zero)) 
			xlabel(-1.5(0.5)1.5) xscale(r(-1.6 1.6)) saving(`graphfold'/mccrary_graph_round`round'_`group', replace);
			graph export `graphfold'/mccrary_graph_round`round'_`group'.`gphtype', replace;	
	};

local outregoptions "se coe bdec(3) 3aster";


********************************************************
*********************** FIGURES ************************
********************************************************;

local graphoptions "xline(0, lpattern(dash) lcolor(gray))
		xlabel(-1.5(0.5)1.5) xscale(r(-1.5 1.5))
		legend(off)
		graphregion(fcolor(white) lcolor(white)) xtitle(" " "1st Year GPA Minus Probation Cutoff") plotregion(margin(zero))";

local graphoptions_grad  "xline(0, lpattern(dash) lcolor(gray))
		legend( label(1 "Within 4 years") label(2 "Within 5 years") label(3 "Within 6 years") rows(1) c(1) region(lwidth(vvthin)) order(1 2 3))
		xlabel(-1.5(0.5)1.5) xscale(r(-1.6 1.6))
		graphregion(fcolor(white) lcolor(white)) xtitle(" " "1st Year GPA Minus Probation Cutoff")";
		
local graphoptions_credits  "xline(0, lpattern(dash) lcolor(gray))
		legend(label(1 "After 2nd Year") label(2 "After 3rd Year") label(3 "After 4th Year") rows(1) c(1) region(lwidth(vvthin)) order(1 2 3))
		xlabel(-1.5(0.5)1.5) xscale(r(-1.6 1.6))
		graphregion(fcolor(white) lcolor(white)) xtitle(" " "1st Year GPA Minus Probation Cutoff")";

local graphoptions_leftpre  "xline(0, lpattern(dash) lcolor(gray))
		legend(label(1 "Before 2nd Year") label(2 "Before 3rd Year") rows(1) c(1) region(lwidth(vvthin)) order(1 2))
		xlabel(-1.5(0.5)1.5) xscale(r(-1.6 1.6))
		graphregion(fcolor(white) lcolor(white)) xtitle(" " "1st Year GPA Minus Probation Cutoff")";

* Y-axis choices for each variable;
local probation_year1_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.5)1) yscale(r(0 1)) ytitle(Probation Status )";
local totcredits_year1_yspecs "ytick(3(1)5, grid) ylabel(3(1)5) yscale(r(3 5)) ytitle(Credits Attempted in 1st Year )  title((b))";
local hsgrade_pct_yspecs "ytick(0(10)70, grid) ylabel(0(20)60) yscale(r(0 70)) ytitle(High School Grade Percentile Rank ) title((a))";
local age_at_entry_yspecs "ytick(18(1)20, grid) ylabel(18(1)20) yscale(r(18 20)) ytitle(Age at Entry ) title((c))";
local male_yspecs "ytick(.2(0.1).6, grid) ylabel(.2(0.2).6) yscale(r(.2 .6)) ytitle(Male)  title((d))";
local english_yspecs "ytick(.5(0.1).9, grid) ylabel(.5(0.2).9) yscale(r(.5 .9)) ytitle(English is 1st Language )  title((f))";
local loc_campus3_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.2)1) yscale(r(0 1)) ytitle(At Campus 3 )  title((i))";
local loc_campus2_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.2)1) yscale(r(0 1)) ytitle(At Campus 2 )  title((h))";
local loc_campus1_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.2)1) yscale(r(0 1)) ytitle(At Campus 1 )  title((g))";
local bpl_north_america_yspecs "ytick(.6(0.1)1, grid) ylabel(.6(0.2)1) yscale(r(.6 1)) ytitle(Born in North America )  title((e))";
local left_school_yspecs "ytick(0(0.05).25, grid) ylabel(0(0.1).2) yscale(r(0 .25)) ytitle(Left University Voluntarily )";
local nextGPA_yspecs "ytick(-1(0.5)1, grid) ylabel(-1(1)1.5) yscale(r(-1 1.5)) ytitle(Subsequent GPA Minus Cutoff )";
local gradin4_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.5)1) yscale(r(0 1)) ytitle(Graduated within 4 years )";
local gradin5_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.5)1) yscale(r(0 1)) ytitle(Graduated within 5 years )";
local gradin6_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.5)1) yscale(r(0 1)) ytitle(Graduated within 6 years )";
local gradin4orcont_yspecs "ytick(0(0.1)1, grid) ylabel(0(0.5)1) yscale(r(0 1)) ytitle(Graduated within 4 years or continuing )";

* Variable that determines cell sizes for means for each group;
local stepsize=0.05;
local totsteps=2*(1.2/`stepsize') + 1;
local bwidth=.6;
local cellvar "dist_from_cut_med10";
local circlesize "large";
local regressors_ln "gpalscutoff gpaXgpalscutoff gpaXgpagrcutoff";

******Iteration Code for Generation fallreg_year2 by different subsamples******;

** This loop runs different interations of the data - full sample and restricted samples;

foreach strat in all {;

	****************************All but grad **************************;

	foreach outcome in `allvar' {;
		use `temp1', clear;
		keep if `strat'==1;
		drop if dist_from_cut>1.2 | dist_from_cut<-1.2;
		* Get predicted values by local linear regressions;
		local step=0;				
		forvalues myx=-1.2(`stepsize')1.2 {;
			local step=`step'+1;
			preserve;
				reg `outcome' `regressors_ln' if dist_from_cut >= `myx'-`bwidth' & dist_from_cut <= `myx' + `bwidth';
				keep if _n==1;
				keep dist_from_cut;
				replace dist_from_cut=`myx';
				gen gpalscutoff=dist_from_cut<0;
				gen gpaXgpalscutoff=(dist_from_cut)*gpalscutoff;
				gen gpaXgpagrcutoff=(dist_from_cut)*(1-gpalscutoff);
				predict `outcome'_pred;
				save temp_pred`step', replace;
			restore;
		};
		preserve;
			use temp_pred1, clear;
			forvalues g=2(1)`step' {;
				append using temp_pred`g';
			};
			save temp_pred, replace;
		restore;
		collapse `outcome', by(`cellvar');
		cap rename `cellvar' dist_from_cut;
		gen mean=1;
		append using temp_pred;  * this adds predicted curves;
		twoway scatter `outcome' dist_from_cut if mean==1 ,
			msize(`circlesize') mfcolor(none) mlcolor(gray)
			|| line `outcome'_pred dist_from_cut if dist_from_cut<0, sort lcolor(black)
			|| line `outcome'_pred dist_from_cut if dist_from_cut>=0, sort lcolor(black)
			`graphoptions'		
			``outcome'_yspecs' saving(`graphfold'/`strat'GRP_`outcome', replace);
		graph export `graphfold'/`strat'GRP_`outcome'.`gphtype', replace;
	};

};
	
** Subgroup "left school" Graphs;

foreach strat in lowHS highHS male female english noenglish {;

	foreach outcome in left_school {;
		use `temp1', clear;
		keep if `strat'==1;
		drop if dist_from_cut>1.2 | dist_from_cut<-1.2;
		* Get predicted values by local linear regressions;
		local step=0;				
		forvalues myx=-1.2(`stepsize')1.2 {;
			local step=`step'+1;
			preserve;
				reg `outcome' `regressors_ln' if dist_from_cut >= `myx'-`bwidth' & dist_from_cut <= `myx' + `bwidth';
				keep if _n==1;
				keep dist_from_cut;
				replace dist_from_cut=`myx';
				gen gpalscutoff=dist_from_cut<0;
				gen gpaXgpalscutoff=(dist_from_cut)*gpalscutoff;
				gen gpaXgpagrcutoff=(dist_from_cut)*(1-gpalscutoff);
				predict `outcome'_pred;
				save temp_pred`step', replace;
			restore;
		};
		preserve;
			use temp_pred1, clear;
			forvalues g=2(1)`step' {;
				append using temp_pred`g';
			};
			save temp_pred, replace;
		restore;
		collapse `outcome', by(`cellvar');
		cap rename `cellvar' dist_from_cut;
		gen mean=1;
		append using temp_pred;  * this adds predicted curves;
		twoway scatter `outcome' dist_from_cut if mean==1 ,
			msize(`circlesize') mfcolor(none) mlcolor(gray)
			|| line `outcome'_pred dist_from_cut if dist_from_cut<0, sort lcolor(black)
			|| line `outcome'_pred dist_from_cut if dist_from_cut>=0, sort lcolor(black)
			`graphoptions'		
			``outcome'_yspecs' saving(`graphfold'/`strat'GRP_`outcome', replace);
		graph export `graphfold'/`strat'GRP_`outcome'.`gphtype', replace;
	};	
	
	
	
	
	
	local left_school_yspecs "ytick(0(0.05).35, grid) ylabel(0(0.1).3) yscale(r(0 .35)) ytitle(Left University Voluntarily )";

	***************************Graduation Year*********************************;
  
	use `temp1', clear;
	keep if all==1;
		drop if dist_from_cut>1.2 | dist_from_cut<-1.2;
		
	* Get predicted values by local linear regressions;
	foreach outcome in gradin4 gradin5 gradin6 {;
		local step=0;		
		forvalues myx=-1.2(`stepsize')1.2 {;
			local step=`step'+1;
			preserve;
				reg `outcome' `regressors_ln' if dist_from_cut >= `myx'-`bwidth' & dist_from_cut <= `myx' + `bwidth';
				keep if _n==1;
				keep dist_from_cut;
				replace dist_from_cut=`myx';
				gen gpalscutoff=dist_from_cut<0;
				gen gpaXgpalscutoff=(dist_from_cut)*gpalscutoff;
				gen gpaXgpagrcutoff=(dist_from_cut)*(1-gpalscutoff);
				predict `outcome'_pred;
				save temp_pred`step', replace;
			restore;
		};
		
		
		preserve;
			use temp_pred1, clear;
			forvalues g=2(1)`step' {;
				append using temp_pred`g';
			};
			save temp_pred_`outcome', replace;
		restore;
	};
	collapse gradin4 gradin5 gradin6, by(`cellvar');
	cap rename `cellvar' dist_from_cut;
	gen mean=1;
	append using temp_pred_gradin4;
	append using temp_pred_gradin5;
	append using temp_pred_gradin6;
	twoway scatter gradin4 dist_from_cut if mean==1,
		msize(`circlesize') mfcolor(none) mlcolor(gray) msymbol(O)
		|| scatter gradin5 dist_from_cut if mean==1,
		msize(`circlesize') mfcolor(none) mlcolor(midblue) msymbol(X)
		|| scatter gradin6 dist_from_cut if mean== 1,
		msize(`circlesize') mfcolor(none) mlcolor(red) msymbol(T)
		|| line gradin4_pred dist_from_cut if dist_from_cut<0, sort lcolor(black)
		|| line gradin4_pred dist_from_cut if dist_from_cut>=0, sort lcolor(black)
		|| line gradin5_pred dist_from_cut if dist_from_cut<0, sort lcolor(blue)
		|| line gradin5_pred dist_from_cut if dist_from_cut>=0, sort lcolor(blue)
		|| line gradin6_pred dist_from_cut if dist_from_cut<0, sort lcolor(cranberry)
		|| line gradin6_pred dist_from_cut if dist_from_cut>=0, sort lcolor(cranberry)				
		`graphoptions_grad'		
		`grad_yspecs';
	graph export `graphfold'/`strat'GRP_grad.`gphtype', replace;

};

***********************Combining Covariate Graphs*****************************;
*** 9 tests of observables;
cd graphs;
**All observables;
local graph "";
foreach k in hsgrade_pct totcredits_year1 age_at_entry male bpl_north_america english loc_campus1 loc_campus2 loc_campus3  {;
	local graph " `graph' allGRP_`k'.gph";
};
di "`graph'";
graph combine `graph' , iscale(*0.7) graphregion(fcolor(white) lcolor(white)) saving(`fileloc'/graphs/all_covariates, replace);
graph export `fileloc'/graphs/all_covariates.`gphtype', replace;

log close;

exit, clear;

