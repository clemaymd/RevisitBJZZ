%macro M_TAB7(x,y,dsin);

	data hft2; set &dsin;
	x = l&x;
	y = f&y;
	ly = l&y;
	lvol = lvol&x;
	run;

	/* First Stage (PANEL A) */
	proc sort data = hft2; by dx;
	
	/* ------ To circumvent the "no valid obs" errors in the log, include the following. ------------- */
	/* ------ Alternatively, put in comments. This choice does *not* affect results. ----------------- */
	data cc(keep=dx stock_id y l&y l&x lmret l6mret); set hft2; run;
	data cc; set cc; if nmiss(of _NUMERIC_)=0; run; *ds with complete cases;
	proc sql noprint; select MIN(dx) into:firstdx from cc;
	proc sql noprint; select MAX(dx) into:lastdx from cc; *max min first date, min max last date;
	data hft2; set hft2; if &firstdx <= dx <= &lastdx ; 
	proc delete data=cc; run;
	/* ------------------------------------------------------------------------------------------------ */

	proc reg data = hft2 outest = pe adjrsq noprint ; 
	by dx;
	model f&y = l&y l&x lmret l6mret;
	quit;
	
	data pe1; set pe; 
	drop _MODEL_ _TYPE_ _DEPVAR_ f&y _RMSE_;
	run;
	proc transpose data = pe1 out = pe2; 
	by dx;
	var Intercept l&y l&x lmret l6mret _ADJRSQ_;
	run;
	
	/* Average accross time */
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
	
	/* organize output */
	data PANELA; set nw;
	if _NAME_ = "Intercept" then order = 1;
	if _NAME_ = "loibvol" then order = 2.1;
	if _NAME_ = "loibtrd" then order = 2.2;
	if _NAME_ = "lnewret" then order = 3.1;
	if _NAME_ = "lret" then order = 3.2;
	if _NAME_ = "lmret" then order = 4;
	if _NAME_ = "l6mret" then order = 5;
	if _NAME_ = "_ADJRSQ_" then order = 10;
	keep _NAME_ order Estimate tValue;
	run;
	proc sort data = PANELA; by order;
	run;
	
	/* Second Stage */	
	/* construct time series of "persistence", "contrarian" and "others" */
	data pe_renamed; set pe1;
	rename l&y=EST_l&y l&x=EST_l&x lmret=EST_lmret l6mret=EST_l6mret;
	run;
	
	proc sql;
	create table tmp as 
	select a.*, b.*
	from hft2 a left join pe_renamed b
	on a.dx=b.dx
	order by dx;
	quit;
	
	data hft3; set tmp;
	fPERS = l&y * EST_l&y;
	fCONT = l&x * EST_l&x;
	fRESID = f&y - Intercept - fPERS - fCONT;
	fOTHER = Intercept + fRESID;
	fCHECKSUM = fPERS + fCONT + fOTHER; * should = to f&y;
	keep dx STOCK_ID f&y fPERS fCONT fRESID fOTHER fCHECKSUM
		l&y l&x lmret l6mret lto lvol size lbm f&x ldx lSTOCK_ID;
	run;
	
	proc sort data=hft3; by STOCK_ID dx; run;
	
	data hft4; set hft3;	
	lPERS = lag5(fPERS);
	lCONT = lag5(fCONT);
	lRESID = lag5(fRESID);
	lOTHER = lag5(fOTHER);
	lCHECKSUM = lPERS + lCONT + lOTHER; *should = to l&y;
	if lSTOCK_ID NE STOCK_ID or ldx NE dx - 4 then do; lPERS = .; lCONT = .;lRESID = .;lOTHER = .; end;
	run;

	/* Fama McBeth regressions */
	proc sort data = hft4; by dx;
	proc reg data = hft4 outest = pe adjrsq noprint ; 
	by dx;
	model f&x = lPERS lCONT lOTHER l&x lmret l6mret lto lvol size lbm;
	quit;
	
	data pe1; set pe; drop _MODEL_ _TYPE_ _DEPVAR_ f&y _RMSE_; run;
	proc transpose data = pe1 out = pe2; 
	by dx;
	var Intercept lPERS lCONT lOTHER l&x lmret l6mret lto lvol size lbm _ADJRSQ_;
	run;
	
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
	
	/* organize output */
	data PANELB_; set nw;
	if _NAME_ = "Intercept" then order = 1;
	if _NAME_ = "lPERS" then order = 2.1;
	if _NAME_ = "lCONT" then order = 2.2;
	if _NAME_ = "lOTHER" then order = 2.3;
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
	proc sort data = PANELB_; by order; run;
	
	/* INTERQUARTILE RANGES */
	PROC MEANS data=HFT4 noprint;
	Var lPERS;
	output out=IQ_PERS n=N mean=Mean std=Std MEDIAN=Median Q1=Q1 Q3=Q3 QRANGE=IQR / autoname;
	RUN;
	proc sql; 
	create table IQ_PERS as 
	select  "PERS_IQR " as _NAME_, IQR as Estimate, . as tValue, . as order 
	from IQ_PERS;
	quit;

	PROC MEANS data=HFT4 noprint;
	Var lCONT;
	output out=IQ_CONT n=N mean=Mean std=Std MEDIAN=Median Q1=Q1 Q3=Q3 QRANGE=IQR / autoname;
	RUN;
	proc sql; 
	create table IQ_CONT as 
	select "CONT_IQR " as _NAME_, IQR as Estimate, . as tValue, . as order 
	from IQ_CONT;
	quit;
	
	PROC MEANS data=HFT4 noprint;
	Var lOTHER;
	output out=IQ_OTHER n=N mean=Mean std=Std MEDIAN=Median Q1=Q1 Q3=Q3 QRANGE=IQR / autoname;
	RUN;
	proc sql; 
	create table IQ_OTHER as 
	select "OTHER_IQR" as _NAME_, IQR as Estimate, . as tValue, . as order 
	from IQ_OTHER;
	quit;

	/* Panel B with IQRs */
	data PANELB; set PANELB_ IQ_PERS IQ_CONT IQ_OTHER; run;
%mend;
