%macro M_TAB8(y, dsin);

	/* Create intense Buy and Sell portfolios based on current-week oib */
	data hft1(keep=dx stock_id &y lnewret size); 
		set &dsin; 
		if mod(dx,5)=0; *only non-overlapping weeks;
	run;
	proc sort data=hft1; by dx; run;
	proc univariate data=hft1 noprint;
		var &y; by dx;
	    output out=DECILES
		pctlpts = 5 to 95 by 5
		pctlpre = P_;
	run;
	proc sql;
		create table hft2 as
		select a.*, b.*
		from hft1 a left join DECILES b
		on a.dx = b.dx;
	quit;
	data hft2_; set hft2;
		if &y <= P_10 then do PTFTYPE1 = "INTENSE_SELLING"; end;
		if &y >= P_90 then do PTFTYPE1 = "INTENSE_BUYING "; end;
		if &y <= P_20 then do PTFTYPE2 = "SELLING"; end;
		if &y >= P_80 then do PTFTYPE2 = "BUYING"; end;
		if missing(P_10) or missing(P_20) or missing(P_80) or missing(P_90) or missing(&y) then do PTFTYPE1 = ""; end;
		if missing(P_10) or missing(P_20) or missing(P_80) or missing(P_90) or missing(&y) then do PTFTYPE2 = ""; end;
		keep dx STOCK_ID lnewret &y P_10 P_20 P_80 P_90 PTFTYPE1 PTFTYPE2 size;
	run;

	/* Intense Buying and Selling portfolios (assuming equal-weight) */
	proc sql;
		create table BSPTF1(drop=size P_10 P_20 P_80 P_90 ) as
		select *, 1/COUNT(STOCK_ID) as w
		from hft2_
		group by dx, PTFTYPE1;
	quit;

	/* Buying and Selling portfolios (assuming equal-weight) */
	proc sql;
		create table BSPTF2(drop=size P_10 P_20 P_80 P_90 ) as
		select *, 1/COUNT(STOCK_ID) as w
		from hft2_
		group by dx, PTFTYPE2;
	quit;
	
	%do j=1 %to 2;
		/* Compute lagged returns for k=-20 to k=-5, and contemporaneous return (k=0) as done in Panel A */	
		proc sort data=BSPTF&j.; by STOCK_ID dx; run;
		data BSPTF&j.; set BSPTF&j.; ldx = lag(dx); lSTOCK_ID = lag(STOCK_ID); run;
		data ret1; set BSPTF&j.;
		lnewretk0   = lnewret;       *contemporaneous week, i.e. k=0;
		lnewretkm5  = lag(lnewret);  *1-week lag, i.e. k=-5;
		lnewretkm10 = lag2(lnewret); *2-weeks lag, i.e. k=-10;
		lnewretkm15 = lag3(lnewret); *3-weeks lag, i.e. k=-15;
		lnewretkm20 = lag4(lnewret); *4-weeks lag, i.e. k=-20;
		if lSTOCK_ID NE STOCK_ID or ldx NE dx - 5 then do; lnewretkm5 = .; lnewretkm10 = .;lnewretkm15 = .;lnewretkm20 = .; end;
		run;
		
		/* Compute lead returns for k=+5 to k=+20 as done in Panel A */	
		proc sort data=ret1(drop= ldx lSTOCK_ID); by STOCK_ID descending dx; run; 
		data ret1; set ret1; ldx = lag(dx); lSTOCK_ID = lag(STOCK_ID); run;
		data ret2; set ret1;
		lnewretkp5  = lag(lnewret);  *1-week lead, i.e. k=+5;
		lnewretkp10 = lag2(lnewret); *2-weeks lead, i.e. k=+10;
		lnewretkp15 = lag3(lnewret); *3-weeks lead, i.e. k=+15;
		lnewretkp20 = lag4(lnewret); *4-weeks lead, i.e. k=+20;
		if lSTOCK_ID NE STOCK_ID or ldx NE dx + 5 then do; lnewretkp5 = .; lnewretkp10 = .;lnewretkp15 = .;lnewretkp20 = .; end;
		run;
		proc sort data=ret2; by STOCK_ID dx; run; 
		
		/* Compute stock cumulative lag and lead returns */
		data ret3; set ret2;
		rstock_km20 = (1+lnewretkm20)*(1+lnewretkm15)*(1+lnewretkm10)*(1+lnewretkm5)-1;
		rstock_km15 = (1+lnewretkm15)*(1+lnewretkm10)*(1+lnewretkm5)-1;
		rstock_km10 = (1+lnewretkm10)*(1+lnewretkm5)-1;
		rstock_km5 = lnewretkm5;
		rstock_k0 = lnewretk0; 
		rstock_kp5 = lnewretkp5;
		rstock_kp10 = (1+lnewretkp5)*(1+lnewretkp10)-1;
		rstock_kp15 = (1+lnewretkp5)*(1+lnewretkp10)*(1+lnewretkp15)-1;
		rstock_kp20 = (1+lnewretkp5)*(1+lnewretkp10)*(1+lnewretkp15)*(1+lnewretkp20)-1;
		run;
		
		/* market equally-weighted k-week ahead returns and cumulative returns */
		proc sql;
		create table ret4 as
		select 
			*, 
			/* not cumulative */
			sum(w_mkt*lnewretkm20) as rmkt0_km20, 
			sum(w_mkt*lnewretkm15) as rmkt0_km15, 
			sum(w_mkt*lnewretkm10) as rmkt0_km10, 
			sum(w_mkt*lnewretkm5)  as rmkt0_km5, 
			sum(w_mkt*lnewretk0)   as rmkt0_k0, 
			sum(w_mkt*lnewretkp5)  as rmkt0_kp5, 
			sum(w_mkt*lnewretkp10) as rmkt0_kp10, 
			sum(w_mkt*lnewretkp15) as rmkt0_kp15, 
			sum(w_mkt*lnewretkp20) as rmkt0_kp20, 
			/* cumulative */
			sum(w_mkt*rstock_km20) as rmkt_km20, 
			sum(w_mkt*rstock_km15) as rmkt_km15, 
			sum(w_mkt*rstock_km10) as rmkt_km10, 
			sum(w_mkt*rstock_km5)  as rmkt_km5, 
			sum(w_mkt*rstock_k0)   as rmkt_k0, 
			sum(w_mkt*rstock_kp5)  as rmkt_kp5, 
			sum(w_mkt*rstock_kp10) as rmkt_kp10, 
			sum(w_mkt*rstock_kp15) as rmkt_kp15, 
			sum(w_mkt*rstock_kp20) as rmkt_kp20 
		from
			(select *, 1/COUNT(STOCK_ID) as w_mkt
			from ret3
			group by dx)
		group by dx;
		quit;
	
		/* Market-adjusted weekly portfolio returns and cumulative returns */
		proc sql;
			create table ret5 as
			select 
			*, 
			/* not cumulative */
			sum(w*lnewretkm20)-rmkt0_km20  as r0_km20, 
			sum(w*lnewretkm15)-rmkt0_km15  as r0_km15, 
			sum(w*lnewretkm10)-rmkt0_km10  as r0_km10, 
			sum(w*lnewretkm5) -rmkt0_km5   as r0_km5, 
			sum(w*lnewretk0)  -rmkt0_k0    as r0_k0, 
			sum(w*lnewretkp5) -rmkt0_kp5   as r0_kp5, 
			sum(w*lnewretkp10)-rmkt0_kp10  as r0_kp10, 
			sum(w*lnewretkp15)-rmkt0_kp15  as r0_kp15, 
			sum(w*lnewretkp20)-rmkt0_kp20  as r0_kp20, 
			/* cumulative */
			sum(w*rstock_km20)-rmkt_km20   as r_km20, 
			sum(w*rstock_km15)-rmkt_km15   as r_km15, 
			sum(w*rstock_km10)-rmkt_km10   as r_km10, 
			sum(w*rstock_km5) -rmkt_km5    as r_km5, 
			sum(w*rstock_k0)  -rmkt_k0     as r_k0, 
			sum(w*rstock_kp5) -rmkt_kp5    as r_kp5, 
			sum(w*rstock_kp10)-rmkt_kp10   as r_kp10, 
			sum(w*rstock_kp15)-rmkt_kp15   as r_kp15, 
			sum(w*rstock_kp20)-rmkt_kp20   as r_kp20, 
			monotonic() as n
		from ret4
		group by dx, PTFTYPE&j.
		having max(n) = n;
		quit;
	
		data pe1; set ret5; 
		keep dx PTFTYPE&j. 
			r_km20  r_km15  r_km10  r_km5  r_k0  r_kp5  r_kp10  r_kp15  r_kp20
			r0_km20 r0_km15 r0_km10 r0_km5 r0_k0 r0_kp5 r0_kp10 r0_kp15 r0_kp20;
		if PTFTYPE&j. NE "";
		run;
		proc transpose data = pe1 out = pe2; 
		by dx PTFTYPE&j.;
		var r_km20  r_km15  r_km10  r_km5  r_k0  r_kp5  r_kp10  r_kp15  r_kp20
			r0_km20 r0_km15 r0_km10 r0_km5 r0_k0 r0_kp5 r0_kp10 r0_kp15 r0_kp20;
		run;
		
		proc sort data = pe2; by PTFTYPE&j. _NAME_; run;
		ods select none;
		ods output parameterestimates = nw;
		ods listing close;
		proc model data=pe2; 
		by PTFTYPE&j. _NAME_;
		instrument/intonly;
		col1=a;
		fit col1/gmm kernel=(bart,4,0) vardef=n; 
		run;
		quit;
		ods select all;

		/* organize output */
		data nw; set nw;
		rtyp = "NOT CUMUL";
		/* PANEL A: CUMULATIVE	 */
		if _NAME_ = "r_km20" then do order = 1; rtyp = "CUMUL    "; end;
		if _NAME_ = "r_km15" then do order = 2; rtyp = "CUMUL    "; end;
		if _NAME_ = "r_km10" then do order = 3; rtyp = "CUMUL    "; end;
		if _NAME_ = "r_km5" then do order = 4; rtyp = "CUMUL    "; end;
		if _NAME_ = "r_k0" then do order = 5;  rtyp = "CUMUL    "; end;
		if _NAME_ = "r_kp5" then do order = 6; rtyp = "CUMUL    "; end;
		if _NAME_ = "r_kp10" then do order = 7; rtyp = "CUMUL    "; end;
		if _NAME_ = "r_kp15" then do order = 8; rtyp = "CUMUL    "; end;
		if _NAME_ = "r_kp20" then do order = 9; rtyp = "CUMUL    "; end;
		/* PANEL B: NOT CUMULATIVE	 */
		if _NAME_ = "r0_km20" then order = 1; 
		if _NAME_ = "r0_km15" then order = 2;
		if _NAME_ = "r0_km10" then order = 3;
		if _NAME_ = "r0_km5" then order = 4;
		if _NAME_ = "r0_k0" then order = 5;
		if _NAME_ = "r0_kp5" then order = 6; 
		if _NAME_ = "r0_kp10" then order = 7;
		if _NAME_ = "r0_kp15" then order = 8;
		if _NAME_ = "r0_kp20" then order = 9;
		keep _NAME_ PTFTYPE&j. rtyp order Estimate tValue;
		run;
		proc sort data = nw; by rtyp PTFTYPE&j. order ; run;
		
		/* final output for j=1 Intense Buying & Selling and j=2 Buying & Selling	 */
		data RES_PTF&j. ; set nw; run;
	%end;

%mend;