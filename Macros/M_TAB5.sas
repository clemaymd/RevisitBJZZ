%macro M_TAB5(x,y,dsin,k);

	%let klag = %eval(5*(&k-1));
	
	data prelim; set &dsin; by STOCK_ID dx;
	ldx&k. = lag&klag.(ldx);
	lSTOCK_ID&k. = lag&klag.(lSTOCK_ID);
	run;
	
	data hft2; set prelim; by STOCK_ID dx;
	y = f&y;
	l&x&k. = lag&klag.(l&x);
	ly&k. = lag&klag.(l&y);
	lvol = lvol&y;
	if lSTOCK_ID&k NE lSTOCK_ID or ldx&k NE dx - 4 - &klag then do; l&x&k. = .; ly&k.=.; end;
	run;
	
	/* Fama McBeth 1st stage */
	proc sort data = hft2; by dx;

	/* ------ To circumvent the "no valid obs" errors in the log, include the following. ------------- */
	/* ------ Alternatively, put in comments. This choice does *not* affect results. ----------------- */
	data cc(keep=dx stock_id y ly&k l&x&k lmret l6mret lto lvol size lbm); set hft2; run;
	data cc; set cc; if nmiss(of _NUMERIC_)=0; run; *ds with complete cases;
	proc sql noprint; select MIN(dx) into:firstdx from cc;
	proc sql noprint; select MAX(dx) into:lastdx from cc; *max min first date, min max last date;
	data hft2; set hft2; if &firstdx <= dx <= &lastdx ; 
	proc delete data=cc; run;
	/* ------------------------------------------------------------------------------------------------ */

	proc reg data = hft2 outest = pe adjrsq noprint; 
	by dx;
	model f&y = ly&k l&x&k lmret l6mret lto lvol size lbm;
	quit;
	
	data pe1; set pe; drop _MODEL_ _TYPE_ _DEPVAR_ f&y _RMSE_; run;
	proc transpose data = pe1 out = pe2; 
	by dx;
	var Intercept ly&k l&x&k lmret l6mret lto lvol size lbm _ADJRSQ_;
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
	fit col1/gmm kernel=(bart,5,0) vardef=n; 
	run;
	quit;
	ods select all;

	data nw; set nw;
	if _NAME_ = "Intercept" then order = 1;
	if find(_NAME_,'loib') then order = 2; 
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
%mend;
