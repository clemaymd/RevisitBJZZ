/* *************************************************************************************************************
	Revisiting Boehmer et al (2021): Recent Period, Alternative method, Different Conclusions.
	David Ardia, Clement Aymard, Tolga Cenesizoglu;
   ********************************************************************************************************** */ 

/* I. Users options: uncomment lines 7-21 to use this file independently  */
/* 	*1. Replace with your paths; */
/* libname mydata "/home/hecca/clementaymd/RevisitBJZZ/Data"; * data for the replicator; */
/* libname mytrdata "/scratch/hecca/clemaymd"; 			   * true data (n/a for the replicator); */
/* filename mymacros "/home/hecca/clementaymd/RevisitBJZZ/Macros";  */
/* %let myout = /home/hecca/clementaymd/RevisitBJZZ/Outputs;   * output for the replicator; */
/* %let mytrout = /home/hecca/clementaymd/RevisitBJZZ/Outputs_paper; * output true data (n/a for the replicator); */
/*  */
/* 	*2. Define panel; */
/* %let RTMTD=QMP ; *BJZZ or QMP;  */
/* %let period=1621 ; *1015 for 2010-15 or 1621 for 2016-21; */
/* %let spreadgrptyp=median; *median or average; */
/* %let ngrp=3; *number of spread group formed (only ngrp=2 available for the replicator); */
/*  */
/* 	*3. Define sample type (only pseudo-sample available for the replicator); */
/* %let SAMPLETYPE=TRUE; *PSEUDO or TRUE; */

/* II. Obtain the panel-specific dataset */ 
%macro PANELDS();
	%if &SAMPLETYPE = PSEUDO %then %do; data DS; set mydata.pseudods_4spread; run; %global myoutput; %let myoutput=&myout; %end;
	%if &SAMPLETYPE = TRUE %then %do;
		%if &ngrp = 2 %then %do; data DS; set mytrdata.trueds_4spread; run; %end;
		%if &ngrp = 3 %then %do; data DS; set mytrdata.trueds_4spread_rev; run; %end;
		%global myoutput; %let myoutput=&mytrout;
	%end;
	%if &RTMTD = BJZZ %then %do; 
		data DS; set DS; 
			drop Mrbvol Mrsvol Mrbtrd Mrstrd Mroibvol Mroibtrd;
			rename mrbvol_BJZZ=Mrbvol mrsvol_BJZZ=Mrsvol mrbtrd_BJZZ=Mrbtrd mrstrd_BJZZ=Mrstrd 
			mroibvol_BJZZ=Mroibvol mroibtrd_BJZZ=Mroibtrd;
		run; 
	%end;
	%if &RTMTD = QMP %then %do; 
		data DS; set DS; 
			drop mrbvol_BJZZ mrsvol_BJZZ mrbtrd_BJZZ mrstrd_BJZZ mroibvol_BJZZ mroibtrd_BJZZ; 
		run;
	%end;
	%if &spreadgrptyp = median %then %do; data DS; set DS; rename spreadgrp_med=spreadgrp medspread=spread; run; %end; 
	%if &spreadgrptyp = average %then %do; data DS; set DS; rename spreadgrp_avg=spreadgrp avgspread=spread; run; %end; 
	%if &period = 1015 %then %do; data DS; set DS; if DATE <= '31DEC2015'd; run; %end;
	%if &period = 1621 %then %do; data DS; set DS; if DATE >  '31DEC2015'd; run; %end;
%mend;
%PANELDS;

%include mymacros(M_DS4REG.sas);
%M_DS4REG(DSIN = DS);

/* III. Run all or part of code below */ 
%include mymacros(M_TAB6.sas);
%include mymacros(M_TAB13.sas);

