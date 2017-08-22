##############################################################################
##
##  Flying Cat balloon
##  Copyright (C) 2016 Herbert Wagner
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################
# For solar radiation heating.
setlistener("/sim/time/sun-angle-rad", func {
    setprop("/fdm/jsbsim/environment/sun-angle-rad", getprop("/sim/time/sun-angle-rad"));
});

#############################################################################################################
setprop("/controls/switches/gauge-light", 0);
#############################################################################################################
# Start-up-screen message

setprop("sim/messages/copilot", "Hello");
setprop("sim/messages/copilot", getprop("sim/multiplay/generic/string[0]"));
setprop("sim/messages/copilot", "Have fun with the Hot Air Balloon Series");

#############################################################################################################
# Lake of Constance Hangar :: M.Kraus
# April 2013
# This file is licenced under the terms of the GNU General Public Licence V2 or later
# ============================================
# The analog watch for the flightgear - rallye 
# ============================================
var sw = "/instrumentation/stopwatch/";


#============================== only stopwatch actions ================================
var sw_start_stop = func {
  var running = props.globals.getNode(sw~"running");

  if(!running.getBoolValue()){
    # start
    setprop(sw~"flight-time/start-time", getprop("/sim/time/elapsed-sec"));
    running.setBoolValue(1);
    sw_loop();
  }else{
    # stop
    var accu = getprop(sw~"flight-time/accu");
    accu += getprop("/sim/time/elapsed-sec") - getprop(sw~"flight-time/start-time");
    setprop(sw~"running",0);
    setprop(sw~"flight-time/accu", accu);
    sw_show(accu);
  }
}

var sw_reset = func {
  var running = props.globals.getNode(sw~"running");
  setprop(sw~"flight-time/accu", 0);

  if(running.getBoolValue()){
    setprop(sw~"flight-time/start-time", getprop("/sim/time/elapsed-sec"));
  }else{
    sw_show(0);
  }
}

var sw_loop = func {
  var running = props.globals.getNode(sw~"running");
  if(running.getBoolValue()){
    sw_show(getprop("/sim/time/elapsed-sec") - getprop(sw~"flight-time/start-time") + getprop(sw~"flight-time/accu"));
    settimer(sw_loop, 0.04);
  }
}

var sw_show = func(s) {
  var hours = s / 3600;
  var minutes = int(math.mod(s / 60, 60));
  var seconds = int(math.mod(s, 60));

  setprop(sw~"flight-time/total",s);
  setprop(sw~"flight-time/hours",hours);
  setprop(sw~"flight-time/minutes",minutes);
  setprop(sw~"flight-time/seconds",seconds);
}

##############################################################################################################

#UVID-15 Control for Pressure in mmhg and inhg
# create listener

setprop("/instrumentation/altimeter/setting-hapa", getprop("/instrumentation/altimeter/setting-hpa"));

setlistener("/instrumentation/altimeter/setting-inhg", func(v)
{
  if(v.getValue())
  
    setprop("/instrumentation/altimeter/mmhg", getprop("/instrumentation/altimeter/setting-inhg") * 25.4);
    setprop("/instrumentation/altimeter/setting-inhgN", getprop("/instrumentation/altimeter/setting-inhg") + 0.005);
    setprop("/instrumentation/altimeter/setting-hapa", getprop("/instrumentation/altimeter/setting-inhg") * 33.8682715);
});
#############################################################################################################
# timer for initial temperatur, needed for red lamp
setprop("/fdm/jsbsim/atmosphere/initT", 0);

var timerIniTemp = maketimer(0.5, func

  { 
    setprop("/fdm/jsbsim/atmosphere/initT", getprop("fdm/jsbsim/atmosphere/T-R") - getprop("fdm/jsbsim/buoyant_forces/gas-cell/temp-R"));    
  }
);

# start the timer (with 0.5 second inverval)
timerIniTemp.start();

# Rankine to Celsius: [°C] = ([°R] − 491.67) × 5⁄9

setprop("/fdm/jsbsim/buoyant_forces/gas-cell/Celsius", 0);

var celsius = maketimer(1.0, func
      {
       cel = (getprop("fdm/jsbsim/buoyant_forces/gas-cell/temp-R") -491.67) * 5 / 9;
        setprop("/fdm/jsbsim/buoyant_forces/gas-cell/Celsius", cel);
      }
);

