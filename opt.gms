*-----------------------------------------------------------------------------------------
* calling Data parameters and timeset from one csv file, calling twice to create one GDX ..
* for the entire time_steps and the full parameter set
*-----------------------------------------------------------------------------------------
$call csv2gdx csv/TimeSeries_dat.csv output=gdx/TimeSeries_dat.gdx          id=dataPar index=1 values=2,3,4,5,6,7,8,10 useHeader=y fieldSep=SemiColon decimalSep=Comma storeZero=y
$call csv2gdx csv/TimeSeries_dat.csv output=gdx/agr_TimeSeries.gdx          id=agrTime index=9 useHeader=y fieldSep=SemiColon decimalSep=Comma storeZero=y
*-----------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------
* Set declaration and definitions
*-----------------------------------------------------------------------------------------
* Parameters loading via GDX files created above
* Initializing full timeset and the housing scenarios as a set
* SET 't' is the full year of 2017
* The SET 'scen' is used to either loop over scen in the solve module or ..
* To manually enter strin like '1A80' to use this scenario. It must only be entered ..
* for the two demand sets i.e. elect_load('scen') and heat_load('scen')
* ex: equation.. elect_load('1A80') =l= ...
* loop ex:
* loop(scen,
*        equation.. elect_load(scen) =l= ... notice that when using the entire set you must not enter it as a string i.e. dont use the quote ''
* solve ..... )
*-----------------------------------------------------------------------------------------
SETS  t         time_steps set for all hours (8760) of the year 2017
      scen      scenarios set for the four different households
    
scen /1A80, 1A180, 3A80, 3A180/;

* Initializes the data from the GDX 'Time_Series_dat.GDX'
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


* Timesteps subset using agregated time steps i.e. the four weeks
* The SUBSET SET tt holds the agregated timeseries loaded from the agr_TimeSeries.GDX
ALIAS(t, ts);
SETS tt(ts) aggregate time_step set - a subset of SET 't'
* uncomment the line below and you can set a test time_subset for a smaller SUBSET ..
* note that no solar_rad data currently exist for any timesteps other than the SET tt
* /tt1*tt5/; 

$gdxIn gdx/agr_TimeSeries.gdx
$load tt = Dim1
$gdxIn
;

* Collects the data parameters and assigns demands for all the scenarios
* note the heat_load for scenarios of equal house sizes are identical i.e. heat_load('1A80', t) == heat_load('3A80')
elect_load('1A80', t)  = dataPar(t,'el1A80');
elect_load('1A180',t)  = dataPar(t,'el1A180');
elect_load('3A80', t)  = dataPar(t,'el3A80');
elect_load('3A180',t)  = dataPar(t,'el3A180');
heat_load('1A80',  t)  = dataPar(t,'thA80');
heat_load('1A180', t)  = dataPar(t,'thA180');
heat_load('3A80',  t)  = dataPar(t,'thA80');
heat_load('3A180', t)  = dataPar(t,'thA180');
spot_price(t)          = dataPar(t,'SpotPriceEUR');
solar_rad(t)           = dataPar(t,'SolarRad');
$offUndf

* initializes the SET 'i' which holds all available technologies for grid, gas, gen tech and storage tech
SETS i        Set for all technologies
/Elect, Grid-pump, Gas-boiler, Photovoltaic, Heat-pump, Battery, Heat-storage/;

* initializes the SUBSET SET 'isub' which is a subset of 'i' (technologies)
* change 'isub' only for testing
ALIAS(i,j);
SETS isub(j)  subset of i (technologies)
/Elect, Grid-pump, Gas-boiler, Photovoltaic, Heat-pump, Battery, Heat-storage/;

* initializes the SET 'ci' for which holds all 'per unit of kWh' parameters
* used in the objective function
SETS ci       Type of costs for generation
/cost, om, taxes, fees/;
*-----------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------
* Scalar declaration and definitions
*
*
*
*-----------------------------------------------------------------------------------------
SCALAR       
         battery_charef                 battery chaging efficiency [kWhsel * (kWhel)^(-1)] ................. /0.98/
         battery_discharef              battery dischaging efficiency [kWhel * (kWhsel)^(-1)] .............. /0.97/
         battery_ll                     linear losses % of stored energy lost per hour ..................... /0.00000173628466837439/
         battery_charglimit             battery charging limit ............................................. /1/
         battery_discharlimit           battery discharging limit .......................................... /0.5/
         battery_depthofdischarge       battery depth of discharge ......................................... /1/
         battery_maxsoc                 battery maximum SOC ................................................ /1/
         
