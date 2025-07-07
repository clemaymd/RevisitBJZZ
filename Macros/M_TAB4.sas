%macro M_TAB4(x,y,dsin,subgroup_var);

	/* subgroup class variables */
	%if &subgroup_var = mktcap %then %do; %let classvar = size; %end; 
	%if &subgroup_var = shrprc %then %do; %let classvar = lmp; %end; 
	%if &subgroup_var = turnover %then %do; %let classvar = lto; %end; 
	
	data hft2; set &dsin;
	x = l&x;
	y = f&y;
	ly = l&y;
	lvol = lvol&y;
	run;
	
	/* Create subgroups based on the complete case DS to ensure having 1/3 of stocks in each tercile */
	data CompleteCases(keep=dx stock_id y ly x lmret l6mret lto lvol size lbm lmp); set hft2; run;
	data CompleteCases; set CompleteCases; if nmiss(of _NUMERIC_)=0; run; *output complete cases rows;
	proc sort data = CompleteCases; by dx; run;
	ods select none;
	proc univariate data=CompleteCases;
		var &classvar;
	    by dx;
	    output out=CLASSVAR_TERCILES pctlpts = 33.33, 66.67 pctlpre = P_;
	run;
	ods select all;
	proc sql;
		create table hft2_ as
		select a.*, b.*
		from CompleteCases a left join CLASSVAR_TERCILES b
		on a.dx = b.dx;
	quit;
	data hft2__; set hft2_;
		if &classvar < P_33_33 then do CLASSVAR_GRP = "small "; end;
		if P_33_33 <= &classvar < P_66_67 then do CLASSVAR_GRP = "medium"; end;
		if &classvar >= P_66_67 then do CLASSVAR_GRP = "big "; end;
		if missing(P_33_33) or missing(P_66_67) then do CLASSVAR_GRP = ""; end;
		drop P_33_33 P_66_67;
	run;
	
	/* Regressions per subgroups */
	/* Fama McBeth 1st stage */
	proc sort data = hft2__; by dx CLASSVAR_GRP; run;
	proc reg data = hft2__ outest = pe adjrsq noprint; 
	by dx CLASSVAR_GRP;
	model y = ly x lmret l6mret lto lvol size lbm;
	quit;
	
	data pe1; set pe; drop _MODEL_ _TYPE_ _DEPVAR_ y _RMSE_; run;
	proc transpose data = pe1 out = pe2; 
	by dx CLASSVAR_GRP;
	var Intercept ly x lmret l6mret lto lvol size lbm _ADJRSQ_;
	run;
	
	/* Fama McBeth 2nd stage */
	proc sort data = pe2; by _NAME_ CLASSVAR_GRP; run;
	ods select none;
	ods output parameterestimates = nw;
	ods listing close;
	proc model data=pe2; 
	by _NAME_ CLASSVAR_GRP;
	instrument/intonly;
	col1=a;
	fit col1/gmm kernel=(bart,5,0) vardef=n; 
	run;
	quit;
	ods select all;
	
	data nw; set nw;
	/* only the order of the reported coeff in table 4 matters */
	if _NAME_ = 'x' and CLASSVAR_GRP = 'small' then order = 1.1;
	if _NAME_ = 'x' and CLASSVAR_GRP = 'medium' then order = 1.2;
	if _NAME_ = 'x' and CLASSVAR_GRP = 'big' then order = 1.3;
	/* other coeff */
	if _NAME_ = "ly" then order = 3.2;
	if _NAME_ = "lmret" then order = 4.1;
	if _NAME_ = "l6mret" then order = 5;
	if _NAME_ = "lto" then order = 6;
	if _NAME_ = "lvol" then order = 7;
	if _NAME_ = "size" then order = 8;
	if _NAME_ = "lbm" then order = 9;
	if _NAME_ = "_ADJRSQ_" then order = 10;
	if _NAME_ = "Intercept" then order = 11;
	keep _NAME_ CLASSVAR_GRP order Estimate tValue;
	run;
	proc sort data = nw; by order;
	run;
	
	/* INTERQUARTILE RANGE */
	proc sort data = hft2__; by CLASSVAR_GRP; run;
	PROC MEANS data=hft2__ noprint ;
		Var x;
		by CLASSVAR_GRP;
		output out=IQR n=N QRANGE=IQR / autoname;
	RUN;
	data IQR; set IQR;
	if CLASSVAR_GRP = 'small' then order = 1;
	if CLASSVAR_GRP = 'medium' then order = 2;
	if CLASSVAR_GRP = 'big' then order = 3;
	keep CLASSVAR_GRP IQR order;
	run;
	proc sort data = IQR; by order;
%mend;