celsius.start();

# burner off if temp > 123 Celsius

setlistener("/fdm/jsbsim/buoyant_forces/gas-cell/Celsius", func(v)
{
  if(v.getValue() > 123)
    setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 0);
});
#############################################################################################################
#correct ground elevation
# create timer with 0.05 second interval

setprop("/position/ground-altitude", 0);

var timerGE = maketimer(0.05, func
  { 
    if ((getprop("/position/altitude-ft") != nil) and (getprop("/position/ground-elev-ft") != nil))
    setprop("/position/ground-altitude", getprop("/position/altitude-ft") - getprop("/position/ground-elev-ft"));
  }
);

# start the timer (with 0.5 second inverval)
timerGE.start();

setprop("/fdm/jsbsim/position/ground-altitude", 0);

setlistener("/position/ground-altitude", func(v)
{
  if(v.getValue())
    setprop("/fdm/jsbsim/position/ground-altitude", getprop("/position/ground-altitude"));
});
  




# vertical speed
setlistener("/autopilot/internal/vert-speed-fpm", func(v)
{
  if(v.getValue())
    setprop("/instrumentation/vertical-speed-indicator/indi-speed-mps", getprop("/autopilot/internal/vert-speed-fpm") * 0.00508);
});

############################################################################################################
# Parking Brake and Gear Control

var activ = 0;

var steady = maketimer(0.3, func
{ 
  if (getprop("/sim/replay/replay-state") == 0)
  {
    if (getprop("/fdm/jsbsim/systems/behaviour/steady-onground") == 1 and activ == 0)
         {
	  setprop("sim/messages/copilot", "Fixing Lines are installed");
          setprop("/controls/gear/brake-parking", 1);
	  setprop("/controls/gear/gear-down", 1);
	  activ = 1;  
         }
    if (getprop("/fdm/jsbsim/systems/behaviour/steady-onground") == 0 and activ == 1)
         {
	  setprop("/controls/gear/brake-parking", 0);
	  setprop("/controls/gear/gear-down", 0);
	  setprop("/fdm/jsbsim/animation/anchor-sacks", 0);
          setprop("/fdm/jsbsim/fcs/mooring-cmd-norm", 0);
          setprop("/fdm/jsbsim/fcs/mooring2-cmd-norm", 0);
	  setprop("sim/messages/copilot", "Fixing Lines are cut off");
	  activ = 0;
         }
   }
}); 
steady.start();
#############################################################################################################
#
# wind drift orientation compass

# create timer with 0.7 second interval

var TODEG = 180/math.pi;
var TORAD = math.pi/180;
var deg = func(rad){ return rad*TODEG; }
var rad = func(deg){ return deg*TORAD; }
var calc = maketimer(0.7, func

{ 
var DA = rad(getprop("/environment/wind-from-heading-deg") - 180 - (getprop("/orientation/heading-deg")));
var DI = rad(getprop("/environment/wind-from-heading-deg") - 180);
var drift = math.periodic(-180, 180, deg(DA));
var direction = math.periodic(-180, 180, deg(DI));

setprop("/instrumentation/drift", drift);
setprop("/instrumentation/direction", direction);

}
);

# start the timer (with 0.7 second inverval)
calc.start();
######################################################################################################
# flame-valve-controll
setprop("/fdm/jsbsim/fcs/flame-valve1-cmd-norm", 0);
setprop("/fdm/jsbsim/fcs/flame-valve2-cmd-norm", 0);
setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 0);


setlistener("/fdm/jsbsim/fcs/flame-valve-cmd-norm", func(v)
{
  if(v.getValue() == 0)  
  {
      setprop("/fdm/jsbsim/fcs/flame-valve1-cmd-norm", 0);
      setprop("/fdm/jsbsim/fcs/flame-valve2-cmd-norm", 0);
  }
   if(v.getValue() == 1)  
  {
      setprop("/fdm/jsbsim/fcs/flame-valve1-cmd-norm", 1);
      setprop("/fdm/jsbsim/fcs/flame-valve2-cmd-norm", 0);
  }
  if(v.getValue() == 2)  
  {
      setprop("/fdm/jsbsim/fcs/flame-valve1-cmd-norm", 1);
      setprop("/fdm/jsbsim/fcs/flame-valve2-cmd-norm", 1);
  }
});

