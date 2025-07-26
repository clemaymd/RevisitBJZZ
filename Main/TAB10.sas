/* *************************************************************************************************************
	Revisiting Boehmer et al (2021): Recent Period, Alternative method, Different Conclusions.
	David Ardia, Clement Aymard, Tolga Cenesizoglu;
   ********************************************************************************************************** */ 

/* I. Users options: uncomment lines 7-19 to use this file independently  */
/* 	*1. Replace with your paths; */
/* libname mydata "/home/hecca/clementaymd/RevisitBJZZ/Data"; * data for the replicator; */
/* libname mytrdata "/scratch/hecca/clemaymd"; 			   * true data (n/a for the replicator); */
/* filename mymacros "/home/hecca/clementaymd/RevisitBJZZ/Macros";  */
/* %let myout = /home/hecca/clementaymd/RevisitBJZZ/Outputs;   * output for the replicator; */
/* %let mytrout = /home/hecca/clementaymd/RevisitBJZZ/Outputs_paper; * output true data (n/a for the replicator); */
/*  */
/* 	*2. Define panel; */
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
	%if &spreadgrptyp = median %then %do; data DS; set DS; rename spreadgrp_med=spreadgrp medspread=spread; run; %end; 
	%if &spreadgrptyp = average %then %do; data DS; set DS; rename spreadgrp_avg=spreadgrp avgspread=spread; run; %end; 
%mend;
%PANELDS;

/* TAB10 PANEL A */
proc sort data=DS; by PERIOD; quit;
PROC MEANS data=DS StackODSOutput n mean std MEDIAN Q1 Q3;
	Var spread;
	by PERIOD;
	ods output summary=outsum1;
RUN; 
proc sort data=DS; by spreadgrp PERIOD; quit;
PROC MEANS data=DS StackODSOutput n mean std MEDIAN Q1 Q3;
	Var spread;
	by spreadgrp PERIOD;
	ods output summary=outsum2;
RUN; 
data TAB10A; set outsum1 outsum2; run;

/* TAB10 PANEL B */
/* correlation all spreads */
proc sort data=DS; by PERIOD; quit;
proc corr data=DS out=CORR0; var mr:; by PERIOD; run;
/* organize output */
data CORR1; set CORR0; 
	if find(_NAME_,'BJZZ','i') ge 1 or _TYPE_="N";
	keep PERIOD _NAME_ Mrbvol Mrsvol Mrbtrd Mrstrd Mroibvol Mroibtrd; 
run;
data CORR1; SPREADGRP = '      '; set CORR1; run;

/* correlation by spread group */
proc sort data=DS; by spreadgrp PERIOD; quit;
proc corr data=DS out=CORR0; var mr:; by spreadgrp PERIOD; run;
/* organize output */
data CORR2; set CORR0; 
	if find(_NAME_,'BJZZ','i') ge 1 or _TYPE_="N";
	length spreadgrp $6;
	keep spreadgrp PERIOD _NAME_ Mrbvol Mrsvol Mrbtrd Mrstrd Mroibvol Mroibtrd; 
run;

data TAB10B; set CORR1 CORR2; run;

/* Save outputs to dedicated folder */
proc export data=TAB10A
    outfile="&myoutput./TAB10A.txt"
    dbms=dlm replace;
    delimiter="";
run;
proc export data=TAB10B
    outfile="&myoutput./TAB10B.txt"
    dbms=dlm replace;
    delimiter="";
run;

