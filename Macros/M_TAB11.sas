%macro M_TAB11(x,y,dsin);

/* 	%let x=oibvol; */
/* 	%let y=newret; */
/* 	%let dsin=DS4REG; */

	/* lvol for tables 2 and 3 */
	%if &x = newret or &x = ret %then %do; %let lvolvar = lvol&x; %end; *table 2;
	%if &y = newret or &y = ret %then %do; %let lvolvar = lvol&y; %end; *table 3;
	
	/* as per BJZZ, NW nb of lag is 6 for tab 2 and 5 for tab 3 */
	%if &x = newret or &x = ret %then %do; %let nlags = 6; %end; *table 2;
	%if &y = newret or &y = ret %then %do; %let nlags = 5; %end; *table 3;
	
	data hft2; set &dsin;
		x = l&x;
		y = f&y;
		ly = l&y;
		lvol = &lvolvar;
	run;
	
	/* Fama McBeth 1st stage */
	proc sort data = hft2; by dx spreadgrp;
	
	/* ------ To circumvent the "no valid obs" errors in the log, include the following. ------------- */
	/* ------ Alternatively, put in comments. This choice does *not* affect results. ----------------- */
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
	/* ------------------------------------------------------------------------------------------------ */
	
	proc reg data = hft2 outest = pe adjrsq noprint; 
	by dx spreadgrp;
	model y = l&y l&x lmret l6mret lto lvol size lbm;
	quit;

	data pe1; set pe; drop _MODEL_ _TYPE_ _DEPVAR_ f&y _RMSE_; run;
	proc transpose data = pe1 out = pe2; 
	by dx spreadgrp;
	var Intercept l&y l&x lmret l6mret lto lvol size lbm _ADJRSQ_;
	run;
	
	/* Fama McBeth 2nd stage */
	proc sort data = pe2; by _NAME_ spreadgrp; run;
	ods select none;
	ods output parameterestimates = nw;
	ods listing close;
	proc model data=pe2; 
	by _NAME_ spreadgrp;
	instrument/intonly;
	col1=a;
	fit col1/gmm kernel=(bart,&nlags,0) vardef=n; 
	run;
	quit;
	ods select all;

	/* organize output */
	/* number of obs used in regression */
	proc sql;
		create table n_obs as
		select spreadgrp, sum(_EDF_) as Estimate, "N" as _NAME_
		from pe1
		group by spreadgrp;
	quit;
	data nw; set nw n_obs; run;
	%local i gname_i;
	%do i=1 %to %sysfunc(countw(&gnames));
		%let gname_i = %scan(&gnames, &i);
	    data nw; set nw;
		if _NAME_ = "Intercept" and spreadgrp="&gname_i" then order = 1;
		if _NAME_ = "loibvol" and spreadgrp="&gname_i" then order = 2.1;
		if _NAME_ = "loibtrd" and spreadgrp="&gname_i" then order = 2.2;
		if _NAME_ = "lnewret" and spreadgrp="&gname_i" then order = 3.1;
		if _NAME_ = "lret" and spreadgrp="&gname_i" then order = 3.2;
		if _NAME_ = "lmret" and spreadgrp="&gname_i" then order = 4;
		if _NAME_ = "l6mret" and spreadgrp="&gname_i" then order = 5;
		if _NAME_ = "lto" and spreadgrp="&gname_i" then order = 6;
		if _NAME_ = "lvol" and spreadgrp="&gname_i" then order = 7;
		if _NAME_ = "size" and spreadgrp="&gname_i" then order = 8;
		if _NAME_ = "lbm" and spreadgrp="&gname_i" then order = 9;
		if _NAME_ = "_ADJRSQ_" and spreadgrp="&gname_i" then order = 10;
		if _NAME_ = "N" and spreadgrp="&gname_i" then order = 10.5;	
		keep _NAME_ spreadgrp order Estimate tValue;
		run;
		%if &i ne 1 %then %do; data nw; set nw; if spreadgrp="&gname_i" then order = order + -10+10*&i; run; %end;
	%end;
	proc sort data = nw; by order; run;
	
	/* INTERQUARTILE RANGE */
	proc sort data = HFT2; by spreadgrp;
	%if &y = newret or &y = ret %then %do; 
		PROC MEANS data=HFT2 noprint ;
			Var loibvol;
			by spreadgrp;
			output out=IQ_MROIBVOL MEDIAN=Median Q1=Q1 Q3=Q3 QRANGE=IQR / autoname;
		RUN;
		PROC MEANS data=HFT2 noprint;
			Var loibtrd;
			by spreadgrp;
			output out=IQ_MROIBTRD MEDIAN=Median Q1=Q1 Q3=Q3 QRANGE=IQR / autoname;
		RUN;
	%end;

	%local i gname_i;
	%do i=1 %to %sysfunc(countw(&gnames));
		%let gname_i = %scan(&gnames, &i);
	    data IQ_MROIBVOL; set IQ_MROIBVOL;
			if spreadgrp="&gname_i" then order = &i;
			keep spreadgrp IQR order;
		run;
		data IQ_MROIBTRD; set IQ_MROIBTRD;
			if spreadgrp="&gname_i" then order = &i;
			keep spreadgrp IQR order;
		run;
	%end;
	proc sort data = IQ_MROIBVOL; by order;
	proc sort data = IQ_MROIBTRD; by order;
	
%mend;