/* ALL SPREADS */
/* OIBVOL & ALL SIZES  */
%let bysize = "no";
%FORM_LS_PTF(y=oibvol, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET(k=1);
data res1; _OIB_="oibvol"; _k_=1; set res; run;

%COMPUTE_PTF_RET(k=2);
data res2; _OIB_="oibvol"; _k_=2; set res; run;

%COMPUTE_PTF_RET(k=4);
data res3; _OIB_="oibvol"; _k_=4; set res; run;

%COMPUTE_PTF_RET(k=6);
data res4; _OIB_="oibvol"; _k_=6; set res; run;

%COMPUTE_PTF_RET(k=8);
data res5; _OIB_="oibvol"; _k_=8; set res; run;

%COMPUTE_PTF_RET(k=10);
data res6; _OIB_="oibvol"; _k_=10; set res; run;

%COMPUTE_PTF_RET(k=12);
data res7; _OIB_="oibvol"; _k_=12; set res; run;

data TAB6_1(keep=_OIB_ _k_ Model Estimate tValue); set res1-res7; if(Variable = 'Intercept'); run;
proc sort data=TAB6_1; by Model _k_ ; run;

/* OIBVOL & MKTCAP SUBGROUPS  */
%let bysize = "yes";
%FORM_LS_PTF(y=oibvol, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET(k=1);
data res1; _OIB_="oibvol"; _k_=1; set res; run;

%COMPUTE_PTF_RET(k=2);
data res2; _OIB_="oibvol"; _k_=2; set res; run;

%COMPUTE_PTF_RET(k=4);
data res3; _OIB_="oibvol"; _k_=4; set res; run;

%COMPUTE_PTF_RET(k=6);
data res4; _OIB_="oibvol"; _k_=6; set res; run;

%COMPUTE_PTF_RET(k=8);
data res5; _OIB_="oibvol"; _k_=8; set res; run;

%COMPUTE_PTF_RET(k=10);
data res6; _OIB_="oibvol"; _k_=10; set res; run;

%COMPUTE_PTF_RET(k=12);
data res7; _OIB_="oibvol"; _k_=12; set res; run;

data TAB6_2(keep=_OIB_ _k_ CLASSVAR_GRP Model Estimate tValue); set res1-res7; if(Variable = 'Intercept' and Model='FFAlpha'); run;
proc sort data=TAB6_2; by descending CLASSVAR_GRP _k_ ; run;

/* OIBTRD & ALL SIZES  */
%let bysize = "no";
%FORM_LS_PTF(y=oibtrd, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET(k=1);
data res1; _OIB_="oibtrd"; _k_=1; set res; run;

%COMPUTE_PTF_RET(k=2);
data res2; _OIB_="oibtrd"; _k_=2; set res; run;

%COMPUTE_PTF_RET(k=4);
data res3; _OIB_="oibtrd"; _k_=4; set res; run;

%COMPUTE_PTF_RET(k=6);
data res4; _OIB_="oibtrd"; _k_=6; set res; run;

%COMPUTE_PTF_RET(k=8);
data res5; _OIB_="oibtrd"; _k_=8; set res; run;

%COMPUTE_PTF_RET(k=10);
data res6; _OIB_="oibtrd"; _k_=10; set res; run;

%COMPUTE_PTF_RET(k=12);
data res7; _OIB_="oibtrd"; _k_=12; set res; run;

data TAB6_3(keep=_OIB_ _k_ Model Estimate tValue); set res1-res7; if(Variable = 'Intercept'); run;
proc sort data=TAB6_3; by Model _k_ ; run;

/* OIBTRD & MKTCAP SUBGROUPS  */
%let bysize = "yes";
%FORM_LS_PTF(y=oibtrd, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET(k=1);
data res1; _OIB_="oibtrd"; _k_=1; set res; run;

%COMPUTE_PTF_RET(k=2);
data res2; _OIB_="oibtrd"; _k_=2; set res; run;

%COMPUTE_PTF_RET(k=4);
data res3; _OIB_="oibtrd"; _k_=4; set res; run;

%COMPUTE_PTF_RET(k=6);
data res4; _OIB_="oibtrd"; _k_=6; set res; run;

%COMPUTE_PTF_RET(k=8);
data res5; _OIB_="oibtrd"; _k_=8; set res; run;

%COMPUTE_PTF_RET(k=10);
data res6; _OIB_="oibtrd"; _k_=10; set res; run;

%COMPUTE_PTF_RET(k=12);
data res7; _OIB_="oibtrd"; _k_=12; set res; run;

data TAB6_4(keep=_OIB_ _k_ CLASSVAR_GRP Model Estimate tValue); set res1-res7; if(Variable = 'Intercept' and Model='FFAlpha'); run;
proc sort data=TAB6_4; by descending CLASSVAR_GRP _k_ ; run;

/* DECOMPOSE BY SPREAD GROUPS */
/* OIBVOL & ALL SIZES  */
%let bysize = "no";
%FORM_LS_PTF_SPREAD(y=oibvol, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET_SPREAD(k=1);
data res1; _OIB_="oibvol"; _k_=1; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=2);
data res2; _OIB_="oibvol"; _k_=2; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=4);
data res3; _OIB_="oibvol"; _k_=4; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=6);
data res4; _OIB_="oibvol"; _k_=6; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=8);
data res5; _OIB_="oibvol"; _k_=8; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=10);
data res6; _OIB_="oibvol"; _k_=10; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=12);
data res7; _OIB_="oibvol"; _k_=12; set res; run;

