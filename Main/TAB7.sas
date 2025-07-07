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
%include mymacros(M_TAB7.sas);

/* OIBVOL + BID-ASK */
%M_TAB7(x=newret, y=oibvol, dsin=DS4REG);
data PA1;    _OIB_="oibvol        "; _RET_="Bid ask"; set PANELA; run;
data PB1;    _OIB_="oibvol        "; _RET_="Bid ask"; set PANELB; run;

/* OIBVOL + CRSP */
%M_TAB7(x=ret, y=oibvol, dsin=DS4REG);
data PA2;    _OIB_="oibvol        "; _RET_="CRSP   "; set PANELA; run;
data PB2;    _OIB_="oibvol        "; _RET_="CRSP   "; set PANELB; run;

/* OIBTRD + BID-ASK */
%M_TAB7(x=newret, y=oibtrd, dsin=DS4REG);
data PA3;    _OIB_="oibtrd        "; _RET_="Bid ask"; set PANELA; run;
data PB3;    _OIB_="oibtrd        "; _RET_="Bid ask"; set PANELB; run;

/* OIBTRD + CRSP */
%M_TAB7(x=ret, y=oibtrd, dsin=DS4REG);
data PA4;    _OIB_="oibtrd        "; _RET_="CRSP   "; set PANELA; run;
data PB4;    _OIB_="oibtrd        "; _RET_="CRSP   "; set PANELB; run;

/* Construct final outputs and save to dedicated folder */
data TAB7A; set PA1-PA4; run;
data TAB7B; set PB1-PB4; run;

proc export data=TAB7A
    outfile="&myoutputs./TAB7A_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;

proc export data=TAB7B
    outfile="&myoutputs./TAB7B_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;

