# Replication code for "Imported Inputs and Productivity". Please cite as
#	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

GRAPH 			= wrap.ado counterfactual.do ../data/simulated_fixedcosts.dta load_fixed_costs.do filename_parser.py
ESTIMATE_FIRST 	= estimate_specification.do estimate_Gn.do prepare_for_estimation.do run_the_estimation.do ../data/impmanuf.dta 
ESTIMATE_LATER 	= estimate_specification.do estimate_Gn.do run_the_estimation.do
ESTIMATE_CMD	= $(STATA) do estimate_specification $(lastword $(subst /, ,$(dir $@))) $(notdir $(basename $@))
ESTIMATE_CMD_1	= $(STATA) do estimate_specification $(lastword $(subst /, ,$(dir $@))) 0
# set your stata executable here
STATA 			= stata-se -b
ESTIMATES_DIR 	= ../doc/mapreduce
GRAPHS_DIR		= ../text/graphs
TABLES_DIR		= ../text/tables
LOG_DIR			= ../doc
DATA_DIR		= ../data
CODE_DIR		= .
FIVE_HUNDRED	= $(shell seq 1 500)
FIVE_HUNDRED_1	= $(shell seq 0 500)
SECTORS			= 15 18 20 22 25 26 28 29 33
SPECIFICATIONS	= table3_baseline table3_exporter table3_importedbefore table3_lag_Gn table4_foreign table4_exporter table4_importedbefore table4_lag_Gn table5_year $(foreach sector,$(SECTORS),table6_nace$(sector))

TAU = $(shell seq -f "%1.2f" -0.1 0.02 0.5)
COMPLEMENTARITY = 0 1 2  
FOREIGNPRESENCE = 0 1 2
OFFSET = -1.0986 0 1.0986

.PHONY: all descriptives table3 table4 table5 table6 fixedcost simulate save graphs create_tables

all: descriptives create_tables graphs 

descriptives: estimate $(LOG_DIR)/descriptives.log $(LOG_DIR)/numbers-in-text.log

$(LOG_DIR)/descriptives.log: descriptives.do load_specification.do 
	$(STATA) do descriptives.do

$(LOG_DIR)/numbers-in-text.log: numbers-in-text.do ../data/impmanuf.dta $(ESTIMATES_DIR)/table3_baseline/0.csv $(ESTIMATES_DIR)/table5_year/estimates.csv
	$(STATA) do numbers-in-text

estimate: table3 table4 table5 table6
	touch $@

table3: $(ESTIMATES_DIR)/table3_exporter/estimates.csv $(ESTIMATES_DIR)/table3_baseline/estimates.csv $(ESTIMATES_DIR)/table3_importedbefore/estimates.csv $(ESTIMATES_DIR)/table3_lag_Gn/estimates.csv

table4: $(ESTIMATES_DIR)/table4_foreign/estimates.csv $(ESTIMATES_DIR)/table4_exporter/estimates.csv $(ESTIMATES_DIR)/table4_importedbefore/estimates.csv $(ESTIMATES_DIR)/table4_lag_Gn/estimates.csv

table5: $(ESTIMATES_DIR)/table5_year/estimates.csv

table6: $(foreach sector,$(SECTORS),$(ESTIMATES_DIR)/table6_nace$(sector)/estimates.csv)

$(ESTIMATES_DIR)/%/estimates.csv $(ESTIMATES_DIR)/%/reduced.csv: $(foreach file,$(FIVE_HUNDRED_1),$(ESTIMATES_DIR)/%/$(file).csv) ../doc/variable_order.csv reducer.do sterrors.do
	$(STATA) do reducer $(lastword $(subst /, ,$(dir $@)))

# point estimates
$(ESTIMATES_DIR)/table6_nace%/0.csv $(ESTIMATES_DIR)/table6_nace%/inputfile.dta: $(ESTIMATE_FIRST) map/table6_nace.do
	$(ESTIMATE_CMD_1)

$(ESTIMATES_DIR)/%/0.csv $(ESTIMATES_DIR)/%/inputfile.dta: $(ESTIMATE_FIRST) map/%.do
	$(ESTIMATE_CMD_1)

# 500 repetitions for bootstrap
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table3_baseline/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table3_baseline/inputfile.dta map/table3_baseline.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table3_exporter/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table3_exporter/inputfile.dta  map/table3_exporter.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table3_importedbefore/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table3_importedbefore/inputfile.dta map/table3_importedbefore.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table3_lag_Gn/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table3_lag_Gn/inputfile.dta map/table3_lag_Gn.do map/table3_exporter.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table4_foreign/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table4_foreign/inputfile.dta map/table4_foreign.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table4_exporter/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table4_exporter/inputfile.dta map/table4_exporter.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table4_importedbefore/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table4_importedbefore/inputfile.dta map/table4_importedbefore.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table4_lag_Gn/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table4_lag_Gn/inputfile.dta map/table4_lag_Gn.do map/table4_exporter.do
	$(ESTIMATE_CMD)
$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table5_year/$(file).csv): $(ESTIMATE_LATER) ../doc/mapreduce/table5_year/inputfile.dta map/table5_year.do
	$(ESTIMATE_CMD)
$(foreach sector,$(SECTORS),$(foreach file,$(FIVE_HUNDRED),$(ESTIMATES_DIR)/table6_nace$(sector)/$(file).csv)): $(ESTIMATE_LATER) $(foreach sector,$(SECTORS),../doc/mapreduce/table6_nace$(sector)/inputfile.dta) map/table6_nace.do
	$(ESTIMATE_CMD)

