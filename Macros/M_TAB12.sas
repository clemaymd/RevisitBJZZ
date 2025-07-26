%macro M_TAB12(x,y,dsin,subgroup_var);
/* 	%let x=oibvol; */
/* 	%let y=newret; */
/* 	%let dsin=DS4REG; */
/* 	%let subgroup_var=mktcap; */
	
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
	data cc0(keep=dx stock_id y l&y l&x lmret l6mret lto lvol size lbm lmp spreadgrp); set hft2; run;
	proc sql noprint; select DISTINCT spreadgrp into:gnames separated by ' ' from cc0;
	%local i gname_i;
	%do i=1 %to %sysfunc(countw(&gnames));
		%let gname_i = %scan(&gnames, &i);
	    *ds with complete cases based on spread group i;
		data cc_i(drop=spreadgrp); set cc0; if spreadgrp="&gname_i"; if nmiss(of _NUMERIC_)=0; run; 
		proc sql noprint; select MIN(dx) into:firstdx_i from cc_i;
		proc sql noprint; select MAX(dx) into:lastdx_i from cc_i;
		data hft2; set hft2; if &firstdx_i <= dx <= &lastdx_i ; run; *max min first date, min max last date;
	%end;
	proc delete data=cc0 cc_i; run;	
	
	proc sort data = hft2; by dx; run;
	ods select none;
	proc univariate data=hft2;
		var &classvar;
	    by dx;
	    output out=CLASSVAR_TERCILES pctlpts = 33.33, 66.67 pctlpre = P_;
	run;
	ods select all;
	proc sql;
		create table hft2_ as
		select a.*, b.*
		from hft2 a left join CLASSVAR_TERCILES b
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
	proc sort data = hft2__; by dx spreadgrp CLASSVAR_GRP; run;
	proc reg data = hft2__ outest = pe adjrsq noprint; 
	by dx spreadgrp CLASSVAR_GRP;
	model y = ly x lmret l6mret lto lvol size lbm;
	quit;
	
	data pe1; set pe; drop _MODEL_ _TYPE_ _DEPVAR_ y _RMSE_; run;
	proc transpose data = pe1 out = pe2; 
	by dx spreadgrp CLASSVAR_GRP;
	var Intercept ly x lmret l6mret lto lvol size lbm _ADJRSQ_;
	run;
	
	/* Fama McBeth 2nd stage */
	proc sort data = pe2; by _NAME_ spreadgrp CLASSVAR_GRP; run;
	ods select none;
	ods output parameterestimates = nw;
	ods listing close;
	proc model data=pe2; 
	by _NAME_ spreadgrp CLASSVAR_GRP;
	instrument/intonly;
	col1=a;
	fit col1/gmm kernel=(bart,5,0) vardef=n; 
	run;
	quit;
	ods select all;
	
	/* organize output */
	/* number of obs used in regression */
	proc sql;
		create table n_obs as
		select classvar_grp, spreadgrp, sum(_EDF_) as NOBS
		from pe1
		group by spreadgrp, classvar_grp;
	quit;
	proc sql; create table nwwithobs as select a.*, b.NOBS from nw a left join n_obs b on a.classvar_grp=b.classvar_grp and a.spreadgrp = b.spreadgrp; quit;
	data nw; set nwwithobs; run;
	%local i gname_i;
	%do i=1 %to %sysfunc(countw(&gnames));
		%let gname_i = %scan(&gnames, &i);
		data nw; set nw;
			/* only the order of the reported coeff (x) and nobs matter for this tab */
		   	if _NAME_ = 'x' and spreadgrp="&gname_i" and CLASSVAR_GRP = 'small' then order = 1.1;
			if _NAME_ = 'x' and spreadgrp="&gname_i" and CLASSVAR_GRP = 'medium' then order = 1.2;
			if _NAME_ = 'x' and spreadgrp="&gname_i" and CLASSVAR_GRP = 'big' then order = 1.3;
			/* other coeff */
			if _NAME_ = "ly" then order = 2;
			if _NAME_ = "lmret" then order = 3;
			if _NAME_ = "l6mret" then order = 4;
			if _NAME_ = "lto" then order = 5;
			if _NAME_ = "lvol" then order = 6;
			if _NAME_ = "size" then order = 7;
			if _NAME_ = "lbm" then order = 8;
			if _NAME_ = "_ADJRSQ_" then order = 9;
			if _NAME_ = "Intercept" then order = 10;
			keep _NAME_ spreadgrp CLASSVAR_GRP order Estimate tValue NOBS;
		run;
		%if &i ne 1 %then %do; data nw; set nw; if spreadgrp="&gname_i" then order = order + -10+10*&i; run; %end;
	%end;
	proc sort data = nw; by order; run;

	/* INTERQUARTILE RANGE */
	proc sort data = hft2__; by spreadgrp CLASSVAR_GRP; run;
	PROC MEANS data=hft2__ noprint ;
		Var x;
		by spreadgrp CLASSVAR_GRP;
		output out=IQR n=N QRANGE=IQR / autoname;
	RUN;
	
	%local i gname_i;
	%do i=1 %to %sysfunc(countw(&gnames));
		%let gname_i = %scan(&gnames, &i);
	    data IQR; set IQR;
			if spreadgrp="&gname_i" and CLASSVAR_GRP = 'small' then order = 1;
			if spreadgrp="&gname_i" and CLASSVAR_GRP = 'medium' then order = 2;
			if spreadgrp="&gname_i" and CLASSVAR_GRP = 'big' then order = 3;
			keep spreadgrp CLASSVAR_GRP IQR order;
		run;
		%if &i ne 1 %then %do; data IQR; set IQR; if spreadgrp="&gname_i" then order = order + -10+10*&i; run; %end;
	%end;
	proc sort data = IQR; by order;
%mend;
