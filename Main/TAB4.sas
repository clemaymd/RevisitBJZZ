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
%include mymacros(M_TAB4.sas);

%M_TAB4(x=oibvol, y=newret, dsin=DS4REG, subgroup_var=mktcap);
data res1;   _OIB_="oibvol        "; _RET_="Bid ask"; _SUBGRP_="MKTCAP     "; set nw;run;
data IQR1;   _OIB_="oibvol        "; _RET_="Bid ask"; _SUBGRP_="MKTCAP     "; set IQR;run;

%M_TAB4(x=oibtrd, y=newret, dsin=DS4REG, subgroup_var=mktcap);
data res2;   _OIB_="oibtrd        "; _RET_="Bid ask"; _SUBGRP_="MKTCAP     "; set nw;run;
data IQR2;   _OIB_="oibtrd        "; _RET_="Bid ask"; _SUBGRP_="MKTCAP     "; set IQR;run;

%M_TAB4(x=oibvol, y=newret, dsin=DS4REG, subgroup_var=shrprc);
data res3;   _OIB_="oibvol        "; _RET_="Bid ask"; _SUBGRP_="Share price"; set nw;run;
data IQR3;   _OIB_="oibvol        "; _RET_="Bid ask"; _SUBGRP_="Share price"; set IQR;run;

%M_TAB4(x=oibtrd, y=newret, dsin=DS4REG, subgroup_var=shrprc);
data res4;   _OIB_="oibtrd        "; _RET_="Bid ask"; _SUBGRP_="Share price"; set nw;run;
data IQR4;   _OIB_="oibtrd        "; _RET_="Bid ask"; _SUBGRP_="Share price"; set IQR;run;

%M_TAB4(x=oibvol, y=newret, dsin=DS4REG, subgroup_var=turnover);
data res5;   _OIB_="oibvol        "; _RET_="Bid ask"; _SUBGRP_="Turnover"; set nw;run;
data IQR5;   _OIB_="oibvol        "; _RET_="Bid ask"; _SUBGRP_="Turnover"; set IQR;run;

%M_TAB4(x=oibtrd, y=newret, dsin=DS4REG, subgroup_var=turnover);
data res6;   _OIB_="oibtrd        "; _RET_="Bid ask"; _SUBGRP_="Turnover"; set nw;run;
data IQR6;   _OIB_="oibtrd        "; _RET_="Bid ask"; _SUBGRP_="Turnover"; set IQR;run;

data final_RES; set res1-res6; if _NAME_ = 'x'; drop _NAME_; run;
data final_IQR; set IQR1-IQR6; run;

/* Construct final output and save to dedicated folder */
proc sql;
	create table TAB4 as
	select a._OIB_, a._RET_, a._SUBGRP_, a.CLASSVAR_GRP, a.Estimate, a.tValue, b.IQR, a.order
	from final_RES a, final_IQR b
	where a._OIB_ = b._OIB_
	and a._RET_ = b._RET_
	and a._SUBGRP_ = b._SUBGRP_
	and a.CLASSVAR_GRP = b.CLASSVAR_GRP;
quit;

proc export data=TAB4 
    outfile="&myoutputs./TAB4_&RTMTD.&period..txt"
    dbms=dlm replace;
    delimiter="";
run;