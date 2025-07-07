/* *************************************************************************************************************
	Revisiting Boehmer et al (2021): Recent Period, Alternative method, Different Conclusions.
	David Ardia, Clement Aymard, Tolga Cenesizoglu;
   ********************************************************************************************************** */ 

/* 1. Replace with your paths */
libname mydata "/home/hecca/clementaymd/RevisitBJZZ/Data"; 
filename mycode "/home/hecca/clementaymd/RevisitBJZZ/Main"; 
filename mymacros "/home/hecca/clementaymd/RevisitBJZZ/Macros"; 
%let myoutputs = /home/hecca/clementaymd/RevisitBJZZ/Outputs;

/* 2. Define sample type (only pseudo-sample available for the replicator) */
%let SAMPLETYPE=PSEUDO; *PSEUDO or TRUE;

/* 3. Run Code Below */
/* Macro variables used to define panels (a) to (d) */
%let MTDS1=BJZZ;    %let MTDS2=QMP;     %let MTDS3=BJZZ;    %let MTDS4=QMP;
%let PERIODS1=1015; %let PERIODS2=1015; %let PERIODS3=1621; %let PERIODS4=1621;

%if &SAMPLETYPE=TRUE %then %do; *for paper results only;
	%let myoutputs = /home/hecca/clementaymd/RevisitBJZZ/Outputs_paper; 
	libname mydata "/scratch/hecca/clemaymd";
%end;

/* TAB1 */
%macro RUN_TAB1();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB1.sas);
	data TAB1_&RTMTD.&period. ; set TAB1; run;
	data TAB1_CORR_&period. ; set CORR; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB1_:; quit; 
%mend;
%RUN_TAB1;

/* TAB2 */
%macro RUN_TAB2();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB2.sas);
	data TAB2_&RTMTD.&period. ; set TAB2; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB2_:; quit; 
%mend;
%RUN_TAB2;

/* TAB3 */
%macro RUN_TAB3();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB3.sas);
	data TAB3_&RTMTD.&period. ; set TAB3; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB3_:; quit; 
%mend;
%RUN_TAB3;

/* TAB4 */
%macro RUN_TAB4();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB4.sas);
	data TAB4_&RTMTD.&period. ; set TAB4; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB4_:; quit; 
%mend;
%RUN_TAB4;

/* TAB5 */
%macro RUN_TAB5();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB5.sas);
	data TAB5_&RTMTD.&period. ; set TAB5; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB5_B: TAB5_Q:; quit; 
%mend;
%RUN_TAB5;

/* TAB6 */
%macro RUN_TAB6();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB6.sas);
	data TAB6_FS_&RTMTD.&period. ; set TAB6_FS; run;
	data TAB6_MKTCAP_&RTMTD.&period. ; set TAB6_MKTCAP; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB6_FS_: TAB6_MKTCAP_:; quit; 
%mend;
%RUN_TAB6;

/* TAB7 */
%macro RUN_TAB7();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB7.sas);
	data TAB7A_&RTMTD.&period. ; set TAB7A; run;
	data TAB7B_&RTMTD.&period. ; set TAB7B; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB7A_: TAB7B_:; quit; 
%mend;
%RUN_TAB7;

/* TAB8 */
%macro RUN_TAB8();
	%do i=1 %to 4;
	%let RTMTD=&&MTDS&i; %let period=&&PERIODS&i ;
	%include mycode(TAB8.sas);
	data TAB8_&RTMTD.&period. ; set TAB8; run;
	%end;
	proc datasets lib=work memtype=data nodetails; save TAB8_:; quit; 
%mend;
%RUN_TAB8;

