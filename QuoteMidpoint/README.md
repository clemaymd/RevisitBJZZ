#### 2025-07-25 

## Overview

This README file provides information about the implementation of the QMP approach as described in Barber et al. (2023) implemented in Ardia et al. (2024), **Revisiting Boehmer et al. (2021): Recent Period, Alternative method, Different Conclusions**. 

By using the code, you agree to the following rules:

- You must cite the paper in working papers and published papers that use the code.
- You must place the DOI of this data/code repository in a footnote to help others find it.
- You assume all risk for the use of the code.

The computer code is written in SAS and intended for use on the WRDS server.

## Code

The file `Compute_RTQ_QMP.sas` identifies and signs retail trades with the QMP approach and computes daily-aggregated retail-trade quantities. See the comment section in the file for more details.

## Data

The data file `pseudo_taqsymlist.sas7bdat` is an illustrative list of TAQ symbols (SYM_ROOT and SYM_SUFFIX) defining the stock universe.

## Output

An output file named `rtq_qmp.sas7bdat` is saved after each run, and any previous content will be overwritten.

## References

Ardia D., Aymard C., and Cenesizoglu T. 2024. Revisiting Boehmer et al. (2021): Recent Period, Alternative method, Different Conclusions. Working paper. https://ssrn.com/abstract=4703056

Barber B. M., Huang X., Jorion P., Odean T., and Schwarz C. 2023. A (Sub)penny For Your Thoughts: Tracking Retail Investor Activity in TAQ. Forthcoming in the Journal of Finance. https://doi.org/10.2139/ssrn.4202874
