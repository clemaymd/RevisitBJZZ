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

/* III. Run code below */ 
%include mymacros(M_TAB8.sas);
%M_TAB8(y=loibvol, dsin=DS4REG);

/* Construct final output and save to dedicated folder */
data TAB8; set RES_PTF1 RES_PTF2; run;

proc export data=TAB8
    outfile="&myoutputs./TAB8_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;
