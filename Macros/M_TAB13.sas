%macro FORM_LS_PTF_SPREAD(y, bysize, dsin);
/* 	%let y=oibvol; */
/* 	%let bysize="no"; */
/* 	%let dsin=DS4REG; */

	%let y = l&y;
	
	%if &bysize="yes" %then %do; 
		%let classvar = size; 
		
		/* 1. Create MKTCAP subgroups */
		/* Create subgroups based on the complete case DS to ensure having 1/3 of stocks in each tercile */
		data cc0(keep=dx stock_id &y fnewret size spreadgrp); set &dsin; run;
		proc sql noprint; select DISTINCT spreadgrp into:gnames separated by ' ' from cc0;
		data hft2; set cc0; run;
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
		
		/* 2. Create spread and mktcap-based L-S portfolios based on past-week oib */
		proc sort data=hft2__; by dx CLASSVAR_GRP spreadgrp; run;
		proc univariate data=hft2__ noprint;
			var &y; by dx CLASSVAR_GRP spreadgrp;
		    output out=QUINTILES
			pctlpts = 5 to 95 by 5
			pctlpre = P_;
		run;
		proc sql;
			create table hft2___ as
			select a.*, b.*
			from hft2__ a left join QUINTILES b
			on a.dx = b.dx and a.CLASSVAR_GRP = b.CLASSVAR_GRP and a.spreadgrp=b.spreadgrp;
		quit;
		data hft2____; set hft2___;
			if &y <= P_20 then do POSITION = "short"; end;
			if &y >= P_80 then do POSITION = "long "; end;
			if missing(P_20) or missing(P_80) or missing(&y) then do POSITION = ""; end;
			keep dx STOCK_ID fnewret &y P_20 P_80 CLASSVAR_GRP spreadgrp POSITION size;
		run;
	
		/* Value-weight by last end-of-month mkt cap */
		proc sql;
			create table LSPTF(drop=size P_20 P_80 &y) as
			select *, exp(size)/sum(exp(size)) as w
			from hft2____
			group by dx, classvar_grp, spreadgrp, POSITION;
		quit;
	%end; 
	%else %do;
		/* Create L-S portfolios based on past-week oib */
		data hft2(keep=dx stock_id &y fnewret size spreadgrp); set &dsin; run;
		
		proc sort data=hft2; by dx spreadgrp; run;
		proc univariate data=hft2 noprint;
			var &y; by dx spreadgrp;
		    output out=QUINTILES
			pctlpts = 5 to 95 by 5
			pctlpre = P_;
		run;
		proc sql;
			create table hft2_ as
			select a.*, b.*
			from hft2 a left join QUINTILES b
			on a.dx = b.dx and a.spreadgrp=b.spreadgrp;
		quit;
		data hft2__; set hft2_;
			if &y <= P_20 then do POSITION = "short"; end;
			if &y >= P_80 then do POSITION = "long "; end;
			if missing(P_20) or missing(P_80) or missing(&y) then do POSITION = ""; end;
			keep dx STOCK_ID fnewret &y P_20 P_80 spreadgrp POSITION size ;
		run;
	
		/* Value-weight by last end-of-month mkt cap */
		proc sql;
			create table LSPTF(drop=size P_20 P_80 &y) as
			select *, exp(size)/sum(exp(size)) as w
			from hft2__
			group by dx, spreadgrp, POSITION;
		quit;
	%end;
	
	/* merge with FF 3 factors */
	proc sql;
		create table LSPTF_FF as
		select a.*, b.fMKTmRF, b.fSMB, b.fHML, b.fRF
		from LSPTF a left join mydata.FF b
		on a.dx = b.dx;
	quit;
	
	data LSPTF_FF; set LSPTF_FF; 
		fMKTmRF = fMKTmRF/100; fSMB = fSMB/100; fHML = fHML/100; fRF = fRF/100;
	run;
	
	/* all k-week ahead returns (not cumulative) */
	proc sort data=LSPTF_FF; by STOCK_ID descending dx; run;
	
	data LSPTF_withidx; set LSPTF_FF;
	fdx5 = lag5(dx); fSTOCK_ID5 = lag5(STOCK_ID);
	fdx10 = lag10(dx); fSTOCK_ID10 = lag10(STOCK_ID);
	fdx15 = lag15(dx); fSTOCK_ID15 = lag15(STOCK_ID);
	fdx20 = lag20(dx); fSTOCK_ID20 = lag20(STOCK_ID);
	fdx25 = lag25(dx); fSTOCK_ID25 = lag25(STOCK_ID);
	fdx30 = lag30(dx); fSTOCK_ID30 = lag30(STOCK_ID);
	fdx35 = lag35(dx); fSTOCK_ID35 = lag35(STOCK_ID);
	fdx40 = lag40(dx); fSTOCK_ID40 = lag40(STOCK_ID);
	fdx45 = lag45(dx); fSTOCK_ID45 = lag45(STOCK_ID);
	fdx50 = lag50(dx); fSTOCK_ID50 = lag50(STOCK_ID);
	fdx55 = lag55(dx); fSTOCK_ID55 = lag55(STOCK_ID);
	run;
	
	data LSPTF2; 
	set LSPTF_withidx;
	fnewret2 =  lag5(fnewret); 	fMKTmRF2 =  lag5(fMKTmRF);  fSMB2 =  lag5(fSMB);  fHML2 =  lag5(fHML);  fRF2 =   lag5(fRF); 
	fnewret3 =  lag10(fnewret);	fMKTmRF3 =  lag10(fMKTmRF); fSMB3 =  lag10(fSMB); fHML3 =  lag10(fHML); fRF3 =   lag10(fRF); 
	fnewret4 =  lag15(fnewret);	fMKTmRF4 =  lag15(fMKTmRF); fSMB4 =  lag15(fSMB); fHML4 =  lag15(fHML); fRF4 =   lag15(fRF); 
	fnewret5 =  lag20(fnewret);	fMKTmRF5 =  lag20(fMKTmRF); fSMB5 =  lag20(fSMB); fHML5 =  lag20(fHML); fRF5 =   lag20(fRF); 
	fnewret6 =  lag25(fnewret);	fMKTmRF6 =  lag25(fMKTmRF); fSMB6 =  lag25(fSMB); fHML6 =  lag25(fHML); fRF6 =   lag25(fRF); 
	fnewret7 =  lag30(fnewret);	fMKTmRF7 =  lag30(fMKTmRF); fSMB7 =  lag30(fSMB); fHML7 =  lag30(fHML); fRF7 =   lag30(fRF); 
	fnewret8 =  lag35(fnewret);	fMKTmRF8 =  lag35(fMKTmRF); fSMB8 =  lag35(fSMB); fHML8 =  lag35(fHML); fRF8 =   lag35(fRF); 
	fnewret9 =  lag40(fnewret);	fMKTmRF9 =  lag40(fMKTmRF); fSMB9 =  lag40(fSMB); fHML9 =  lag40(fHML); fRF9 =   lag40(fRF); 
	fnewret10 = lag45(fnewret);	fMKTmRF10 = lag45(fMKTmRF); fSMB10 = lag45(fSMB); fHML10 = lag45(fHML); fRF10 =  lag45(fRF); 
	fnewret11 = lag50(fnewret);	fMKTmRF11 = lag50(fMKTmRF); fSMB11 = lag50(fSMB); fHML11 = lag50(fHML); fRF11 =  lag50(fRF); 
	fnewret12 = lag55(fnewret);	fMKTmRF12 = lag55(fMKTmRF); fSMB12 = lag55(fSMB); fHML12 = lag55(fHML); fRF12 =  lag55(fRF);
	
	if fSTOCK_ID5 NE STOCK_ID  or fdx5 NE dx + 5   then do; fnewret2=.;  fMKTmRF2=.;  fSMB2=.;  fHML2=.;  fRF2=.; end;
	if fSTOCK_ID10 NE STOCK_ID or fdx10 NE dx + 10 then do; fnewret3=.;  fMKTmRF3=.;  fSMB3=.;  fHML3=.;  fRF3=.; end;
	if fSTOCK_ID15 NE STOCK_ID or fdx15 NE dx + 15 then do; fnewret4=.;  fMKTmRF4=.;  fSMB4=.;  fHML4=.;  fRF4=.; end;
	if fSTOCK_ID20 NE STOCK_ID or fdx20 NE dx + 20 then do; fnewret5=.;  fMKTmRF5=.;  fSMB5=.;  fHML5=.;  fRF5=.; end;
	if fSTOCK_ID25 NE STOCK_ID or fdx25 NE dx + 25 then do; fnewret6=.;  fMKTmRF6=.;  fSMB6=.;  fHML6=.;  fRF6=.; end;
	if fSTOCK_ID30 NE STOCK_ID or fdx30 NE dx + 30 then do; fnewret7=.;  fMKTmRF7=.;  fSMB7=.;  fHML7=.;  fRF7=.; end;
	if fSTOCK_ID35 NE STOCK_ID or fdx35 NE dx + 35 then do; fnewret8=.;  fMKTmRF8=.;  fSMB8=.;  fHML8=.;  fRF8=.; end;
	if fSTOCK_ID40 NE STOCK_ID or fdx40 NE dx + 40 then do; fnewret9=.;  fMKTmRF9=.;  fSMB9=.;  fHML9=.;  fRF9=.; end;
	if fSTOCK_ID45 NE STOCK_ID or fdx45 NE dx + 45 then do; fnewret10=.; fMKTmRF10=.; fSMB10=.; fHML10=.; fRF10=.; end;
	if fSTOCK_ID50 NE STOCK_ID or fdx50 NE dx + 50 then do; fnewret11=.; fMKTmRF11=.; fSMB11=.; fHML11=.; fRF11=.; end;
	if fSTOCK_ID55 NE STOCK_ID or fdx55 NE dx + 55 then do; fnewret12=.; fMKTmRF12=.; fSMB12=.; fHML12=.; fRF12=.; end;
	run;
	proc sort data=LSPTF2; by STOCK_ID dx; run;

