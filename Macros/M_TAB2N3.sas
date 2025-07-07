%macro M_TAB2N3(x,y,dsin);

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
	proc sort data = hft2; by dx;
	
	/* ------ To circumvent the "no valid obs" errors in the log, include the following. ------------- */
	/* ------ Alternatively, put in comments. This choice does *not* affect results. ----------------- */
	data CompleteCases(keep=dx stock_id y ly x lmret l6mret lto lvol size lbm); set hft2; run;
	data CompleteCases; set CompleteCases; if nmiss(of _NUMERIC_)=0; run; *output complete cases rows;
	proc sql noprint; select MIN(dx) into:firstdx from CompleteCases;
	proc sql noprint; select MAX(dx) into:lastdx from CompleteCases;
	data hft2; set hft2; if &firstdx <= dx <= &lastdx ; 
	proc delete data=CompleteCases; run;
	/* ------------------------------------------------------------------------------------------------ */
	
	proc reg data = hft2 outest = pe adjrsq noprint; 
	by dx;
	model f&y = l&y l&x lmret l6mret lto lvol size lbm;
	quit;
	
	data pe1; set pe; drop _MODEL_ _TYPE_ _DEPVAR_ f&y _RMSE_; run;
	proc transpose data = pe1 out = pe2; 
	by dx;
	var Intercept l&y l&x lmret l6mret lto lvol size lbm _ADJRSQ_;
	run;
	
	/* Fama McBeth 2nd stage */
	proc sort data = pe2; by _NAME_; run;
	ods select none;
	ods output parameterestimates = nw;
	ods listing close;
	proc model data=pe2; 
	by _NAME_;
	instrument/intonly;
	col1=a;
	fit col1/gmm kernel=(bart,&nlags,0) vardef=n; 
	run;
	quit;
	ods select all;

	/* organize output */
	data nw; set nw;
	if _NAME_ = "Intercept" then order = 1;
	if _NAME_ = "loibvol" then order = 2.1;
	if _NAME_ = "loibtrd" then order = 2.2;
	if _NAME_ = "lnewret" then order = 3.1;
	if _NAME_ = "lret" then order = 3.2;
	if _NAME_ = "lmret" then order = 4;
	if _NAME_ = "l6mret" then order = 5;
	if _NAME_ = "lto" then order = 6;
	if _NAME_ = "lvol" then order = 7;
	if _NAME_ = "size" then order = 8;
	if _NAME_ = "lbm" then order = 9;
	if _NAME_ = "_ADJRSQ_" then order = 10;
	keep _NAME_ order Estimate tValue;
	run;
	proc sort data = nw; by order;
	run;
	
	/* IQR for Table 3 */
	%if &y = newret or &y = ret %then %do; 
		PROC MEANS data=HFT2 noprint ;
			Var loibvol;
			output out=IQ_MROIBVOL MEDIAN=Median Q1=Q1 Q3=Q3 QRANGE=IQR / autoname;
		RUN;
		PROC MEANS data=HFT2 noprint;
			Var loibtrd;
			output out=IQ_MROIBTRD MEDIAN=Median Q1=Q1 Q3=Q3 QRANGE=IQR / autoname;
		RUN;
	%end;
%mend;
