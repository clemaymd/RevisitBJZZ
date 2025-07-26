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
/* %let ngrp=2; *number of spread group formed (only ngrp=2 available for the replicator); */
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
%include mymacros(M_TAB2N3.sas);
%include mymacros(M_TAB11.sas);

/* ALL SPREADS */
%M_TAB2N3(x=oibvol,y=newret,dsin=DS4REG);
data res1;   _OIB_="oibvol        "; _RET_="Bid ask"; set nw; run;

%M_TAB2N3(x=oibvol,y=ret,dsin=DS4REG);
data res2;   _OIB_="oibvol        "; _RET_="CRSP   "; set nw; run;

%M_TAB2N3(x=oibtrd,y=newret,dsin=DS4REG);
data res3;   _OIB_="oibtrd        "; _RET_="Bid ask"; set nw; run;

%M_TAB2N3(x=oibtrd,y=ret,dsin=DS4REG);
data res4;   _OIB_="oibtrd        "; _RET_="CRSP   "; set nw; run;

/* IQR */
proc sql;
	create table IQR_OIBVOL_ALLSPREADS as
	select "oibvol" as _OIB_, "" as _RET_, "IQR" as _NAME_, "      " as SPREADGRP, IQR as Estimate, . as tValue, . as order
	from IQ_MROIBVOL;
quit;
proc sql;
	create table IQR_OIBTRD_ALLSPREADS as
	select "oibtrd" as _OIB_, "" as _RET_, "IQR" as _NAME_, "      " as SPREADGRP, IQR as Estimate, . as tValue, . as order
	from IQ_MROIBTRD;
quit;

/* DECOMPOSE BY SPREAD GROUPS */
%M_TAB11(x=oibvol,y=newret,dsin=DS4REG);
data res5;   _OIB_="oibvol        "; _RET_="Bid ask"; set nw; run;

%M_TAB11(x=oibvol,y=ret,dsin=DS4REG);
data res6;   _OIB_="oibvol        "; _RET_="CRSP   "; set nw; run;

%M_TAB11(x=oibtrd,y=newret,dsin=DS4REG);
data res7;   _OIB_="oibtrd        "; _RET_="Bid ask"; set nw; run;

%M_TAB11(x=oibtrd,y=ret,dsin=DS4REG);
data res8;   _OIB_="oibtrd        "; _RET_="CRSP   "; set nw; run;

/* IQR */
proc sql;
	create table IQR_OIBVOL as
	select "oibvol" as _OIB_, "" as _RET_, "IQR" as _NAME_, SPREADGRP as SPREADGRP, IQR as Estimate, . as tValue, . as order
	from IQ_MROIBVOL;
quit;
proc sql;
	create table IQR_OIBTRD as
	select "oibtrd" as _OIB_, "" as _RET_, "IQR" as _NAME_, SPREADGRP as SPREADGRP, IQR as Estimate, . as tValue, . as order
	from IQ_MROIBTRD;
quit;

/* Construct final output and save to dedicated folder */
data TAB11; 
set res1 res2 IQR_OIBVOL_ALLSPREADS res3 res4 IQR_OIBTRD_ALLSPREADS
	 res5 res6 IQR_OIBVOL res7 res8 IQR_OIBTRD  ; 
run;

proc export data=TAB11
    outfile="&myoutput./TAB11_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;
