%macro M_DS4REG(DSIN=);
	
	* Prepare Weekly Trading and Return Data;
	data hft(rename=(Mroibvol=oibvol Mroibtrd=oibtrd)); set &DSIN; by STOCK_ID dx;
	lSTOCK_ID = lag4(STOCK_ID);
	ldx = lag4(dx);
	run;
	
	* Day t, t-1, t-2, t-3 and t-4 ;
	data lx; set hft; by STOCK_ID dx;
	loibvol = oibvol + lag(oibvol) + lag2(oibvol) + lag3(oibvol) + lag4(oibvol);
	loibtrd = oibtrd + lag(oibtrd) + lag2(oibtrd) + lag3(oibtrd) + lag4(oibtrd);
	lnewret = newret + lag(newret) + lag2(newret) + lag3(newret) + lag4(newret);
	lret    = ret + lag(ret) + lag2(ret) + lag3(ret) + lag4(ret);
	if lSTOCK_ID NE STOCK_ID or ldx NE dx - 4 then do; loibvol = .; loibtrd=.; lnewret=.; lret=.; end;
	keep STOCK_ID dx loibvol loibtrd lnewret lret;
	run;
	
	* Day t+1, t+2, t+3, t+4, and t+5;
	data fy; set lx;
	dx = dx - 5;
	foibvol = loibvol;
	foibtrd = loibtrd;
	fnewret = lnewret;
	fret = lret;
	keep STOCK_ID dx foibvol foibtrd fnewret fret;
	run;
	
	proc sort data = lx  nodupkey; by STOCK_ID dx;
	proc sort data = fy  nodupkey; by STOCK_ID dx;
	proc sort data = hft nodupkey; by STOCK_ID dx;
	run;
	data DS4REG; merge hft(in = ina) fy lx; 
	by STOCK_ID dx;
	if ina;
	run;
	
	/* keep final output only */
	proc delete data=hft lx fy; run;

%mend;