fixedcost: $(LOG_DIR)/fixedcost.log $(DATA_DIR)/fixed_cost_mu_estimates.csv $(DATA_DIR)/simulated_fixedcosts.dta $(TABLES_DIR)/table7-fixed-costs.csv $(GRAPHS_DIR)/fixed_cost_function.gph

$(GRAPHS_DIR)/fixed_cost_function.gph $(TABLES_DIR)/table7-fixed-costs.csv $(LOG_DIR)/fixedcost.log $(DATA_DIR)/fixed_cost_mu_estimates.csv $(DATA_DIR)/simulated_fixedcosts.dta: $(CODE_DIR)/fixedcost.do $(CODE_DIR)/load_specification.do $(CODE_DIR)/simulate_entry.do $(ESTIMATES_DIR)/table4_foreign/0.csv
	$(STATA) do fixedcost

simulate: $(GRAPHS_DIR)/offset_tfp_gain.gph $(GRAPHS_DIR)/foreignpresence_tfp_gain.gph $(GRAPHS_DIR)/complementarity_change_in_domestic_inputs.gph 

grid: $(foreach logtau,$(TAU),$(foreach foreignpresence,$(FOREIGNPRESENCE),$(foreach offset,$(OFFSET),../doc/simulations/use+logtau~$(logtau)+complementarity~1+foreignpresence~$(foreignpresence)+offset~$(offset)+global+specification+table4_foreign.csv))) $(foreach logtau,$(TAU),$(foreach complementarity,$(COMPLEMENTARITY),../doc/simulations/use+logtau~$(logtau)+complementarity~$(complementarity)+foreignpresence~1+offset~0+global+specification+table3_baseline.csv))
	touch $@
../doc/simulations/use%.csv: $(GRAPH)
	python filename_parser.py $@ : do counterfactual
$(GRAPHS_DIR)/offset_tfp_gain.gph: grid collapse-and-draw-graph.do
	$(STATA) do collapse-and-draw-graph.do table4_foreign offset tfp_gain complementarity==1 foreignpresence==1
$(GRAPHS_DIR)/foreignpresence_tfp_gain.gph: grid collapse-and-draw-graph.do
	$(STATA) do collapse-and-draw-graph.do table4_foreign foreignpresence tfp_gain complementarity==1 offset==0
$(GRAPHS_DIR)/complementarity_change_in_domestic_inputs.gph: grid collapse-and-draw-graph.do
	$(STATA) do collapse-and-draw-graph.do table3_baseline complementarity change_in_domestic_inputs offset==0 foreignpresence==1
$(GRAPHS_DIR)/switcher_event_study_omegastar.gph: switcher_event_study.do load_specification.do $(ESTIMATES_DIR)/table3_baseline/0.csv 
	$(STATA) do switcher_event_study

create_tables: estimate $(TABLES_DIR)/table2-import-margins.csv $(TABLES_DIR)/table2longrun-import-margins.csv $(foreach table,3 4 5 6,$(TABLES_DIR)/table$(table)-regression.csv) $(TABLES_DIR)/table7-fixed-costs.csv $(TABLES_DIR)/table8-decomposition.csv $(TABLES_DIR)/table9-top.csv $(TABLES_DIR)/table9-bottom.csv

$(TABLES_DIR)/table2-import-margins.csv: import_margins.do $(ESTIMATES_DIR)/table3_baseline/0.csv ../data/impmanuf.dta
	$(STATA) do import_margins
$(TABLES_DIR)/table2longrun-import-margins.csv: import_margins.do $(ESTIMATES_DIR)/table3_baseline/0.csv ../data/impmanuf.dta
	$(STATA) do import_margins longrun

$(TABLES_DIR)/table8-decomposition.csv: decomposition.do $(ESTIMATES_DIR)/table5_year/0.csv
	$(STATA) do decomposition

$(TABLES_DIR)/table%-regression.csv: estimate $(CODE_DIR)/write_results_to_excel.py
	python write_results_to_excel.py $(notdir $(basename $@)) > $@

$(TABLES_DIR)/table9-bottom.csv $(TABLES_DIR)/table9-top.csv: table9.do $(GRAPHS_DIR)/offset_tfp_gain.gph $(GRAPHS_DIR)/foreignpresence_tfp_gain.gph
	$(STATA) do table9

save_results: $(ESTIMATES_DIR)/*/*.csv ../doc/simulations/use+*.csv ../text/tables/table*.csv ../text/graphs/*.gph
	git add -f $?
	git commit -m "AUTOCOMMIT: estimation, bootstrap and simulation results"
	git push srv master
	touch $@

graphs: estimate $(foreach i,1 2 3 4 5,$(GRAPHS_DIR)/figure$(i).pdf)
$(foreach i,1 2 3 4 5,$(GRAPHS_DIR)/figure$(i).pdf): all_graphs.do $(ESTIMATES_DIR)/table3_baseline/0.csv ../data/impmanuf.dta $(ESTIMATES_DIR)/table4_foreign/0.csv $(GRAPHS_DIR)/complementarity_change_in_domestic_inputs.gph $(GRAPHS_DIR)/switcher_event_study_omegastar.gph $(GRAPHS_DIR)/fixed_cost_function.gph
	$(STATA) do all_graphs