%mend;

/* ***************************************************************************************************************** */
/* ***************************************************************************************************************** */

%macro COMPUTE_PTF_RET_SPREAD(k);
/* 	%let k=2; */
	/* k-week ahead cumulative returns for each return variable (y + all FF variables) */
	/* 1. Preparation: create macro variable list */
	proc contents data=LSPTF_FF out=colnam noprint; run;
	data colnam2(keep=NAME); set colnam; where NAME in ("fnewret", "fMKTmRF", "fSMB", "fHML", "fRF"); run;
	data _NULL_;
		set colnam2 end=last;
		call symputx(cats('VarList', _n_), NAME, 'G');
		if last then call symputx('nb_var', _n_, 'G');
	run;
	
	/* 	2. Compute returns for each variable */
	data LSPTF3; set LSPTF2; run;
	%do j=1 %to &nb_var;
		%let var = &&VarList&j;
		
		%if &k=1 %then %do;
		data LSPTF3; set LSPTF3; 
			%sysfunc(cats(&var,_k)) = &var;
		run;
		%end;
		%if &k=2 %then %do;
		data LSPTF3; set LSPTF3; 
			%sysfunc(cats(&var,_k)) = ((1+&var)*(1+&var&k)) -1 ;
		run;
		%end;
		%if &k=4 %then %do;
		data LSPTF3; set LSPTF3; 
			%sysfunc(cats(&var,_k)) = ((1+&var)*(1+&var.2)*(1+&var.3)*(1+&var&k)) -1 ;
		run;
		%end;
		%if &k=6 %then %do;
		data LSPTF3; set LSPTF3; 
			%sysfunc(cats(&var,_k)) = ((1+&var)*(1+&var.2)*(1+&var.3)*(1+&var.4)*(1+&var.5)*(1+&var&k)) -1 ;
		run;
		%end;
		%if &k=8 %then %do;
		data LSPTF3; set LSPTF3; 
			%sysfunc(cats(&var,_k)) = ((1+&var)*(1+&var.2)*(1+&var.3)*(1+&var.4)*(1+&var.5)*(1+&var.6)*(1+&var.7)*(1+&var&k)) -1 ;
		run;
		%end;
		%if &k=10 %then %do;
		data LSPTF3; set LSPTF3; 
			%sysfunc(cats(&var,_k)) = ((1+&var)*(1+&var.2)*(1+&var.3)*(1+&var.4)*(1+&var.5)*(1+&var.6)*(1+&var.7)*(1+&var.8)*(1+&var.9)*(1+&var&k)) -1 ;
		run;
		%end;
		%if &k=12 %then %do;
		data LSPTF3; set LSPTF3; 
			%sysfunc(cats(&var,_k)) = ((1+&var)*(1+&var.2)*(1+&var.3)*(1+&var.4)*(1+&var.5)*(1+&var.6)*(1+&var.7)*(1+&var.8)*(1+&var.9)*(1+&var.10)*(1+&var.11)*(1+&var&k)) -1 ;
		run;
		%end;
		
		data LSPTF3; set LSPTF3; drop &var &var.2 &var.3 &var.4 &var.5 &var.6 &var.7 &var.8 &var.9 &var.10 &var.11 &var.12; run;
		
	%end;
	
	/* stock weighted return on the k-week period	 */
	data LSPTF4; set LSPTF3;
		if POSITION = 'short' then w = w*(-1);
		weightedret = w * fnewret_k;
		if not missing(w) and (POSITION = 'short' or POSITION = 'long');
	run;
	
	/* ptf return on the k-week period	 */
	%if &bysize="yes" %then %do;
		proc sql;
			create table LSPTF5 as
			select *, sum(weightedret) as ptfret_kweek, monotonic() as n
			from LSPTF4
			group by dx, classvar_grp, spreadgrp
			having max(n) = n;
		quit;
	%end;
	%else %do;
		proc sql;
			create table LSPTF5 as
			select *, sum(weightedret) as ptfret_kweek, monotonic() as n
			from LSPTF4
			group by dx, spreadgrp
			having max(n) = n;
		quit;
	%end;

	/* ptf return in excess of the RFR on the k-week period	 */
	data LSPTF6; set LSPTF5; ptfret_kweek_excess = ptfret_kweek - fRF_k; run;

	/* Results: mean (raw) returns and FF alpha returns */
	%let nlags = %eval(&k*5); *nb of lags to use for SE;
	
	%if &bysize="yes" %then %do;
		proc sort data=LSPTF6; by classvar_grp spreadgrp; run;
		/* mean (raw returns) */
		ods select none;
		ods output parameterestimates = res_mean;
		proc autoreg data=LSPTF6 ;
		   by classvar_grp spreadgrp;
		   model ptfret_kweek = / covest=hac(kernel=truncated, bandwidth=&nlags);
		run;
		ods select all;
		data res_mean; set res_mean; Model = 'RawReturn'; run;
		
		/* alpha (FF adjusted returns) */
		ods select none;
		ods output parameterestimates = res_alpha;
		proc autoreg data=LSPTF6 ;
		   by classvar_grp spreadgrp;
		   model ptfret_kweek_excess = fMKTmRF_k fSMB_k fHML_k / covest=hac(kernel=truncated, bandwidth=&nlags);
		run;
		ods select all;
		data res_alpha; set res_alpha; Model = 'FFAlpha  '; run;
				
		data res; set res_mean res_alpha; run;
	%end;
	%else %do;
		proc sort data=LSPTF6; by spreadgrp; run;
		/* mean (raw returns) */
		ods select none;
		ods output parameterestimates = res_mean;
		proc autoreg data=LSPTF6 ;
		   by spreadgrp;
		   model ptfret_kweek = / covest=hac(kernel=truncated, bandwidth=&nlags);
		run;
		ods select all;
		data res_mean; set res_mean; Model = 'RawReturn'; run;
		
		/* alpha (FF adjusted returns) */
		ods select none;
		ods output parameterestimates = res_alpha;
		proc autoreg data=LSPTF6 ;
		   by spreadgrp;
		   model ptfret_kweek_excess = fMKTmRF_k fSMB_k fHML_k / covest=hac(kernel=truncated, bandwidth=&nlags);
		run;
		ods select all;
		data res_alpha; set res_alpha; Model = 'FFAlpha  '; run;
			
		data res; set res_mean res_alpha; run;
	%end;
%mend;

