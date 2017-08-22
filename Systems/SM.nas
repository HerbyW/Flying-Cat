##############################################################################
##
##  Scharmorton balloon
##  Copyright (C) 2016 Herbert Wagner
##  Copyright (C) 2006 - 2010  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

var weight_on_gear =
    props.globals.getNode("/fdm/jsbsim/forces/fbz-gear-lbs");
var gas_valve = "/fdm/jsbsim/fcs/gas-valve-cmd-norm";

###############################################################################

var print_wow = func {
    gui.popupTip("Current weight on basket " ~
                 weight_on_gear.getValue() ~ ".");
}

##############################################################################

var weightoff = func {
    
 if (getprop("/fdm/jsbsim/fcs/mooring2-cmd-norm") == 1)
    {
      setprop("sim/messages/copilot", "We are getting ready for take off!");

      gui.popupTip("Filling Hot Air to 100% for take off in progress. " ~
                 "Current weight " ~ weight_on_gear.getValue() ~ ".");
    var wowmol = (weight_on_gear.getValue() * -35.2);
    var cont = getprop("/fdm/jsbsim/buoyant_forces/gas-cell/contents-mol");
    interpolate("/fdm/jsbsim/buoyant_forces/gas-cell/contents-mol", cont + 0.96 * wowmol, 10);
    setprop("/fdm/jsbsim/fcs/takeoffweight", 1);
   }
   else
   {
     setprop("sim/messages/copilot", "We need the anchor set!");
     setprop("/fdm/jsbsim/fcs/takeoffweight", 0);
  }
  if (getprop("/fdm/jsbsim/buoyant_forces/gas-cell/volume-ft3") > 126820.0) setprop("/fdm/jsbsim/fcs/takeoffweight", 0);
}

######################################################################################
# check anchor status
# start:Temp and Filling: anchor-new
# Take off weight: lifting a little bit
# release anchors-new
# flight and landing: sandsacks
# new initial: back to anchor-new
# after ripping: sandscks go and anchor-new come
# call "whatanchor" with E or switch Anchor
# switch has 3 stages: 0 no anchor 1 fixed-anchor 2 sandsacks : fdm/jsbsim/animation/anchor-sacks

setprop("/fdm/jsbsim/fcs/takeoffweight", 0);

var whatanchor = func
{
  if (getprop("/fdm/jsbsim/fcs/initial") == nil)
   {
      setprop("/fdm/jsbsim/fcs/initial", 0);
      setprop("/fdm/jsbsim/animation/anchor-sacks", 1);
      setprop("/fdm/jsbsim/fcs/mooring2-cmd-norm", 1);
   } 
    
  if (getprop("/fdm/jsbsim/fcs/initial") == 1)
   {
    setprop("/fdm/jsbsim/animation/anchor-sacks", 1);
    setprop("/fdm/jsbsim/fcs/mooring2-cmd-norm", 1);
    setprop("/fdm/jsbsim/fcs/mooring-cmd-norm", 0);
   }
  if (getprop("/fdm/jsbsim/fcs/initial") == 0)
   {  
    if (getprop("/fdm/jsbsim/animation/anchor-sacks") == 0 )
    {
      setprop("/fdm/jsbsim/animation/anchor-sacks", 2);
      setprop("/fdm/jsbsim/fcs/mooring-cmd-norm", 1);
      setprop("/fdm/jsbsim/fcs/mooring2-cmd-norm", 0);
    }
    else
    {
      setprop("/fdm/jsbsim/animation/anchor-sacks", 0);
      setprop("/fdm/jsbsim/fcs/mooring-cmd-norm", 0);
      setprop("/fdm/jsbsim/fcs/mooring2-cmd-norm", 0);
    }
   }
}

setlistener("/position/ground-altitude", func(v)
{
  if(v.getValue() > 2)
    setprop("/fdm/jsbsim/fcs/initial", 0);
});
####################################################################################
#hot air cell blower
# this makes a trigger for the blower, so that in 1 sec 1000 mol are filled in

var blower = aircraft.light.new("/fdm/jsbsim/fcs/blower-valve-cmd-norm/trigger", [0.5,0.5], "/fdm/jsbsim/fcs/blower-valve-cmd-norm");

setlistener("/fdm/jsbsim/fcs/blower-valve-cmd-norm/trigger/state", func(state)
{
  if(state.getValue())
  {
    if(getprop("/fdm/jsbsim/animation/hull") > 0.99)
    {
      blower.switch(0);
      setprop("/fdm/jsbsim/fcs/blower-valve-cmd-norm/trigger/state", 0);
      setprop("sim/messages/copilot", "Hot Air Balloon is filled");
    }
     else
     {
      var mol = getprop("/fdm/jsbsim/buoyant_forces/gas-cell/contents-mol") + 500;
      setprop("/fdm/jsbsim/buoyant_forces/gas-cell/contents-mol", mol);
     }
  }
});

