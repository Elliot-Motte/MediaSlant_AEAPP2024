
/*Run data preparation dofile (common to appendix and main analysis)*/
do 01_data_prep/03_build_analysis_data.do

/* Run analysis do-files for appendix Tables*/
do 03_appendix/Table_A2.do
do 03_appendix/Table_A3.do