######################################################################################################
# Autopilot controller
#
#  Orientation Drift Turnvalves
#
#  /autopilot/locks/heading = orientation    string-value
#  /autopilot/locks/heading-on               same, but 0/1 = off/on
#  /instrumentation/drift                 -180 -- 0  -- 180
#  /fdm/jsbsim/fcs/turnvalve              -1 ----- 1  -left +right   from Autopilot if drift > 1 grad then 1 if < 1 then 0.xx

#  /fdm/jsbsim/fcs/turnvalve-var              -1 / 1  -left +right   mapping to on or out if < 0,8 und > -0,8

#  /fdm/jsbsim/fcs/turnvalvel-cmd-norm       0/1   magnitude from 0 to 100 or 0 to -100
#  /fdm/jsbsim/fcs/turnvalver-cmd-norm       0/1

#  /orientation/yaw-rate-degps              drehgeschwindigkeit

setprop("/fdm/jsbsim/fcs/turnvalvel-cmd-norm", 0);
setprop("/fdm/jsbsim/fcs/turnvalver-cmd-norm", 0);
setprop("/fdm/jsbsim/fcs/turnvalve-var", 0);
setprop("/fdm/jsbsim/fcs/turnvalve", 0);


setlistener("/fdm/jsbsim/fcs/turnvalve", func(v)
{
  if(v.getValue() > 0.1)  
      setprop("/fdm/jsbsim/fcs/turnvalve-var", 1);
  else
  {
  if(v.getValue() < -0.1)
    setprop("/fdm/jsbsim/fcs/turnvalve-var", -1);
  else
    setprop("/fdm/jsbsim/fcs/turnvalve-var", 0);
  }
});

# grob tuning
var timerOri1 = maketimer(1, func
{  if (getprop("/autopilot/locks/heading-on") == 1)

 { 
   if (getprop("/fdm/jsbsim/fcs/turnvalve-var") == 1 and getprop("/orientation/yaw-rate-degps") < 0.07  and getprop("/instrumentation/drift") > 1 )
    {
    setprop("/fdm/jsbsim/fcs/turnvalver-cmd-norm", 1);
    interpolate("/fdm/jsbsim/fcs/turnvalver-cmd-norm", 1, 5, 0, 0);
    }
   else
   {
      
    if (getprop("/fdm/jsbsim/fcs/turnvalve-var") == -1 and getprop("/orientation/yaw-rate-degps") > -0.07  and getprop("/instrumentation/drift") < -1 )
     { 
     setprop("/fdm/jsbsim/fcs/turnvalvel-cmd-norm", 1);
     interpolate("/fdm/jsbsim/fcs/turnvalvel-cmd-norm", 1, 5, 0, 0);
     }       
    
   else
     setprop("/fdm/jsbsim/fcs/turnvalvel-cmd-norm", 0);
   }
 }
});

timerOri1.start();

# fine tuning
var timerOri2 = maketimer(1, func
{  if (getprop("/autopilot/locks/heading-on") == 1)

 { 
   if (getprop("/fdm/jsbsim/fcs/turnvalve-var") == 1 and getprop("/orientation/yaw-rate-degps") < 0.003  and getprop("/instrumentation/drift") > 0.1 )
    {
    setprop("/fdm/jsbsim/fcs/turnvalver-cmd-norm", 1);
    interpolate("/fdm/jsbsim/fcs/turnvalver-cmd-norm", 1, 2, 0, 0);
    }
   else
   {
      
    if (getprop("/fdm/jsbsim/fcs/turnvalve-var") == -1 and getprop("/orientation/yaw-rate-degps") > -0.003  and getprop("/instrumentation/drift") < -0.1 )
     { 
     setprop("/fdm/jsbsim/fcs/turnvalvel-cmd-norm", 1);
     interpolate("/fdm/jsbsim/fcs/turnvalvel-cmd-norm", 1, 2, 0, 0);
     }       
    
   else
     setprop("/fdm/jsbsim/fcs/turnvalvel-cmd-norm", 0);
   }
 }
});

timerOri2.start();

################################################################################################
#   instrumentation/vertical-speed-indicator/indicated-speed-mps        vertical speed m/s
#   /instrumentation/vertical-speed-indicator/indi-speed-mps                                                       neu!!!
#   /fdm/jsbsim/fcs/flame-valve-cmd-norm                                burner         0/1
#   /fdm/jsbsim/fcs/blower-valve-cmd-norm                               blower         0/1
#   /fdm/jsbsim/fcs/gas-valve-cmd-norm                                  parachute      0/1
#   /autopilot/locks/parachute-on                                       0/1 