####################################################################################
#Butan control
#         /fdm/jsbsim/fcs/flame-valve-cmd-norm    Flame 0 1 2


var consum = maketimer(1.0, func
{ 
 propane = getprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]"); 
 if (getprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm") == 1 )
 {
   setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]", propane - 0.095165 );
 }
 if (getprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm") == 2 )
 {
   setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]", propane - 0.190331 );
 }
});

# start the timer (with 1 second inverval)
consum.start();


setlistener("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]", func {
  if (getprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]") < 24  )
  {
  setprop("/sim/messages/copilot", "Less than 10% Propane on board!");
  setprop("/fdm/jsbsim/fcs/flame-valve-cmd-norm", 0);
  }
});

########################################################################################################
# Rip Valve control
#    /fdm/jsbsim/fcs/rip-cmd-norm       0 oder 30
var rip_panel = "/fdm/jsbsim/fcs/rip-cmd-norm";
var ripped    = 0;

setlistener("/fdm/jsbsim/fcs/rip-cmd-norm", func {
  if (getprop("/fdm/jsbsim/fcs/rip-cmd-norm") > 0  )
  {
  ripped = 1;
  setprop("/sim/messages/copilot", "Rip Valve is open!");
  } else ripped = 0;
});

var ripping = maketimer(0.2, func
{ 
 if (ripped == 1 and getprop("/fdm/jsbsim/animation/hull") < 0.05 )
 {
   rip_panel = 0;
   setprop("/fdm/jsbsim/fcs/rip-cmd-norm", 0);
   setprop("/sim/messages/copilot", "Balloon is ripped and nearly empty!");
 }
});

# start the timer (with 0.2 second inverval)
ripping.start();

###############################################################################
# About dialog.

var ABOUT_DLG = 0;

var dialog = {
#################################################################
    init : func (x = nil, y = nil) {
        me.x = x;
        me.y = y;
        me.bg = [0, 0, 0, 0.3];    # background color
        me.fg = [[1.0, 1.0, 1.0, 1.0]]; 
        #
        # "private"
        me.title = "About";
        me.dialog = nil;
        me.namenode = props.Node.new({"dialog-name" : me.title });
    },
#################################################################
    create : func {
        if (me.dialog != nil)
            me.close();

        me.dialog = gui.Widget.new();
        me.dialog.set("name", me.title);
        if (me.x != nil)
            me.dialog.set("x", me.x);
        if (me.y != nil)
            me.dialog.set("y", me.y);

        me.dialog.set("layout", "vbox");
        me.dialog.set("default-padding", 0);

        var titlebar = me.dialog.addChild("group");
        titlebar.set("layout", "hbox");
        titlebar.addChild("empty").set("stretch", 1);
        titlebar.addChild("text").set
            ("label",
             "About");
        var w = titlebar.addChild("button");
        w.set("pref-width", 16);
        w.set("pref-height", 16);
        w.set("legend", "");
        w.set("default", 0);
        w.set("key", "esc");
        w.setBinding("nasal", "SM.dialog.destroy(); ");
        w.setBinding("dialog-close");
        me.dialog.addChild("hrule");

        var content = me.dialog.addChild("group");
        content.set("layout", "vbox");
        content.set("halign", "center");
        content.set("default-padding", 5);
        props.globals.initNode("sim/about/text",
             "Flying Cat Hot Air Balloon Series Version 3.2 for FlightGear\n" ~
             "Copyright (C) 2016 Herbert Wagner\n\n" ~
             "Models in this series:\n" ~
             "HotAirSportBalloon, Green- and RedSportBalloon\n" ~
             "Flighing Cat -Robot and Minion\n" ~
             "for FlightGear flight simulator\n" ~
             "This is free software, and you are welcome to\n" ~
             "redistribute it under certain conditions.\n" ~
             "See the GNU GENERAL PUBLIC LICENSE Version 2 for the details.",
             "STRING");
        var text = content.addChild("textbox");
        text.set("halign", "fill");
        #text.set("slider", 20);
        text.set("pref-width", 400);
        text.set("pref-height", 300);
        text.set("editable", 0);
        text.set("property", "sim/about/text");

        #me.dialog.addChild("hrule");

        fgcommand("dialog-new", me.dialog.prop());
        fgcommand("dialog-show", me.namenode);
    },
#################################################################
    close : func {
        fgcommand("dialog-close", me.namenode);
    },
#################################################################
    destroy : func {
        ABOUT_DLG = 0;
        me.close();
        delete(gui.dialog, "\"" ~ me.title ~ "\"");
    },
#################################################################
    show : func {
        if (!ABOUT_DLG) {
            ABOUT_DLG = 1;
            me.init(400, getprop("/sim/startup/ysize") - 500);
            me.create();
        }
    }
};
###############################################################################

# Popup the about dialog.
var about = func {
    dialog.show();
}
