*calling Data parameters and timeset
$call csv2gdx csv/TimeSeries_dat.csv output=gdx/TimeSeries_dat.gdx          id=dataPar index=1 values=2,3,4,5,6,7,8,10 useHeader=y fieldSep=SemiColon decimalSep=Comma storeZero=y
$call csv2gdx csv/TimeSeries_dat.csv output=gdx/agr_TimeSeries.gdx          id=agrTime index=9 useHeader=y fieldSep=SemiColon decimalSep=Comma storeZero=y

SETS  t timesteps full year
*      tt Time subset 
      scen house size and income scenarios
    

scen /1A80, 1A180, 3A80, 3A180/;


*$gdxIn gdx/TimeSeries_dat.gdx
*$load t  = Dim1
*$gdxIn
*;

*SET ts(t) timesteps without;
*ts('tt0') = no


PARAMETERS
    dataPar
    elect_load(scen, t)
    heat_load(scen, t)
    spot_price(t)
    solar_rad(t);
    
$onUndf
$gdxIn gdx/TimeSeries_dat.gdx
$load t = Dim1
$load dataPar
$gdxIn

*ALIAS(t, tt);

* Timesteps subset using the selected weeks
ALIAS(t, ts);
SETS tt(ts);
* /tt1*tt5/;
*
$gdxIn gdx/agr_TimeSeries.gdx
$load tt = Dim1
$gdxIn
;

elect_load('1A80', t)  = dataPar(t,'el1A80');
elect_load('1A180',t)  = dataPar(t,'el1A180');
elect_load('3A80', t)  = dataPar(t,'el3A180');
elect_load('3A180',t)  = dataPar(t,'el3A180');
heat_load('1A80',  t)  = dataPar(t,'thA80');
heat_load('1A180', t)  = dataPar(t,'thA180');
heat_load('3A80',  t)  = dataPar(t,'thA80');
heat_load('3A180', t)  = dataPar(t,'thA180');
spot_price(t)          = dataPar(t,'SpotPriceEUR');
solar_rad(t)           = dataPar(t,'SolarRad');
$offUndf
*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Set declaration and definition
*-----------------------------------------------------------------------------------------

SETS i Type of Supply
/Elect, Grid-pump, Gas-boiler, Photovoltaic, Heat-pump, Battery, Heat-storage/;

ALIAS(i,j);
SETS isub(j) Defines subset of actual tech in use for scenario
*/Elect, Elect-heat, Gas-boiler, Photovoltaic, Heat-pump, Battery, Heat-storage/;
/Elect, Grid-pump, Gas-boiler, Photovoltaic, Heat-pump, Battery/
*, Photovoltaic /;  Elect-heat
*/Gas-boiler,  Heat-pump, Battery, Heat-storage/;


SETS ci Type of costs for generation
/cost, om, taxes, fees/;


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
         fees_electNetwork   network costs for electricity consumption [� * (kWh)^(-1)] /0/
       
*Storage parameters  
         battery_maxcap                 battery max capacity ............................................... /55/
         battery_capex                  battery capital cost divided by lifetime [€ * (kWh)^(-1)]........... /53.65/
         battery_opex                   battery operational and maintenance costs [€ * (kWh)^(-1)] ......... /0.0021/
         battery_charef                 battery chaging efficiency [kWhsel * (kWhel)^(-1)] ................. /0.98/
         battery_discharef              battery dischaging efficiency [kWhel * (kWhsel)^(-1)] .............. /0.97/
         battery_ll                     linear losses % of stored energy lost per hour ..................... /0.00000173628466837439/
         battery_charglimit             battery charging limit ............................................. /1/
         battery_discharlimit           battery discharging limit .......................................... /0.5/
         battery_depthofdischarge       battery depth of discharge ......................................... /1/
         battery_maxsoc                 battery maximum SOC ................................................ /1/
         
         heatstorage_maxcap             heats storage max capacity ......................................... /55/
         heatstorage_capex              heats storage capital cost divided by lifetime  [€ * (kWh)^(-1)] ... /14.07/
         heatstorage_opex               heats storage operational and maintenance costs [€ * (kWh)^(-1)] ... /0.000883927291391307/
         heatstorage_charef             heats storage chaging efficiency [kWhsel * (kWhel)^(-1)] ........... /1/
         heatstorage_discharef          heats storage dischaging efficiency [kWhel * (kWhsel)^(-1)] ........ /1/
         heatstorage_ll                 linear losses % of stored energy lost per hour...................... /0.021/
         heatstorage_charlimit         heats storage charging limit ....................................... /1/
         heatstorage_discharlimit       heats storage discharging limit .................................... /1/
         heatstorage_depthofdischarge   heats storage depth of discharge ................................... /1/
         heatstorage_maxsoc             heats storage maximum SOC .......................................... /1/;
         