*         heatstorage_opex               heats storage operational and maintenance costs [€ * (kWh)^(-1)] ... /0.000883927291391307/
         heatstorage_charef             heats storage chaging efficiency [kWhsel * (kWhel)^(-1)] ........... /1/
         heatstorage_discharef          heats storage dischaging efficiency [kWhel * (kWhsel)^(-1)] ........ /1/
         heatstorage_ll                 linear losses % of stored energy lost per hour...................... /0.021/
         heatstorage_charlimit          heats storage charging limit ....................................... /1/
         heatstorage_discharlimit       heats storage discharging limit .................................... /1/
         heatstorage_depthofdischarge   heats storage depth of discharge ................................... /1/
         heatstorage_maxsoc             heats storage maximum SOC .......................................... /1/;
*-----------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------
* Parameter declaration and definitions
*-----------------------------------------------------------------------------------------
* Spot prices 'sp(t)' is multiplied by 1e-3 to get per kWh prices instead of per MWh
* Tech capacity 'kw(i)' is the set size for a given tech in kW output or cababilities
* TODO: If we're not doing decision variables for the capacities then  'kw(i)' ...
* should be a table also taking the SET 'scen' as index to then define appropriate ...
* tech-sizes for various housing sizes.
* See the teams Wiki for a suggestion of these sizes the page 'DATA'
* Capitol cost 'cap_cost(i)' is the per kW size of technology related to ...
* investing (buying) in a tech. 
* Table 'a(ci, i)' is the table used in the solver for calculating the per unit kWh costs
* it uses the SET's 'i' and 'ci' for the technologies and the running cost of technologies
* The table is filed with scalars and this is here we change different cost parameters ...
* for e.g. sensitivity analyses or further testing.
* Parameter 'x_Results'
*-----------------------------------------------------------------------------------------
PARAMETER  sp(t)            Electricity Spot prices in per kWh not per MWh;
sp(t) = 60 * 1e-3
*sp(t) = spot_price(t) * 1e-3;

PARAMETER kw(i)             Maximum capacity i.e. size of unit in kW
/Elect        0
Grid-pump     0
Gas-boiler    20
Photovoltaic  20
Heat-pump     18
Battery       55
Heat-storage  15/;


PARAMETER cap_cost(i)       Capitol cost in Euro per kW per year
/Elect        0 
Grid-pump     0
Gas-boiler    2.55
Photovoltaic  33.63
Heat-pump     56.08
Battery       53.65
Heat-storage  14.07/;



TABLE   a(ci,i)             Table used in the objective function for calculate the per unit kWh running costs of all techs
                            Elect   Grid-pump   Gas-boiler   Photovoltaic   Heat-pump   Battery   Heat-storage           
cost                        0       0            0.09         0              0           0         0
om                          0       0.0027       0.0011       0              0.0027      0.0021    0.0008
taxes                       0.12    0.036        0.04         0              0           0         0
fees                        0       0            0            0              0           0         0;

Parameter
        x_Results(i)        Used to display how much [kWh] each electricity related technology is used over the selected time_series
        y_Results(i)        Used to display how much [kWh] each thermally related technology is used over the selected time_series;

*-----------------------------------------------------------------------------------------
*-----------------------------------------------------------------------------------------
* Variables declaration and definition
*-----------------------------------------------------------------------------------------
* Binaries 'bi_tech(i)' indexed with the technology SET 'i'
* Variable 'Z' is the objective function to minimize. It estimates the cost over the ...
* selected time steps for the optimal investing strategy and the related running costs
* 
*   x(t,i) is used for all decision variables related to providing electricity
*   y(t,i) is used for all decision variables related to providing heat (thermal)
*   xTot(t) collects all available electricity in each time step
*   yTot(t) collects all available thermal energy (heat) in each time step
*
*-----------------------------------------------------------------------------------------
Binary Variable
        bi_tech(i)                      Binary decision variables for all techs;

Variable
         Z                              Objective function: Investment and runnning energy purchase costs;
         
Positive Variable
         x(t,i)                         Decision variables for electricity requests  to techs
         y(t,i)                         Decision variables for thermal heat requests to techs
         xTot(t)                        Variable for total electricity available to cover demand at each time step
         yTot(t)                        Variable for total thermal energy available to cover demand at each time step
         battery_charge(t)              battery charge for a given timestep [kWh]
         battery_discharge(t)           battery discharge for a given timestep [kWh]
         battery_level(t)               amount of energy stored in the battery for any given time step [kWh_el]
         heatstorage_charge(t)          heat storage charge for a given timestep [kWh]
         heatstorage_discharge(t)       heat storage discharge for a given timestep [kWh]
         heatstorage_level(t)           amount of energy stored in the heat storage for any given time step [kWh_el];
