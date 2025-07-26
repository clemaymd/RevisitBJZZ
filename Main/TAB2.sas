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

%include mymacros(M_DS4REG.sas);
%M_DS4REG(DSIN = DS);

/* III. Run all or part of code below */ 
%include mymacros(M_TAB2N3.sas);

%M_TAB2N3(x=newret,y=oibvol,dsin=DS4REG);
data res1;   _OIB_="oibvol        "; _RET_="Bid ask";set nw;run;

%M_TAB2N3(x=ret,y=oibvol,dsin=DS4REG);
data res2;   _OIB_="oibvol        "; _RET_="CRSP   ";set nw;run;

%M_TAB2N3(x=newret,y=oibtrd,dsin=DS4REG);
data res3;   _OIB_="oibtrd        "; _RET_="Bid ask";set nw;run;

%M_TAB2N3(x=ret,y=oibtrd,dsin=DS4REG);
data res4;   _OIB_="oibtrd        "; _RET_="CRSP   ";set nw;run;

/* Construct final output and save to dedicated folder */
data TAB2; set res1-res4; run; 

proc export data=TAB2
    outfile="&myoutput./TAB2_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;
