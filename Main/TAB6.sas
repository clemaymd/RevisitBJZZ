/* *************************************************************************************************************
	Revisiting Boehmer et al (2021): Recent Period, Alternative method, Different Conclusions.
	David Ardia, Clement Aymard, Tolga Cenesizoglu;
   ********************************************************************************************************** */ 

/* I. Users options: uncomment lines 7-17 to use this file independently  */
/* 	*1. Replace with your paths; */
/* libname mydata "/home/hecca/clementaymd/RevisitBJZZ/Data";  */
/* filename mymacros "/home/hecca/clementaymd/RevisitBJZZ/Macros";  */
/* %let myoutputs = /home/hecca/clementaymd/RevisitBJZZ/Outputs; */
/*  */
/* 	*2. Define panel; */
/* %let RTMTD=BJZZ ; *BJZZ or QMP;  */
/* %let period=1015 ; *1015 for 2010-15 or 1621 for 2016-21; */
/*  */
/* 	*3. Define sample type (only pseudo-sample available for the replicator); */
/* %let SAMPLETYPE=PSEUDO; *PSEUDO or TRUE; */

/* II. Obtain the panel-specific dataset */ 
%macro PANELDS();
	%if &RTMTD = BJZZ %then %do; 
		%if &SAMPLETYPE = PSEUDO %then %do; data DS; set mydata.pseudods_BJZZ; run; %end;
		%if &SAMPLETYPE = TRUE %then %do; data DS; set mydata.trueds_BJZZ; run; %end;
	%end;
	%if &RTMTD = QMP %then %do; 
		%if &SAMPLETYPE = PSEUDO %then %do; data DS; set mydata.pseudods_QMP; run; %end;
		%if &SAMPLETYPE = TRUE %then %do; data DS; set mydata.trueds_QMP; run; %end;
	%end;
	%if &period = 1015 %then %do; data DS; set DS; if DATE <= '31DEC2015'd; run; %end;
	%if &period = 1621 %then %do; data DS; set DS; if DATE >  '31DEC2015'd; run; %end;
%mend;
%PANELDS;

%include mymacros(M_DS4REG.sas);
%M_DS4REG(DSIN = DS);

/* III. Run all or part of code below */ 
%include mymacros(M_TAB6.sas);

/* OIBVOL & FULL SAMPLE  */
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

/* OIBTRD & FULL SAMPLE  */
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

/* Construct final outputs and save to dedicated folder */
data TAB6_FS; set TAB6_1 TAB6_3; run; 
data TAB6_MKTCAP; set TAB6_2 TAB6_4; run; 

proc export data=TAB6_FS
    outfile="&myoutputs./TAB6_FS_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;

proc export data=TAB6_MKTCAP
    outfile="&myoutputs./TAB6_MKTCAP_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;