data TAB13_1(keep=_OIB_ _k_ spreadgrp Model Estimate tValue); set res1-res7; if(Variable = 'Intercept'); run;
proc sort data=TAB13_1; by Model _k_ DESCENDING spreadgrp ; run;

/* OIBVOL & MKTCAP SUBGROUPS  */
%let bysize = "yes";
%FORM_LS_PTF_SPREAD(y=oibvol, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET_SPREAD(k=1);
data res1; _OIB_="oibvol"; _k_=1; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=2);
data res2; _OIB_="oibvol"; _k_=2; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=4);
data res3; _OIB_="oibvol"; _k_=4; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=6);
data res4; _OIB_="oibvol"; _k_=6; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=8);
data res5; _OIB_="oibvol"; _k_=8; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=10);
data res6; _OIB_="oibvol"; _k_=10; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=12);
data res7; _OIB_="oibvol"; _k_=12; set res; run;

data TAB13_2(keep=_OIB_ _k_ spreadgrp CLASSVAR_GRP Model Estimate tValue); set res1-res7; if(Variable = 'Intercept' and Model='FFAlpha'); run;
proc sort data=TAB13_2; by descending CLASSVAR_GRP DESCENDING spreadgrp _k_ ; run;

/* OIBTRD & FULL SAMPLE  */
%let bysize = "no";
%FORM_LS_PTF_SPREAD(y=oibtrd, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET_SPREAD(k=1);
data res1; _OIB_="oibtrd"; _k_=1; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=2);
data res2; _OIB_="oibtrd"; _k_=2; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=4);
data res3; _OIB_="oibtrd"; _k_=4; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=6);
data res4; _OIB_="oibtrd"; _k_=6; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=8);
data res5; _OIB_="oibtrd"; _k_=8; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=10);
data res6; _OIB_="oibtrd"; _k_=10; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=12);
data res7; _OIB_="oibtrd"; _k_=12; set res; run;

data TAB13_3(keep=_OIB_ _k_ spreadgrp Model Estimate tValue); set res1-res7; if(Variable = 'Intercept'); run;
proc sort data=TAB13_3; by Model _k_ DESCENDING spreadgrp ; run;

/* OIBTRD & MKTCAP SUBGROUPS  */
%let bysize = "yes";
%FORM_LS_PTF_SPREAD(y=oibtrd, bysize=&bysize, dsin=DS4REG);

%COMPUTE_PTF_RET_SPREAD(k=1);
data res1; _OIB_="oibtrd"; _k_=1; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=2);
data res2; _OIB_="oibtrd"; _k_=2; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=4);
data res3; _OIB_="oibtrd"; _k_=4; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=6);
data res4; _OIB_="oibtrd"; _k_=6; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=8);
data res5; _OIB_="oibtrd"; _k_=8; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=10);
data res6; _OIB_="oibtrd"; _k_=10; set res; run;

%COMPUTE_PTF_RET_SPREAD(k=12);
data res7; _OIB_="oibtrd"; _k_=12; set res; run;

data TAB13_4(keep=_OIB_ _k_ spreadgrp CLASSVAR_GRP Model Estimate tValue); set res1-res7; if(Variable = 'Intercept' and Model='FFAlpha'); run;
proc sort data=TAB13_4; by descending CLASSVAR_GRP DESCENDING spreadgrp _k_ ; run;

/* Construct final output and save to dedicated folder */
data TAB13; set TAB6_1 TAB6_2 TAB6_3 TAB6_4 TAB13_1 TAB13_2 TAB13_3 TAB13_4; 
	if spreadgrp=' ' then spreadgrp='NA';
	if classvar_grp=' ' then classvar_grp='NA';
run;
proc sort data=TAB13; by descending _OIB_ descending spreadgrp descending CLASSVAR_GRP _k_ ; run;

proc export data=TAB13
    outfile="&myoutput./TAB13_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;

