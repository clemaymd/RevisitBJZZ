#### 2025-07-25

## Overview

This README file provides information about the data and the computer code used to generate the results presented in Ardia et al. (2025), **Revisiting Boehmer et al. (2021): Recent Period, Alternative method, Different Conclusions.**

By using the code, you agree to the following rules:

- You must cite the paper in working papers and published papers that use the code.
- You must place the DOI of this data/code repository in a footnote to help others find it.
- You assume all risk for the use of the code.

All datasets are proprietary. We do not have the rights to share any of the data. We provide pseudo data to illustrate the code usage. 

The computer code is written in SAS and allows for replicating all tables presented in the paper. It also includes our implementation of the Quote MidPoint (QMP) approach, as advocated by Barber et al. (2024).

## Main Folder

The file `ALL.sas` is a wrapper program that allows replicating all tables and figures in the paper.
The files `TAB1.sas` to `TAB13.sas` are second-layer wrapper programs allowing to obtain all or selected parts of Tables 1 to 13, respectively.
Specifically, the replicator can obtain a specific panel by defining the macro-variables `RTMD` and `period`. She can also run results based on specific parameters of the regression (e.g., bid-ask returns (`newret`) or CRSP returns (`ret`), `mroibvol` or `mroibtrd`, specific horizon, etc.)
The file `FIG1.sas` allows to obtain Figure 1.

## Macros Folder

The macro `M_DS4REG.sas` prepares initial input for replicating Tables 2 to 13. It is called in `TAB2.sas` to `TAB13.sas` programs.
The macros `M_TAB2n3.sas` to `M_TAB13.sas` contain the core of the code replicating Tables 2 and 3 to 13, respectively. They are called in `TAB2.sas` and `TAB3.sas` to `TAB13.sas` programs, respectively.

## Data Folder

The data files `pseudods_bjzz.sas7bdat`, `pseudods_qmp.sas7bdat` and `pseudods_4spread.sas7bdat` are pseudo-data sets that illustrate the format of the files read by the programs in the main folder.

- Panel data: 300 stocks x 1007 trading days, corresponding to two years of pseudo data for each 2010-2015 and 2016-2021 period.

- Variables description (see also Table A of our paper):

  * Retail-trade variables:
	* `mrbvol`: marketable retail buy volume based on shares traded
	* `mrsvol`: marketable retail sell volume based on shares traded
	* `mrbtrd`: marketable retail number of buy trades
	* `mrstrd`: marketable retail number of sell trades
	* `mroibvol`: marketable retail order imbalance based on shares traded
	* `mroibtrd`: marketable retail order imbalance based on number of trades
	* Note that for the `pseudods_4spread.sas7bdat`, both BJZZ-based and QMP-based variables are included.
	
  * Non-retail-trade variables:
	* `newret`: bid-ask return
	* `ret`: CRSP return
	* `lmret`: last-month return
	* `l6mret`: previous six-month return before the last month
	* `lvolnewret`: last-month volatility of daily bid-ask returns
	* `lvolret`: last-month volatility of daily CRSP returns
	* `lto`: last-month-end turnover (reported as 'lmto' in the paper)
	* `size`: last-month-end logarithm of market value
	* `lbm`: last-month-end logarithm of book-to-market ratio
	
  * Others:
	* `DATE`: pseudo-date in YYYYMMDD format
	* `dx`: trading day index
	* `STOCK_ID`: stock identification index
	* `lmp`: pseudo last-month-price (used in share-price subgroups analyses)

The data file `ff.sas7bdat` contains information on Fama-French 3-factor series modified for our purpose. Original data comes from Kenneth R. French's website. This file is read by the `TAB6.sas` and `TAB13.sas` programs.

## Outputs and Outputs_paper Folders

The folder `Outputs` is populated when files `TAB1.sas` to `TAB13.sas` and `FIG1.sas` are run; content is overwritten with each run. **Since these outputs are based on pseudo data sets, they do NOT correspond to the results in the paper**.
The folder `Outputs_paper` is populated when files `TAB1.sas` to `TAB13.sas` and `FIG1.sas` are run using our original data sets as input. They correspond to results reported in the paper.

## QuoteMidpoint Folder

This folder relates to our implementation of the QMP approach. This folder is self-contained for researchers solely interested in this aspect.

The file `Compute_RTQ_QMP.sas` identifies and signs retail trades with the QMP approach and computes daily-aggregated retail-trade quantities. See the README.md specific to this folder for more details.

The data file `pseudo_taqsymlist.sas7bdat` is an illustrative list of TAQ symbols (SYM_ROOT and SYM_SUFFIX) defining the stock universe.

An output file named `rtq_qmp.sas7bdat` is saved after each run, and any previous content will be overwritten.

## End notes

This folder does not allow for the reproduction of Table 9 in the paper, as that table was produced manually and does not rely on any data.

Some outputs generated using the pseudo data may contain errors due to specific limitations of the pseudo dataset (e.g., insufficient number of observations).

## References

Ardia D., Aymard C., and Cenesizoglu T. 2025. Revisiting Boehmer et al. (2025): Recent Period, Alternative method, Different Conclusions. Forthcoming in Financial Markets and Portfolio Management. https://ssrn.com/abstract=4703056

Barber B. M., Huang X., Jorion P., Odean T., and Schwarz C. 2024. A (Sub)penny For Your Thoughts: Tracking Retail Investor Activity in TAQ. Journal of Finance 79:2403. https://doi.org/10.2139/ssrn.4202874

Boehmer E., Jones C.M., Zhang X., and Zhang X. 2021. Tracking retail investor activity. Journal of Finance 76:2249. https://doi.org/10.1111/jofi.13033 
