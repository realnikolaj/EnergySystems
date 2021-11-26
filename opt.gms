*sets i.e time with t0 (tt_0) and time without t0 (tt)
$call csv2gdx csv/Timesteps.csv output=gdx/timesteps.gdx                        id=time autoCol=col colCount=1 index=1 values=1 trace=0 fieldSep=SemiColon decimalSep=Comma
$call csv2gdx csv/TimestepsFull.csv output=gdx/timestepsfull.gdx                id=time autoCol=col colCount=4 index=1 values=1 trace=0 fieldSep=SemiColon decimalSep=Comma


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

**solar radiation data
$call csv2gdx csv/SolarRadiation.csv output=gdx/par_SolarRadiation.gdx              id=SolarRadiation colCount=2 index=1 values=2 trace=0 useHeader=n fieldSep=SemiColon decimalSep=Comma

*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Set declaration and definition
*-----------------------------------------------------------------------------------------
SETS t timesteps full year
/
$gdxIn gdx/timestepsfull.gdx
$load t = Dim1
$gdxIn
/;

ALIAS(t, ts);
SETS tt(ts) Timesteps subset using the selected weeks
/
$gdxIn gdx/timesteps.gdx
$load tt = Dim1
$gdxIn
/
;

SETS i Type of Supply
/Elect, Elect-heat, Gas-boiler, Photovoltaic, Heat-pump, Battery, Heat-storage/;

ALIAS(i,j);
SETS isub(j) Defines subset of actual tech in use for scenario
/Elect, Elect-heat,Gas-boiler,Photovoltaic,heat-pump/;
*, Photovoltaic /;  Elect-heat
*/Gas-boiler,  Heat-pump, Battery, Heat-storage/;


SETS ci Type of costs for generation
/cost, om, taxes, fees/;




*Set k Effeciencies;
*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Parameter declaration and definition
*-----------------------------------------------------------------------------------------

