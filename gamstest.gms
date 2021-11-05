*-----------------------------------------------------------------------------------------
* #Assignment 2021 - Course 42002#
*-----------------------------------------------------------------------------------------
* * Group:              Number
* * Author(s):          Name 1, Name 2, Name 3
*-----------------------------------------------------------------------------------------

* Input from Excel File´
*-----------------------------------------------------------------------------------------
*sets
$call =xls2gms   r="Timesteps"!C3:C8762          i=Data_GroupWork.xlsx    o=set_tt.inc
$call =xls2gms   r="Timesteps"!D2:D8762          i=Data_GroupWork.xlsx    o=set_tt_0.inc

*electricity consumption data
$call =xls2gms   r="ElectConsumption"!B6:C8765   i=Data_GroupWork.xlsx    o=par_ElectCons_P4_3_A80.inc
$call =xls2gms   r="ElectConsumption"!D6:E8765   i=Data_GroupWork.xlsx    o=par_ElectCons_P4_3_A180.inc
$call =xls2gms   r="ElectConsumption"!F6:G8765   i=Data_GroupWork.xlsx    o=par_ElectCons_P4_1_A80.inc
$call =xls2gms   r="ElectConsumption"!H6:I8765   i=Data_GroupWork.xlsx    o=par_ElectCons_P4_1_A180.inc

*heat consumption data
$call =xls2gms   r="HeatConsumption"!B4:C8763   i=Data_GroupWork.xlsx    o=par_HeatCons_A80.inc
$call =xls2gms   r="HeatConsumption"!D4:E8763   i=Data_GroupWork.xlsx    o=par_HeatCons_A180.inc

*spot price data
$call =xls2gms   r="ElectSpotPrices"!D2:E8761   i=Data_GroupWork.xlsx    o=par_ElectSpot.inc


*-----------------------------------------------------------------------------------------
* Set declaration and definition
*-----------------------------------------------------------------------------------------
set tt_0   timesteps (including tt0)
/
$include set_tt_0.inc
/
;

set tt(tt_0)  timesteps (without tt0)
/
$include set_tt.inc
/
;
*-----------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------
* Parameter declaration and definition
*-----------------------------------------------------------------------------------------

parameter elect_load_P4_3_A80(tt) electricity demand per timestep [kWh_el]
/
$include par_ElectCons_P4_3_A80.inc
/
;

parameter elect_load_P4_3_A180(tt) electricity demand per timestep [kWh_el]
/
$include par_ElectCons_P4_3_A180.inc
/
;

parameter elect_load_P4_1_A80(tt) electricity demand per timestep [kWh_el]
/
$include par_ElectCons_P4_1_A80.inc
/
;

parameter elect_load_P4_1_A180(tt) electricity demand per timestep [kWh_el]
/
$include par_ElectCons_P4_1_A180.inc
/
;

parameter heat_load_A80(tt) electricity demand per timestep [kWh_heat]
/
$include par_HeatCons_A80.inc
/
;


parameter heat_load_A180(tt) electricity demand per timestep [kWh_heat]
/
$include par_HeatCons_A180.inc
/
;

parameter spot_price(tt) spot market price per timestep [� * (kWh_el)^(-1)]
/
$include par_ElectSpot.inc
/
;
*-----------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------
* Scalar declaration and definition
*-----------------------------------------------------------------------------------------

Scalar
         time_step       smallest time step [h] /1/
         num_weeks       number of weeks per year considered /9/

         cost_gas        cost of natural gas [� * (kWh)^(-1)] /0.09/

         taxes_electCons     taxes electricity consumption [� * (kWh)^(-1)] /0.12/
         taxes_electHeat     taxes electricity for heating [� * (kWh)^(-1)] /0.036/
         taxes_gasCons       taxes gas consumption [� * (kWh)^(-1)] /0.04/
         fees_electNetwork   network costs for electricity consumption [� * (kWh)^(-1)] /0/

*-----------------------------------------------------------------------------------------
* Variables declaration
*-----------------------------------------------------------------------------------------

Variable

         Z            energy purchase cost [� * (kWh)^(-1)];

Positive Variable
         x_el_grid(tt) electricity from grid [kWh_el]
         x_th_boil(tt) output of heat boiler [kWh_th]


*-----------------------------------------------------------------------------------------
* Equations declaration
*-----------------------------------------------------------------------------------------





*Model energy /all/ ;
*option mip=cplex;
*solve energy using mip maximizing Z;
*Display f.l, x_el_grid.l, x_th_boil.l;

