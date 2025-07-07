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
%include mymacros(M_TAB5.sas);

/* OIBVOL + BID-ASK */
%M_TAB5(x=oibvol, y=newret, dsin=DS4REG, k=2);
data res1;   _OIB_="oibvol        "; _RET_="Bid ask"; _K_=2; set nw; run;

%M_TAB5(x=oibvol, y=newret, dsin=DS4REG, k=4);
data res2;   _OIB_="oibvol        "; _RET_="Bid ask"; _K_=4; set nw; run;

%M_TAB5(x=oibvol, y=newret, dsin=DS4REG, k=6);
data res3;   _OIB_="oibvol        "; _RET_="Bid ask"; _K_=6; set nw; run;

%M_TAB5(x=oibvol, y=newret, dsin=DS4REG, k=8);
data res4;   _OIB_="oibvol        "; _RET_="Bid ask"; _K_=8; set nw; run;

%M_TAB5(x=oibvol, y=newret, dsin=DS4REG, k=10);
data res5;   _OIB_="oibvol        "; _RET_="Bid ask"; _K_=10; set nw; run;

%M_TAB5(x=oibvol, y=newret, dsin=DS4REG, k=12);
data res6;   _OIB_="oibvol        "; _RET_="Bid ask"; _K_=12; set nw; run;

data TAB5_1; set res1-res6; if find(_NAME_,'loib'); drop _NAME_; run;

/* OIBTRD + BID-ASK */
%M_TAB5(x=oibtrd, y=newret, dsin=DS4REG, k=2);
data res1;   _OIB_="oibtrd        "; _RET_="Bid ask"; _K_=2; set nw; run;

%M_TAB5(x=oibtrd, y=newret, dsin=DS4REG, k=4);
data res2;   _OIB_="oibtrd        "; _RET_="Bid ask"; _K_=4; set nw; run;

%M_TAB5(x=oibtrd, y=newret, dsin=DS4REG, k=6);
data res3;   _OIB_="oibtrd        "; _RET_="Bid ask"; _K_=6; set nw; run;

%M_TAB5(x=oibtrd, y=newret, dsin=DS4REG, k=8);
data res4;   _OIB_="oibtrd        "; _RET_="Bid ask"; _K_=8; set nw; run;

%M_TAB5(x=oibtrd, y=newret, dsin=DS4REG, k=10);
data res5;   _OIB_="oibtrd        "; _RET_="Bid ask"; _K_=10; set nw; run;

%M_TAB5(x=oibtrd, y=newret, dsin=DS4REG, k=12);
data res6;   _OIB_="oibtrd        "; _RET_="Bid ask"; _K_=12; set nw; run;

data TAB5_2; set res1-res6; if find(_NAME_,'loib'); drop _NAME_; run;

/* OIBVOL + CRSP */
%M_TAB5(x=oibvol, y=ret, dsin=DS4REG, k=2);
data res1;   _OIB_="oibvol        "; _RET_="CRSP   "; _K_=2; set nw; run;

%M_TAB5(x=oibvol, y=ret, dsin=DS4REG, k=4);
data res2;   _OIB_="oibvol        "; _RET_="CRSP   "; _K_=4; set nw; run;

%M_TAB5(x=oibvol, y=ret, dsin=DS4REG, k=6);
data res3;   _OIB_="oibvol        "; _RET_="CRSP   "; _K_=6; set nw; run;

%M_TAB5(x=oibvol, y=ret, dsin=DS4REG, k=8);
data res4;   _OIB_="oibvol        "; _RET_="CRSP   "; _K_=8; set nw; run;

%M_TAB5(x=oibvol, y=ret, dsin=DS4REG, k=10);
data res5;   _OIB_="oibvol        "; _RET_="CRSP   "; _K_=10; set nw; run;

%M_TAB5(x=oibvol, y=ret, dsin=DS4REG, k=12);
data res6;   _OIB_="oibvol        "; _RET_="CRSP   "; _K_=12; set nw; run;

data TAB5_3; set res1-res6; if find(_NAME_,'loib'); drop _NAME_; run;

/* OIBTRD + CRSP */
%M_TAB5(x=oibtrd, y=ret, dsin=DS4REG, k=2);
data res1;   _OIB_="oibtrd        "; _RET_="CRSP   "; _K_=2; set nw; run;

%M_TAB5(x=oibtrd, y=ret, dsin=DS4REG, k=4);
data res2;   _OIB_="oibtrd        "; _RET_="CRSP   "; _K_=4; set nw; run;

%M_TAB5(x=oibtrd, y=ret, dsin=DS4REG, k=6);
data res3;   _OIB_="oibtrd        "; _RET_="CRSP   "; _K_=6; set nw; run;

%M_TAB5(x=oibtrd, y=ret, dsin=DS4REG, k=8);
data res4;   _OIB_="oibtrd        "; _RET_="CRSP   "; _K_=8; set nw; run;

%M_TAB5(x=oibtrd, y=ret, dsin=DS4REG, k=10);
data res5;   _OIB_="oibtrd        "; _RET_="CRSP   "; _K_=10; set nw; run;

%M_TAB5(x=oibtrd, y=ret, dsin=DS4REG, k=12);
data res6;   _OIB_="oibtrd        "; _RET_="CRSP   "; _K_=12; set nw; run;

data TAB5_4; set res1-res6; if find(_NAME_,'loib'); drop _NAME_; run;

/* Construct final output and save to dedicated folder */
data TAB5; set TAB5_1-TAB5_4; run; 

proc export data=TAB5
    outfile="&myoutputs./TAB5_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;