# parachute controll

setprop("/fdm/jsbsim/fcs/gas-para-activ", 0);
setprop("/fdm/jsbsim/fcs/gas-desc-activ", 0);
setprop("/autopilot/locks/parachute-on", 0);
setprop("/autopilot/locks/descend-on", 0);

var timerPara = maketimer(1, func
{  if (getprop("/autopilot/locks/parachute-on") == 1)
 {  
  if (getprop("instrumentation/vertical-speed-indicator/indi-speed-mps") > 2.5)
  { 
    setprop("/fdm/jsbsim/fcs/gas-para-activ", 1);
    setprop("/fdm/jsbsim/fcs/gas-valve-cmd-norm", 1);
    setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 0);
    setprop("/fdm/jsbsim/fcs/blower-valve-cmd-norm", 0);
  }
  else
   {
     if (getprop("instrumentation/vertical-speed-indicator/indi-speed-mps") < 2.5 and getprop("/fdm/jsbsim/fcs/gas-para-activ") == 1 )
     { 
       setprop("/fdm/jsbsim/fcs/gas-valve-cmd-norm", 0);
       setprop("/fdm/jsbsim/fcs/gas-para-activ", 0);
     }
   }
 } 
});

timerPara.start();

#################################################################################################
# descending controll

# /autopilot/locks/descend-on

var timerDesc = maketimer(1, func
{  if (getprop("/autopilot/locks/descend-on") == 1)
 {  
  if (getprop("instrumentation/vertical-speed-indicator/indi-speed-mps") < -2.5)
  { 
    setprop("/fdm/jsbsim/fcs/gas-desc-activ", 1);
    setprop("/fdm/jsbsim/fcs/gas-valve-cmd-norm", 0);
    setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 2);
    setprop("/fdm/jsbsim/fcs/blower-valve-cmd-norm", 1);
  } 
  else
    {
     if (getprop("instrumentation/vertical-speed-indicator/indi-speed-mps") > -2.5 and getprop("/fdm/jsbsim/fcs/gas-desc-activ") == 1 ) 
     { setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 0);
       setprop("/fdm/jsbsim/fcs/gas-desc-activ", 0);
       setprop("/fdm/jsbsim/fcs/blower-valve-cmd-norm", 0);
     }
    } 
 } 
});

timerDesc.start();

###################################################################################################
# altitude hold controller
#
setprop("/autopilot/locks/altitude-on", 0);



var timerLogic = maketimer(1, func
{ 
  
  if (getprop("/autopilot/locks/altitude-on") == 0)
   {   
    setprop("/autopilot/settings/logic", 0);
   } 
  if (getprop("/autopilot/locks/altitude-on") == 1)
  {
# Def der Variablen
     var vertspeed = getprop("instrumentation/vertical-speed-indicator/indi-speed-mps");
     var logic = 0;
    
# Logic Schaltung
   
         if (vertspeed > 0.20)
	   logic = -1;
	 if (vertspeed > -0.05 and vertspeed < 0.20)
	   logic = 0;
	 if (vertspeed < -0.05)
	   logic = 1;
     
     setprop("/autopilot/settings/logic", logic);
  }
  else
    setprop("/autopilot/settings/logic", 0);
});

timerLogic.start();

# setting the values to the logic
setlistener("/autopilot/settings/logic", func(v)
{  
  if(v.getValue() == -1) 
  {
   setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 0);
   setprop("/fdm/jsbsim/fcs/blower-valve-cmd-norm", 0);
   setprop("/fdm/jsbsim/fcs/gas-valve-cmd-norm", 1);    
  }
  if(v.getValue() == 0) 
  {
   setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 0);
   setprop("/fdm/jsbsim/fcs/blower-valve-cmd-norm", 0);   
   setprop("/fdm/jsbsim/fcs/gas-valve-cmd-norm", 0);   
  }
  if(v.getValue() == 1) 
  {
   setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 1); 
   setprop("/fdm/jsbsim/fcs/blower-valve-cmd-norm", 1); 
   setprop("/fdm/jsbsim/fcs/gas-valve-cmd-norm", 0);   
  }
  
}, 1, 0);