PARAMETER  sp(t)  Electricity Spot prices in per kWh not per MWh;
sp(t) = spot_price(t) * 1e-3;

PARAMETER kw(i) Maximum capacity i.e. size of unit in kW
/Elect 0
Grid-pump 0
Gas-boiler 20
Photovoltaic 20
Heat-pump 18
Battery 55
Heat-storage 15/;


PARAMETER cap_cost(i) Capitol cost in Euro per kW per year
/Elect 0
Grid-pump 0
Gas-boiler 2.55
Photovoltaic 33.63
Heat-pump 56.08
Battery 53.65
Heat-storage 14.07/;



TABLE   a(ci,i)    
                    Elect   Grid-pump   Gas-boiler   Photovoltaic   Heat-pump   Battery   Heat-storage           
cost                0       0            0.09         0              0           0         0
om                  0       0.0027       0.0011       0              0.0027      0.0021    0.0007
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
         x(t,i)
         y(t,i)
         xTot(t) 
         yTot(t)
         
*         kw_(i)
         
*Storage Variables
         pvlevel(t)         Utilizing of PV panel (dependent on solar_rad)
         battery_charge(t)              battery charge for a given timestep [kWh]
         battery_discharge(t)           battery discharge for a given timestep [kWh]
         battery_level(t)                amount of energy stored in the battery for any given time step [kWh_el]
         
         heatstorage_charge(t)          heat storage charge for a given timestep [kWh]
         heatstorage_discharge(t)       heat storage discharge for a given timestep [kWh]
         heatstorage_level(t)           amount of energy stored in the heat storage for any given time step [kWh_el]
         
         
         heatpump_level(t);


*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Equations declaration
*-----------------------------------------------------------------------------------------

equation costs;
equation elecdemand(t) summaraizes entire electricity (kWh) demand;
equation heatdemand(t) summaraizes entire heat (kWh) demand;
*equation pvproduction(t) Max pv production (kW);
*equation pvcapacity(t) Max capacity of PV (kW);
*equation boilcapacity(tt) Max capacity of heat boiler (kW);
*equation heatpumpchoice(t) force Elect-heat and 'Peatpump' as one choice;
*equation heatpumpchoice2 force Elect-heat and 'Peatpump' as one choice;

equations
*Storage constraints
         PvSOC(t)           PV utilization
         elTot(t)              Total produced el from techs at tt (x(i))
         thTot(t)              Total produced th from techs at tt (y(i))
*         BatterySOC0(tt)      The battery starts with none energy stored
         BatterySOC(t)
*         Batteryuplimit
         Batteryclimit(t)    At any given time step the charged energy cannot exceed the charging limit       
         Batterydlimit(t)    At any given time step the discharged energy cannot exceed the discharging limit

*         heatstorageSOC0(tt)      The battery starts with none energy stored
         heatstorageSOC(t)
         
*         heatstorage_uplimit
         heatstorage_climit(t)    At any given time step the charged energy cannot exceed the charging limit       
         heatstorage_dlimit(t)    At any given time step the discharged energy cannot exceed the discharging limit;

        

****** using a(ci,isub) *************
*costs.. Z =e= sum(isub,capitalCosts(isub)*bi_tech(isub))
*              + sum(tt, sp(tt)*x(tt,'Elect'))
*              + sum((tt,ci), sum(isub,(a(ci,isub))*x(tt,isub)));

***** adding heat-pump **************      
costs.. Z =e= sum(isub,      cap_cost(isub)        * kw(isub)        * bi_tech(isub))
              + sum(tt,      sp(tt)                * (x(tt,'Elect')  + x(tt,'Grid-pump'))) 
              + sum((tt,ci), sum(isub,(a(ci,isub)) * (x(tt,isub))));


elTot(tt)..                 xTot(tt) =l= x(tt,'Elect')       + x(tt,'Photovoltaic') + battery_discharge(tt) / battery_discharef;
thTot(tt)..                 yTot(tt) =l= y(tt,'Gas-boiler')  + 2.9*y(tt,'Grid-pump') + 2.9*y(tt, 'Heat-pump') + heatstorage_discharge(tt) / heatstorage_discharef;

