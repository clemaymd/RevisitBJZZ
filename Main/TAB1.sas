/* *************************************************************************************************************
	Revisiting Boehmer et al (2021): Recent Period, Alternative method, Different Conclusions.
	David Ardia, Clement Aymard, Tolga Cenesizoglu;
   ********************************************************************************************************** */ 

/* I. Users options: uncomment lines 7-19 to use this file independently  */
	*1. Replace with your paths;
/* libname mydata "/home/hecca/clementaymd/RevisitBJZZ/Data"; * data for the replicator; */
/* libname mytrdata "/scratch/hecca/clemaymd"; 			   * true data (n/a for the replicator); */
/* filename mymacros "/home/hecca/clementaymd/RevisitBJZZ/Macros";  */
/* %let myout = /home/hecca/clementaymd/RevisitBJZZ/Outputs;   * output for the replicator; */
/* %let mytrout = /home/hecca/clementaymd/RevisitBJZZ/Outputs_paper; * output true data (n/a for the replicator); */
/*  */
/* 	*2. Define panel; */
/* %let RTMTD=QMP ; *BJZZ or QMP;  */
/* %let period=1621 ; *1015 for 2010-15 or 1621 for 2016-21; */
/*  */
/* 	*3. Define sample type (only pseudo-sample available for the replicator); */
/* %let SAMPLETYPE=TRUE; *PSEUDO or TRUE; */

/* II. Obtain the panel-specific dataset */ 
%macro PANELDS();
	%if &SAMPLETYPE = PSEUDO %then %do; 
		%if &RTMTD = BJZZ %then %do; data DS; set mydata.pseudods_BJZZ; run; %end;
		%if &RTMTD = QMP %then %do; data DS; set mydata.pseudods_QMP; run; %end;
		%global myoutput; %let myoutput=&myout; 
	%end;
	%if &SAMPLETYPE = TRUE %then %do; 
		%if &RTMTD = BJZZ %then %do; data DS; set mytrdata.trueds_BJZZ; run; %end;
		%if &RTMTD = QMP %then %do; data DS; set mytrdata.trueds_QMP; run; %end;
		%global myoutput; %let myoutput=&mytrout; 
	%end;
	%if &period = 1015 %then %do; data DS; set DS; if DATE <= '31DEC2015'd; run; %end;
	%if &period = 1621 %then %do; data DS; set DS; if DATE >  '31DEC2015'd; run; %end;
%mend;
%PANELDS;

/* III. Run all or part of code below */ 
/* Summary Stats */
PROC MEANS data=DS StackODSOutput n mean std MEDIAN Q1 Q3;
	Var Mrbvol Mrsvol Mrbtrd Mrstrd Mroibvol Mroibtrd;
	ods output summary=TAB1;
RUN; 

proc export data=TAB1
    outfile="&myoutput./TAB1_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;

/* Correlations */
/* BJZZ and QMP data */
%macro DSFORCORR();
	%if &SAMPLETYPE = PSEUDO %then %do; 
		data DS_BJZZ; set mydata.pseudods_BJZZ; run; 
		data DS_QMP;  set mydata.pseudods_QMP; run; 
	%end;
	%if &SAMPLETYPE = TRUE %then %do; 
		data DS_BJZZ; set mytrdata.trueds_BJZZ; run; 
		data DS_QMP;  set mytrdata.trueds_QMP; run; 
	%end;
	%if &period = 1015 %then %do; 
		data DS_BJZZ; set DS_BJZZ; if DATE <= '31DEC2015'd; run; 
		data DS_QMP;  set DS_QMP;  if DATE <= '31DEC2015'd; run; 
	%end;
	%if &period = 1621 %then %do; 
		data DS_BJZZ; set DS_BJZZ; if DATE >  '31DEC2015'd; run;
		data DS_QMP; set DS_QMP;   if DATE >  '31DEC2015'd; run;
	%end;
%mend;
%DSFORCORR;
	
proc sql;
	create table DSALL as 
	select a.*, b.*
	from 
		DS_BJZZ(rename=(mrbvol=mrbvol_BJZZ mrsvol=mrsvol_BJZZ mrbtrd=mrbtrd_BJZZ mrstrd=mrstrd_BJZZ
	mroibvol=mroibvol_BJZZ mroibtrd=mroibtrd_BJZZ)) a
		inner join DS_QMP b 
	on a.DATE = b.DATE and a.STOCK_ID=b.STOCK_ID 
	order by DATE, STOCK_ID;
run;

proc corr data=DSALL out=CORR0; var mr:; run;

/* Construct final correlation output and save to dedicated folder */
data CORR; set CORR0; 
	if find(_NAME_,'BJZZ','i') ge 1;
	keep _NAME_ Mrbvol Mrsvol Mrbtrd Mrstrd Mroibvol Mroibtrd; 
run;

proc export data=CORR
    outfile="&myoutput./TAB1_CORR_&period..txt"
    dbms=dlm replace;
    delimiter="";
run;

