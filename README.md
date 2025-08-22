
## Data access
The dataset used in the analysis is confidential and, therefore, is not provided.
The data are kept at the facilities of the Bank of Lithuania. Researchers can apply for the visit program and obtain access to the dataset (https://www.lb.lt/en/ca-visiting-researcherprogramme).

## Replication files
The full set of results can be obtained by running the 

The full set of results can be obtained by running the `0_master.do` program. This program includes built-in programs and additional sub-files:

* `01_monthlypanel.do`                                                            - imports raw data files and generates a monthly panel to use in the analysis
* `2_desc.do` + `2a_desc.do`                                                      - generates descriptive statistics for main text and appendix
* `3_fortin.do.do` + `3a_visualeffects_deflator.do`  + `3b_marginal_effects.do`   - estimates Fortin et al. (2021) and visualizes the impact of different deflators on the estimates and marginal effects
* `4a_reweighting_realdist.do`  + `4b_counterfactual_realdist.do`                 - computes reweighting factors and generates counterfactual distributions in real terms
* `5a_reweighting_nominaldist.do`  + `5b_counterfactual_nominaldist.do`           - computes reweighting factors and generates counterfactual distributions in nominal terms 
* `6_inequality_measures` + `6a_inequality_measures_nominal.do`                   - quantifies minimum wage contribution to inequality and wage growth



