/* ************************************************************************************************************
   This sas code extracts all retail trades based on the quote midpoint (QMP) approach as described in Barber
   et al. (2023) and computes daily aggregated retail-trade quantities.
   
   The trades are identified as retail if they are off-exchange, have subpenny improvement, and have an
   execution price outside 40-60% of the NBBO spread. They are classified as buy (sell) when the price is 
   >60% (<40%) of the NBBO spread.

   When the trade price is outside the NBBO spread, I follow Barber et al. (2023, footnote 9), that is, 
   for all trades outside the NBBO spread: 
	- if the NBBO spread is *not* a penny, I sign it with the QMP approach
	- if the NBBO spread is       a penny, I sign it with the Boehmer et al. (2021) (BJZZ) method

   The computed retail-trade quantities include:
     - Daily volume of shares bought and sold (Mrbvol Mrsvol)
     - Daily number of buy- and sell- trades (Mrbtrd Mrstrd)
     - Daily order imbalances relative to share volume or number of trades (Mroibvol Mroibtrd)
   
   /!\ For dates between Oct-2016 to Oct-2018, users need to exclude the stocks participating in the SEC's 
	Tick Pilot Size Program, as recommended by Barber et al. (2023), among others.
   /!\ This program allows the user to define its universe of stock through the parameter StockList in the macro
	Compute_RTQ_QMP. For the entire TAQ universe, set StockList=NA.

   This code is released with the paper "Revisiting Boehmer et al. (2021): Recent Period, Alternative Method, 
   Different Conclusions." Authors: David Ardia, Clement Aymard, and Tolga Cenesizoglu. 
   https://ssrn.com/abstract=4703056 
   
   -------------------------------
   Version 1.0 (February 2024)
   Contact: clement d.o.t aymard at hec d.o.t ca
   ********************************************************************************************************* */

%macro CREATE_LIST_TAQDS(FirstDay_YYYYMMDD, LastDay_YYYYMMDD, DailyMonthly);
/* Parameters: 
	[FirstDay_YYYYMMDD]: First day of period / format: integer / example: 20100101.
	[LastDay_YYYYMMDD]: Last day of period / format: integer / example: 20100331.
	[DailyMonthly]: generate monthly or daily list? / format: unquoted character / example: Daily, Monthly.
*/
	
	data TAQ_DS;
		set sashelp.vtable(keep=libname memname);
		where libname="TAQMSEC" and substr(memname, 1, 4)="WCT_";
		Date_Char = substr(memname, length(memname)-7, length(memname));
		
		/* For daily DS */
		ds_fullname_day= cats(libname,'.', memname);
		YYYMMDD=input(Date_Char, yymmdd8.);
		FirstDay = %sysfunc(inputn(&FirstDay_YYYYMMDD, yymmdd8.));
		LastDay = %sysfunc(inputn(&LastDay_YYYYMMDD, yymmdd8.));
		
		/* For monthly DS */
		ds_fullname_mth = cats(libname,'.', substr(memname, 1, 10),':');
		YYYMM=input(Date_Char, yymmn6.);
		FirstMonth = %sysfunc(inputn(&FirstDay_YYYYMMDD, yymmn6.));
		LastMonth = %sysfunc(inputn(&LastDay_YYYYMMDD, yymmn6.));
		
		format YYYMMDD yymmdd8. FirstDay yymmdd8. LastDay yymmdd8. 
			   YYYMM yymmn6. FirstMonth yymmn6. LastMonth yymmn6.;
	run;
	
	%if &DailyMonthly = Daily %then %do;
		data TAQ_DS2; set TAQ_DS; where YYYMMDD >= FirstDay and YYYMMDD <= LastDay; run;
		
		/* Create macro variables with names of daily DS */
		data _NULL_;
			set TAQ_DS2 end=last;
			call symputx(cats('TAQDS', _n_), ds_fullname_day, 'G');
			if last then call symputx('nb_dayormonth', _n_, 'G');
		run;	
	%end;
	
	%if &DailyMonthly = Monthly %then %do;
		data TAQ_DS2; set TAQ_DS; where YYYMM >= FirstMonth and YYYMM <= LastMonth;	run;
		proc sort data=TAQ_DS2(keep=ds_fullname_mth) nodupkey ; by _ALL_; run;

		/* Create macro variables with names of monthly DS */
		data _NULL_;
			set TAQ_DS2 end=last;
			call symputx(cats('TAQDS', _n_), ds_fullname_mth, 'G');
			if last then call symputx('nb_dayormonth', _n_, 'G');
		run;
	%end;
