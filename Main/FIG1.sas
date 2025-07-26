/* *************************************************************************************************************
	Revisiting Boehmer et al (2021): Recent Period, Alternative method, Different Conclusions.
	David Ardia, Clement Aymard, Tolga Cenesizoglu;
   ********************************************************************************************************** */ 

/* I. Users options  */
/* 	*1. Replace with your paths; */
/* libname mydata "/home/hecca/clementaymd/RevisitBJZZ/Data"; * data for the replicator; */
/* libname mytrdata "/scratch/hecca/clemaymd"; 			   * true data (n/a for the replicator); */
/* filename mymacros "/home/hecca/clementaymd/RevisitBJZZ/Macros";  */
/* %let myout = /home/hecca/clementaymd/RevisitBJZZ/Outputs;   * output for the replicator; */
/* %let mytrout = /home/hecca/clementaymd/RevisitBJZZ/Outputs_paper; * output true data (n/a for the replicator); */
/*  */
/* 	*2. Define panel; */
/* %let spreadgrptyp=median; *median or average; */
/*  */
/* 	*3. Define sample type (only pseudo-sample available for the replicator); */
/* %let SAMPLETYPE=TRUE; *PSEUDO or TRUE; */

/* II. Obtain the panel-specific dataset */ 
%macro PANELDS();
	%if &SAMPLETYPE = PSEUDO %then %do; data DS; set mydata.pseudods_4spread; run; %global myoutput; %let myoutput=&myout; %end;
	%if &SAMPLETYPE = TRUE %then %do; data DS; set mytrdata.trueds_4spread; %global myoutput; %let myoutput=&mytrout; %end;
	%if &spreadgrptyp = median %then %do; data DS; set DS; rename spreadgrp_med=spreadgrp medspread=spread; run; %end; 
	%if &spreadgrptyp = average %then %do; data DS; set DS; rename spreadgrp_avg=spreadgrp avgspread=spread; run; %end; 
%mend;
%PANELDS;

/* Build and save figure 1 */
ods select cdfplot;
proc univariate data=DS;
	var SPREAD;
	class PERIOD;
	cdfplot SPREAD / overlay ;
	ods output cdfplot=outCDF;   /* data set contains ECDF values */
run;

/* filename grafout '&myoutput./FIG1.png';  /* Define the output file */
ods listing gpath="&myoutput";
ods graphics / reset=all imagename="FIG1" imagefmt=png;
goptions gsfmode=replace;
proc sgplot data=outCDF(where=(ECDFX <= 0.3));
   step x=ECDFX y=ECDFY / group=Class1;          /* variable names created by PROC UNIVARIATE */
   refline 0.01 / axis=x lineattrs=(color=black pattern=dash) label="0.01";
run;
ods listing close;