elecdemand(tt)..        elect_load('3A80',tt) + y(tt, 'Heat-pump') + y(tt, 'Grid-pump') + battery_charge(tt) / battery_charef  =l= xTot(tt);
heatdemand(tt)..        heat_load('3A80', tt) + heatstorage_charge(tt) =l= yTot(tt);   


x.up(tt,'Photovoltaic') = kw('Photovoltaic');
PvSOC(tt)..             x(tt,'Photovoltaic') =l= solar_rad(tt);

battery_level.up(tt) =  kw('battery');
BatterySOC(tt)..       battery_level(tt) =e= battery_level(tt-1) - (battery_discharge(tt) + battery_charge(tt)) ;
Batteryclimit(tt)..  battery_charge(tt)    =l=  kw('battery') * battery_charglimit;
Batterydlimit(tt)..  battery_discharge(tt) =l= kw('battery') * battery_discharlimit;

heatstorage_level.up(tt) = kw('Heat-storage');
heatstorageSOC(tt)..      heatstorage_level(tt)     =e= heatstorage_level(tt-1) - (heatstorage_discharge(tt) + heatstorage_charge(tt));
heatstorage_climit(tt)..  heatstorage_charge(tt)    =l= kw('Heat-storage');
heatstorage_dlimit(tt)..  heatstorage_discharge(tt) =l= kw('Heat-storage');

*x.up(tt,'Heat-pump') + x.up(tt, 'Grid-pump')   = kw('Heat-pump');


**pvproduction(tt)..      y(tt,'Photovoltaic')                                            =e= solar_rad(tt)         * bi_tech('Photovoltaic');
*pvcapacity(tt)..        x(tt,'Photovoltaic')                                            =l= kw('Photovoltaic')    * bi_tech('Photovoltaic');
*heatpumpchoice(tt)..    x(tt,'Elect-heat')                                              =l= kw('heat-pump')                   * bi_tech('Heat-pump');
*heatpumpchoice2..       bi_tech('Elect-heat')                                           =e= bi_tech('Heat-pump');
*
** missing electric heat from pv panel.
*heatpumpSOC(tt)..      y(tt, 'Heat-pump') =e= 

* Adding storage
*BatteryS0C('tt170').. batt
*BatterySOC(tt)..     battery_level(tt)     =e= (battery_charge(tt) * battery_charef       - x(tt, 'battery') / battery_discharef);
*Batteryuplimit(tt).. battery_level(tt)     =l= battery_maxcap;
*Batteryclimit(tt)..  battery_charge(tt)    =l= battery_maxcap      * battery_charglimit   * bi_tech('Battery');
*Batterydlimit(tt)..  battery_discharge(tt) =l= battery_maxcap      * battery_discharlimit * bi_tech('Battery');
*
*heatstorageSOC(tt)..      heatstorage_level(tt)     =e= (heatstorage_charge(tt) * heatstorage_charef       - heatstorage_discharge(tt) / heatstorage_discharef);
*heatstorage_uplimit(tt).. heatstorage_level(tt)     =l= heatstorage_maxcap;
*heatstorage_climit(tt)..  heatstorage_charge(tt)    =l= heatstorage_maxcap      * heatstorage_charlimit    * bi_tech('Heat-storage');
*heatstorage_dlimit(tt)..  heatstorage_discharge(tt) =l= heatstorage_maxcap      * heatstorage_discharlimit * bi_tech('Heat-storage');



battery_level.fx('tt168') = 55;

*heatpumpSOC.up(tt) = kw('Heat-pump');
bi_tech.fx('Elect') = 1;
bi_tech.fx('Gas-boiler') = 1;
******** Custom Edits ************

****** Grid electricity and Gas-boiler is always available *********

*battery_charge.fx('tt170') = 0;
*cap_Costs('Heat-pump')= 0;
*cap_Costs('Photovoltaic') =0;
*bi_tech.fx('Photovoltaic') = 0;
*bi_tech.fx('Elect-heat') = 0;
*bi_tech.fx('Heat-pump') = 0;
bi_tech.fx(isub) = 1;

******** Solver ***************
Model energy /all/;
option mip=cplex;
solve energy using mip minimizing Z;

x_Results(isub) = sum(tt,x.l(tt,isub));

display Z.l,x.l, bi_tech.l, x_Results, battery_charge.l;