PARAMETER elect_load_P4_3_A80(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_3_A80.gdx
$load elect_load_P4_3_A80 = Econ3A80
$gdxIn
/
;

PARAMETER elect_load_P4_3_A180(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_3_A180.gdx
$load elect_load_P4_3_A180 = Econ3A180
$gdxIn
/
;

PARAMETER elect_load_P4_1_A80(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_1_A80.gdx
$load elect_load_P4_1_A80 = Econ1A80
$gdxIn
/
;

PARAMETER elect_load_P4_1_A180(tt) electricity demand per timestep [kWh_el]
/
$gdxIn gdx/par_ElectCons_P4_1_A180.gdx
$load elect_load_P4_1_A180 = Econ1A180
$gdxIn
/
;

PARAMETER heat_load_A80(tt) electricity demand per timestep [kWh_heat]
/
$gdxIn gdx/par_HeatCons_A80.gdx
$load heat_load_A80 = HconA80
$gdxIn
/
;

PARAMETER heat_load_A180(tt) electricity demand per timestep [kWh_heat]
/
$gdxIn gdx/par_HeatCons_A180.gdx
$load heat_load_A180 = HconA180
$gdxIn
/
;

PARAMETER spot_price(tt) spot market price per timestep [� * (kWh_el)^(-1)]
/
$gdxIn gdx/par_ElectSpot.gdx
$load spot_price = Espotprice
$gdxIn
/
;

PARAMETER solar_rad(tt) solar radiation per timestep [� * (kWh_el)^(-1)]
/
$gdxIn gdx/par_SolarRadiation.gdx
$load solar_rad = SolarRadiation
$gdxIn
/
;

*display tt, solar_rad;
*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Scalar declaration and definition
*-----------------------------------------------------------------------------------------

SCALAR
         time_step       smallest time step [h] /1/
         num_weeks       number of weeks per year considered /4/
         
         pv_kw           size of PV unit i.e. Max Capacity in kW /20/
         pump_kw         size of Heat pump unit i.e. Max Capacity in kW /20/
         boiler_kw       size of Gas boiler unit i.e. Max Capacity in kW /20/
         battery_kw      size of battery unit i.e. Max Capacity in kW /20/
         heat_stor_kw    size of Heat storage unit i.e. Max Capacity in kW /20/
         

         cost_gas        cost of natural gas [� * (kWh)^(-1)] /0.09/
         om_boiler       operation and maintainance of heat boiler [� * (kWh)^(-1)] /0.0011/
         om_pump         operation and maintainance of gas boiler [� * (kWh)^(-1)]  /0.0027/
         

         taxes_electCons     taxes electricity consumption [� * (kWh)^(-1)] /0.12/
         taxes_electHeat     taxes electricity for heating [� * (kWh)^(-1)] /0.036/
         taxes_gasCons       taxes gas consumption [� * (kWh)^(-1)] /0.04/
         fees_electNetwork   network costs for electricity consumption [� * (kWh)^(-1)] /0/;

PARAMETER  sp(tt)  Electricity Spot prices in per kWh not per MWh;
sp(tt) = spot_price(tt) / 1000;

PARAMETER kw(i) Maximum capacity i.e. size of unit in kWh
/Elect 0
Elect-heat 0
Gas-boiler 20
Photovoltaic 20
Heat-pump 18
Battery 55
Heat-storage 15/;


PARAMETER cap_cost(i) Capitol cost in Euro per kW per year
/Elect 0
Elect-heat 0
Gas-boiler 2.55
Photovoltaic 33.63
Heat-pump 56.08
Battery 53.65
Heat-storage 14.07/;

PARAMETER  capitalCosts(i)  Capital costs;
capitalCosts(i) = ( cap_cost(i) * kw(i) );


TABLE   a(ci,i)    
                    Elect   Elect-heat   Gas-boiler   Photovoltaic   Heat-pump   Battery   Heat-storage           
cost                0       0            0.09         0              0           0         0
om                  0       0            0.0011       0              0.0027      0.0021    0.0007
taxes               0.12    0.036        0.04         0              0           0         0
fees                0       0            0            0              0           0         0;

Parameter
         x_Results variable to display how much each technology is used over the 4 weeks [kWh];

*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Variables declaration
*-----------------------------------------------------------------------------------------

Binary Variable
        bi_tech(i);


Variable
         Z            energy purchase cost [� * (kWh)^(-1)];

*Positive Variable
*         x_el_grid(tt) electricity from grid [kWh_el]
*         x_th_boil(tt) output of heat boiler [kWh_th]
*         x_el_pv(tt)   electircity from PV [kWh_el]
*         x_th_pump(tt) output of heat pump [kWh_th]
         
Positive Variable
         x(tt,i);        
*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Equations declaration
*-----------------------------------------------------------------------------------------

equation costs;
equation elecdemand(tt) summaraizes entire electricity (kWh) demand;
equation heatdemand(tt) summaraizes entire heat (kWh) demand;
equation pvproduction(tt) Max pv production (kW);
equation pvcapacity(tt) Max capacity of PV (kW);
*equation boilcapacity(tt) Max capacity of heat boiler (kW);
equation heatpumpchoice(tt) force Elect-heat and 'Peatpump' as one choice;
equation heatpumpchoice2 force Elect-heat and 'Peatpump' as one choice;
****** using a(ci,isub) *************
*costs.. Z =e= sum(isub,capitalCosts(isub)*bi_tech(isub))
*              + sum(tt, sp(tt)*x(tt,'Elect'))
*              + sum((tt,ci), sum(isub,(a(ci,isub))*x(tt,isub)));
        
***** adding heat-pump **************      
costs.. Z =e= sum(isub,capitalCosts(isub)*bi_tech(isub))
              + sum(tt, sp(tt)*(x(tt,'Elect')+x(tt,'Elect-heat')))
              + sum((tt,ci), sum(isub,(a(ci,isub))*x(tt,isub)));

elecdemand(tt).. x(tt,'Elect') + x(tt,'Photovoltaic') =g= elect_load_P4_3_A80(tt);
heatdemand(tt).. x(tt,'Gas-boiler') + 2.9*x(tt,'Elect-heat')=g= heat_load_A80(tt);
pvproduction(tt).. x(tt,'Photovoltaic') =l= solar_rad(tt)*bi_tech('Photovoltaic');
pvcapacity(tt).. x(tt,'Photovoltaic') =l= kw('Photovoltaic')*bi_tech('Photovoltaic');
heatpumpchoice(tt).. x(tt,'Elect-heat') =l= 1000000000*bi_tech('Heat-pump');
heatpumpchoice2.. bi_tech('Elect-heat') =e= bi_tech('Heat-pump');

* missing electric heat from pv panel.

****** Grid electricity and Gas-boiler is always available *********
bi_tech.fx('Elect') = 1;
bi_tech.fx('Gas-boiler') = 1;

******** Custom Edits ************

*capitalCosts('Heat-pump')= 0;
*capitalCosts('Photovoltaic') =0;
*bi_tech.fx('Photovoltaic') = 0;
*bi_tech.fx('Elect-heat') = 0; bi_tech.fx('Heat-pump') = 0;

******** Solver ***************
Model energy /all/;
option mip=cplex;
solve energy using mip minimizing Z;

x_Results(isub) = sum(tt,x.l(tt,isub));

display Z.l,x.l, bi_tech.l,x_Results;
