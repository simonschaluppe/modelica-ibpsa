within IBPSA.BoundaryConditions.WeatherData.BaseClasses;
block ConvertTime
  "Converts the simulation time to calendar time in scale of 1 year (365 days), or a multiple of a year if this is the length of the weather file"
  extends Modelica.Blocks.Icons.Block;

  parameter Modelica.SIunits.Time weaDatStaTim(displayUnit="d") "Start time of weather data";
  parameter Modelica.SIunits.Time weaDatEndTim(displayUnit="d") "End time of weather data";
  parameter Modelica.SIunits.Time weaDatAveInc(displayUnit="d") "Average increment of weather data";

  Modelica.Blocks.Interfaces.RealInput modTim(
    final quantity="Time",
    final unit="s") "Simulation time"
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  Modelica.Blocks.Interfaces.RealOutput calTim(
    final quantity="Time",
    final unit="s") "Calendar time"
    annotation (Placement(transformation(extent={{100,-10},{120,10}})));

protected
  constant Modelica.SIunits.Time year=31536000 "Number of seconds in a year";
  constant Modelica.SIunits.Time shiftSolarRad=1800 "Number of seconds for the shift for solar radiation calculation";
  discrete Modelica.SIunits.Time tStart "Start time of period";
  Boolean repeatWeatherFile(
    start = true,
    fixed=true) "true if the weather file should be repeated";

initial equation
  tStart = integer(modTim/year)*year;
equation
  when (modTim - pre(tStart)) > (weaDatEndTim+weaDatAveInc) then
    // simulation time stamp went over the last time stamp of the weather file + average increment
     if mod(weaDatEndTim-weaDatStaTim + weaDatAveInc, year) < 1 then
       // time span in weather file equal to a year or a multiple of it
      tStart = integer(modTim/year)*year; // the new start time is the start of the next year
      repeatWeatherFile = true;
     else
      tStart = pre(tStart);
      repeatWeatherFile = false;
     end if;
  end when;
  calTim = modTim - tStart;

  if repeatWeatherFile == false then
    assert((time - weaDatEndTim) < shiftSolarRad,
     "Insufficient weather data provided for the desired simulation period.",
     AssertionLevel.error);
  end if;
  annotation (
    defaultComponentName="conTim",
    Documentation(info="<html>
<p>
This component converts the simulation time to calendar time in a scale of 1 year (365 days).
</p>
</html>", revisions="<html>
<ul>
<li>
July 27, 2018, by Ana Constantin:<br/>
Added shift for multiple time spans.
</li>
<li>
September 27, 2011, by Wangda Zuo and Michael Wetter:<br/>
Modify it to convert negative value of time.
Use the when-then to allow dymola differentiating this model when
conducting index reduction which is not allowed in previous implementation.
</li>
<li>
February 27, 2011, by Wangda Zuo:<br/>
Renamed the component.
</li>
<li>
July 08, 2010, by Wangda Zuo:<br/>
First implementation.
</li>
</ul>
</html>"),
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
            100}}), graphics={
        Text(
          extent={{-98,6},{-74,-4}},
          lineColor={0,0,127},
          textString="modTim"),
        Text(
          extent={{74,6},{98,-4}},
          lineColor={0,0,127},
          textString="calTim"),
        Rectangle(
          extent={{-66,76},{60,58}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Solid,
          fillColor={120,120,120}),
        Rectangle(extent={{-66,58},{60,-62}}, lineColor={0,0,0}),
        Line(
          points={{-24,-62},{-24,58}}),
        Line(
          points={{18,-62},{18,58}}),
        Line(
          points={{60,28},{-66,28}}),
        Line(
          points={{60,-2},{-66,-2}}),
        Line(
          points={{60,-32},{-66,-32}})}));
end ConvertTime;