*-----------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------
* Equations declaration
*
*
*
*----------------------------------------------------------------------------------------- 
equations
         costs                    objective function equation calculates entire cost for optimal solution
         elecdemand(t)            summaraizes entire electricity (kWh) demand
         heatdemand(t)            summaraizes entire heat (kWh) demand
         elTot(t)                 Total produced el from techs at tt (x(i))
         thTot(t)                 Total produced th from techs at tt (y(i))
         
         PvSOC(t)                 PV utilization
*         HeatpumpSOC(t)           Heatpump utilization
         
         BatterySOC(t)            Battery utilization
         Batteryclimit(t)         At any given time step the charged energy cannot exceed the charging limit       
         Batterydlimit(t)         At any given time step the discharged energy cannot exceed the discharging limit

         heatstorageSOC(t)         
         heatstorage_climit(t)    At any given time step the charged energy cannot exceed the charging limit       
         heatstorage_dlimit(t)    At any given time step the discharged energy cannot exceed the discharging limit;
*-----------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------
* Model declaration
*
*
*
*-----------------------------------------------------------------------------------------

* Defines upper levels for generation and storage techs
* Fixes initial levels of battery to model a battery charge level at previous timestep
* Fixes grid electricity and boiler techs to always available
x.up(t,'Photovoltaic')      =  kw('Photovoltaic');
y.up(t,'heat-pump')         =  kw('Heat-pump');
battery_level.up(t)         =  kw('battery');
battery_level.fx('tt168')   =  30;
heatstorage_level.up(t)     =  kw('Heat-storage');
bi_tech.fx('Elect')         =  1;
bi_tech.fx('Gas-boiler')    =  1;
           
costs..                 Z  =e= sum(isub,        cap_cost(isub)           * kw(isub)        * bi_tech(isub))
                            +  sum( tt,         sp(tt)                   * (x(tt,'Elect')  + x(tt,'Grid-pump'))) 
                            +  sum((tt,ci),     sum(isub,a(ci,isub)      * (x(tt,isub)     + y(tt,isub))));

elTot(tt)..                 xTot(tt)                  =l=  x(tt,'Elect')            + x(tt,'Photovoltaic')    + battery_discharge(tt) / battery_discharef;
thTot(tt)..                 yTot(tt)                  =l=  y(tt,'Gas-boiler')       + 2.9 * y(tt,'Grid-pump') + 2.9 * y(tt, 'Heat-pump') + heatstorage_discharge(tt) / heatstorage_discharef;
elecdemand(tt)..            xTot(tt)                  =g=  elect_load('3A180', tt)  + y(tt, 'Heat-pump')      + y(tt, 'Grid-pump')       + battery_charge(tt) / battery_charef;
heatdemand(tt)..            yTot(tt)                  =g=  heat_load( '3A180', tt)  + heatstorage_charge(tt)  / heatstorage_charef;   

PvSOC(tt)..                 x(tt,'Photovoltaic')      =l=  solar_rad(tt);
BatterySOC(tt)..            battery_level(tt)         =e=  (battery_level(tt-1)     + battery_charge(tt)      - battery_discharge(tt))     * (1 - battery_ll);
Batteryclimit(tt)..         battery_charge(tt)        =l=  kw('battery')            * battery_charglimit;
Batterydlimit(tt)..         battery_discharge(tt)     =l=  kw('battery')            * battery_discharlimit;
heatstorageSOC(tt)..        heatstorage_level(tt)     =e=  (heatstorage_level(tt-1) + heatstorage_charge(tt)  - heatstorage_discharge(tt)) * (1 - heatstorage_ll);
heatstorage_climit(tt)..    heatstorage_charge(tt)    =l=  kw('Heat-storage');
heatstorage_dlimit(tt)..    heatstorage_discharge(tt) =l=  kw('Heat-storage');

******** Custom Edits ************
*battery_charge.fx('tt170') = 0;
*cap_Costs('Heat-pump')= 0;
*cap_Costs('Photovoltaic') =0;
*bi_tech.fx('Photovoltaic') = 0;
*bi_tech.fx('Elect-heat') = 0;
*bi_tech.fx('Heat-pump') = 0;
*bi_tech.fx(isub) = 1;

******** Solver ***************
Model energy /all/;
option mip=cplex;
solve energy using rmip minimizing Z;

x_Results(isub) = sum(tt,x.l(tt,isub));
y_Results(isub) = sum(tt,y.l(tt,isub));

display Z.l, x.l, y.l, bi_tech.l, x_Results, y_Results, battery_charge.l;