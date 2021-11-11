*sets i.e time with t0 (tt_0) and time without t0 (tt)
$call csv2gdx csv/Timesteps.csv output=gdx/timesteps.gdx                        id=time autoCol=col colCount=4 index=3 values=3 trace=0 fieldSep=SemiColon decimalSep=Comma
$call csv2gdx csv/Timesteps.csv output=gdx/timesteps_0.gdx                      id=time autoCol=col colCount=4 index=4 values=4 trace=0 fieldSep=SemiColon decimalSep=Comma


**electricity consumption data (in DKK)
$call csv2gdx csv/ElectConsumption.csv output=gdx/par_ElectCons_P4_3_A80.gdx    id=Econ3A80 colCount=9 index=2 values=3 trace=0 fieldSep=SemiColon decimalSep=Comma
$call csv2gdx csv/ElectConsumption.csv output=gdx/par_ElectCons_P4_3_A180.gdx   id=Econ3A180 colCount=9 index=4 values=5 trace=0 fieldSep=SemiColon decimalSep=Comma
$call csv2gdx csv/ElectConsumption.csv output=gdx/par_ElectCons_P4_1_A80.gdx    id=Econ1A80 colCount=9 index=6 values=7 trace=0 fieldSep=SemiColon decimalSep=Comma
$call csv2gdx csv/ElectConsumption.csv output=gdx/par_ElectCons_P4_1_A180.gdx   id=Econ1A180 colCount=9 index=8 values=9 trace=0 fieldSep=SemiColon decimalSep=Comma

**heat consumption data
$call csv2gdx csv/HeatConsumption.csv output=gdx/par_HeatCons_A80.gdx           id=HconA80 colCount=9 index=2 values=3 trace=0 fieldSep=SemiColon decimalSep=Comma
$call csv2gdx csv/HeatConsumption.csv output=gdx/par_HeatCons_A180.gdx          id=HconA180 colCount=9 index=4 values=5 trace=0 fieldSep=SemiColon decimalSep=Comma

**spot price data
$call csv2gdx csv/ElectSpotprices.csv output=gdx/par_ElectSpot.gdx              id=Espotprice colCount=5 index=4 values=5 trace=0 useHeader=y fieldSep=SemiColon decimalSep=Comma


*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Set declaration and definition
*-----------------------------------------------------------------------------------------

Set tt_0 Timesteps with tt0
/
$gdxIn gdx/timesteps_0.gdx
$load tt_0 = Dim1
$gdxIn
/
;

Set tt(tt_0) timesteps without tt0
/
$gdxIn gdx/timesteps.gdx
$load tt = Dim1
$gdxIn
/
;

*Set tt /tt10, tt12, tt13/;

*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Parameter declaration and definition
*-----------------------------------------------------------------------------------------

parameter elect_load_P4_3_A80(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_3_A80.gdx
$load elect_load_P4_3_A80 = Econ3A80
$gdxIn
/
;

parameter elect_load_P4_3_A180(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_3_A180.gdx
$load elect_load_P4_3_A180 = Econ3A180
$gdxIn
/
;

parameter elect_load_P4_1_A80(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_1_A80.gdx
$load elect_load_P4_1_A80 = Econ1A80
$gdxIn
/
;

parameter elect_load_P4_1_A180(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_1_A180.gdx
$load elect_load_P4_1_A180 = Econ1A180
$gdxIn
/
;

parameter heat_load_A80(tt) electricity demand per timestep [kWh_heat]
/
$gdxIn gdx/par_HeatCons_A80.gdx
$load heat_load_A80 = HconA80
$gdxIn
/
;

parameter heat_load_A180(tt) electricity demand per timestep [kWh_heat]
/
$gdxIn gdx/par_HeatCons_A180.gdx
$load heat_load_A180 = HconA180
$gdxIn
/
;

parameter spot_price(tt) spot market price per timestep [� * (kWh_el)^(-1)]
/
$gdxIn gdx/par_ElectSpot.gdx
$load spot_price = Espotprice
$gdxIn
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
         om_boiler       operation and maintainance of heat boiler [� * (kWh)^(-1)] /0.0011/

         taxes_electCons     taxes electricity consumption [� * (kWh)^(-1)] /0.12/
         taxes_electHeat     taxes electricity for heating [� * (kWh)^(-1)] /0.036/
         taxes_gasCons       taxes gas consumption [� * (kWh)^(-1)] /0.04/
         fees_electNetwork   network costs for electricity consumption [� * (kWh)^(-1)] /0/;

*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Variables declaration
*-----------------------------------------------------------------------------------------

Variable

         Z            energy purchase cost [� * (kWh)^(-1)];

Positive Variable
         x_el_grid(tt) electricity from grid [kWh_el]
         x_th_boil(tt) output of heat boiler [kWh_th];
         
Binary Variable
        u
        y;
        

        
        

*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Equations declaration
*-----------------------------------------------------------------------------------------

equation costs;
equation elecdemand(tt) summaraizes entire electricity (kWh) demand;
equation heatdemand(tt) summaraizes entire heat (kWh) demand;



costs.. Z =e= sum(tt, (( (0.001*spot_price(tt)) + taxes_electCons ) * x_el_grid(tt)) + ( (om_boiler + taxes_gasCons + cost_gas) * x_th_boil(tt)));
elecdemand(tt).. x_el_grid(tt) =g= elect_load_P4_3_A80(tt);
heatdemand(tt).. x_th_boil(tt) =g= heat_load_A80(tt);





Model energy /all/;
*Model energy /costs, elecdemand/ ;
option mip=cplex;
*solve energy using mip maximizing Z;
solve energy using mip minimizing Z;
*Display f.l, x_el_grid.l, x_th_boil.l;
display z.l;
* x_el_grid.l, elect_load_P4_3_A80, spot_price;