%mend;

/* ---------------------------------------------------------------------------------------------------------- */
%macro Compute_RTQ_QMP(FirstDay_YYYYMMDD=, LastDay_YYYYMMDD=, DailyMonthly=, StockList=);
/* Parameters: 
	[FirstDay_YYYYMMDD]: First day of period / format: integer / example: 20100101.
	[LastDay_YYYYMMDD]: Last day of period / format: integer / example: 20100331.
	[DailyMonthly]: Run the process (loop) at daily or monthly frequency? / format: unquoted character
		/ example: Daily, Monthly.
	[StockList]: two-column dataset with your stock list using the TAQ fields SYM_ROOT and SYM_SUFFIX 
		/ format: .sas7bdat file / example: mylib.pseudo_taqsymlist. For the entire TAQ universe, set 
		StockList=NA.
*/
	
	/* All existing daily of monthly DS for the period */
	%CREATE_LIST_TAQDS(FirstDay_YYYYMMDD=&FirstDay_YYYYMMDD, 
					LastDay_YYYYMMDD=&LastDay_YYYYMMDD,
					DailyMonthly=&DailyMonthly); 
	
	/* Delete output if it already exists */
	%if %sysfunc(exist(mylib.RTQ_QMP)) %then %do; proc delete data=mylib.RTQ_QMP; run; %end;
	
	%do i=1 %to &nb_dayormonth;
	
	/* Identify and sign retail trade according to the QMP approach */
	data RT_QMP_i(replace=yes);
		retain DATE SYM_ROOT SYM_SUFFIX TIME PRICE SIZE p;
		set &&TAQds&i(drop=TR_SEQNUM rename=(TIME_M=TIME));
		
		/* exclude the following condition codes, keep market-opening hours, and non-zero size */
		if _n_=1 then p=prxparse("/1|4|7|8|9|[A-D]|G|H|K|L|N|P|R|S|[U-W]|Y|Z]/");
		start=1;
		stop=length(TR_SCOND);
		call prxnext(p,start,stop,TR_SCOND,position,length);
		drop p start stop position length;
		if position=0;
		if TIME >= '9:30:00't and TIME <='16:00:00't and SIZE>0;

		/* identification: must be off-exchange, have subpenny improvements, and not in 40-60% of the NBBO spread */
		if EX = 'D'; 
		CENTFRAC = mod(price*100,1); if CENTFRAC > 0;
		BASPREAD = NBO - NBB; 
		MIDPOINT = NBB + 0.5*BASPREAD; SPREAD40 = NBB + 0.4*BASPREAD; SPREAD60 = NBO - 0.4*BASPREAD;
		if SPREAD40 <= PRICE <= SPREAD60 then DELETE;
		if BASPREAD < 0 then DELETE; *Exclude obs with negative spread;

		/* signing the trade: a buy (sell) is >60% (<40%) of the NBBO spread */
		if PRICE < SPREAD40 then TRDIR='sell';
		if PRICE > SPREAD60 then TRDIR='buy';
		
		/* When transaction price is outside the NBBO spread */
			/* 1. flag these cases */
		FLAG_OUTSIDENBBO = 0; if PRICE < NBB or PRICE > NBO then FLAG_OUTSIDENBBO = 1;
		BASPREAD_ROUNDED = round(BASPREAD,.01); *necessary since BASPREAD has hidden decimals see put(BASPREAD,best32.);
			/* 2. if the associated NBBO spread is a round penny, sign it with BJZZ rather than QMP */
		TRDIR_MTD='QMP '; if FLAG_OUTSIDENBBO=1 and BASPREAD_ROUNDED=0.01 then TRDIR_MTD='BJZZ'; *keep track of the method used;
		if FLAG_OUTSIDENBBO = 1 and BASPREAD_ROUNDED = 0.01 and 0.4 <= centfrac <= 0.6 then DELETE;
		if FLAG_OUTSIDENBBO = 1 and BASPREAD_ROUNDED = 0.01 and centfrac < 0.4 then TRDIR='sell';
		if FLAG_OUTSIDENBBO = 1 and BASPREAD_ROUNDED = 0.01 and centfrac > 0.6 then TRDIR='buy';
		
		length SYMBOL $ 17; SYMBOL=catx(' ', SYM_ROOT, SYM_SUFFIX);	*concat root and suffix;
		drop p start stop position length type BASPREAD_ROUNDED EX TR_SCOND NBOqty NBBqty ;	*;
	run;	
	
	/* Reduce to your stock list if applicable */
	%if &StockList NE NA %then %do;
	proc sql;
		create table RT_QMP_i_MYSTOCK as 
		select a.*
		from RT_QMP_i a, &StockList b
		where a.sym_root = b.sym_root 
		and a.sym_suffix = b.sym_suffix 
		order by a.DATE, SYMBOL, a.TIME ;
	quit; 
	data RT_QMP_i(replace=yes); set RT_QMP_i_MYSTOCK; run;
	%end;	

	/* Compute retail trades quantities */
	/* Mrbvol, Mrsvol, Mrbtrd and Mrdstrd */
	proc sql;
		create table RTQ_i1(drop=n) AS
		select DATE, SYMBOL, TRDIR, SIZE, COUNT(TRDIR) AS NTRD, SUM(SIZE) AS NSH, monotonic() as n
		from RT_QMP_i
		group by DATE, SYMBOL, TRDIR
		having max(n) = n;
	quit;	
	
	/* reduce to one row per stock per day */
	data RTQ_i2;
		set RTQ_i1;
		Mrbvol_TMP = 0 ; Mrsvol_TMP = 0 ; Mrbtrd_TMP = 0 ; Mrstrd_TMP = 0 ;
		if TRDIR = 'buy' then do; Mrbtrd_TMP = NTRD; Mrbvol_TMP = NSH; end;
		if TRDIR = 'sell' then do; Mrstrd_TMP = NTRD; Mrsvol_TMP = NSH; end;
	run;
	proc sql;
		create table RTQ_i3 as
		select DATE, SYMBOL,
				MAX(Mrbvol_TMP) AS Mrbvol, MAX(Mrsvol_TMP) AS Mrsvol, 
				MAX(Mrbtrd_TMP) AS Mrbtrd, MAX(Mrstrd_TMP) AS Mrstrd
		from RTQ_i2
		group by DATE, SYMBOL;
	QUIT;
	
	/* Mroibvol and Mroibtrd */
	data OUT_i(replace=yes);
		set RTQ_i3;
		Mroibvol = (Mrbvol-Mrsvol)/(Mrbvol+Mrsvol);
		Mroibtrd = (Mrbtrd-Mrstrd)/(Mrbtrd+Mrstrd);
	run;
	
	/* Append the DS month by month or day by day */
	proc append base=mylib.RTQ_QMP data=OUT_i; run;

	%if &DailyMonthly=Daily   %then %do; %put &=i day=%substr(&&TAQds&i, 13); %end;
	%if &DailyMonthly=Monthly %then %do; %put &=i month=%substr(&&TAQds&i, 13); %end;

	%end;
%mend;

/* Replace with your path */
libname mylib "/home/hecca/clementaymd/RevisitBJZZ/QuoteMidpoint"; 

%Compute_RTQ_QMP(FirstDay_YYYYMMDD=20100101, LastDay_YYYYMMDD=20100110, DailyMonthly=Daily, StockList=mylib.pseudo_taqsymlist);
