
/*Run cleaning dofile for CES analysis with ratings and lineups*/
do 01_data_prep/03_build_analysis_data.do

/* Run analysis do-files*/
do 02_analysis/Table_1.do
do 02_analysis/Table_2_PanelA.do
do 02_analysis/Table_2_PanelB.do

do 02_analysis/Figure_1.do
