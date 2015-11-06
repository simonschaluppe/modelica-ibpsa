within Annex60.Experimental.Pipe;
model DoublePipe "Pipe model for double pipe case"
  extends BaseClasses.PartialFourPort;

  output Modelica.SIunits.HeatFlowRate heat_losses "Heat losses in this pipe";

  parameter Modelica.SIunits.Diameter diameter "Pipe diameter";
  parameter Modelica.SIunits.Length length "Pipe length";
  parameter Modelica.SIunits.Length thicknessIns "Thickness of pipe insulation";

  /*parameter Modelica.SIunits.ThermalConductivity k = 0.005 
    "Heat conductivity of pipe's surroundings";*/

  parameter Modelica.SIunits.MassFlowRate m_flow_nominal
    "Nominal mass flow rate"
  annotation(Dialog(group = "Nominal condition"));

  parameter Modelica.SIunits.MassFlowRate m_flow_small(min=0) = 1E-4*abs(m_flow_nominal)
    "Small mass flow rate for regularization of zero flow"
    annotation(Dialog(tab = "Advanced"));

  parameter Modelica.SIunits.Height roughness=2.5e-5
    "Average height of surface asperities (default: smooth steel pipe)"
      annotation(Dialog(group="Geometry"));

  parameter Modelica.SIunits.Pressure dp_nominal(displayUnit="Pa")= 2*dpStraightPipe_nominal
    "Pressure drop at nominal mass flow rate"
    annotation(Dialog(group = "Nominal condition"));

  final parameter Modelica.SIunits.Pressure dpStraightPipe_nominal=
      Modelica.Fluid.Pipes.BaseClasses.WallFriction.Detailed.pressureLoss_m_flow(
      m_flow=m_flow_nominal,
      rho_a=rho_default,
      rho_b=rho_default,
      mu_a=mu_default,
      mu_b=mu_default,
      length=length,
      diameter=diameter,
      roughness=roughness,
      m_flow_small=m_flow_small)
    "Pressure loss of a straight pipe at m_flow_nominal";

  // FIXME: Resistances must be calculated according to pipe lay-out
  parameter Modelica.SIunits.ThermalConductivity Ra = 1 / (lambdaI*2*Modelica.Constants.pi/Modelica.Math.log((diameter/2+thicknessIns)/(diameter/2)))
    "Resistance for asymmetric problem, in K/W";
  parameter Modelica.SIunits.ThermalConductivity Rs = 2 /1 / (lambdaI*2*Modelica.Constants.pi/Modelica.Math.log((diameter/2+thicknessIns)/(diameter/2)))
    "Resistance for symmetric problem, in K/W";
  final parameter Real C=rho_default*Modelica.Constants.pi*(diameter/2)^2*cp_default;
  parameter Modelica.SIunits.ThermalConductivity lambdaI=0.026
    "Heat conductivity";

  // fixme: shouldn't dp(nominal) be around 100 Pa/m?
  // fixme: propagate use_dh and set default to false

protected
  parameter Medium.ThermodynamicState sta_default=
     Medium.setState_pTX(
       T=Medium.T_default,
       p=Medium.p_default,
       X=Medium.X_default) "Default medium state";

 parameter Modelica.SIunits.Density rho_default=
      Medium.density_pTX(
       p=Medium.p_default,
       T=Medium.T_default,
       X=Medium.X_default)
    "Default density (e.g., rho_liquidWater = 995, rho_air = 1.2)"
    annotation(Dialog(group="Advanced", enable=use_rho_nominal));

 parameter Modelica.SIunits.DynamicViscosity mu_default=
    Medium.dynamicViscosity(Medium.setState_pTX(
      p=  Medium.p_default,
      T=  Medium.T_default,
      X=  Medium.X_default))
    "Default dynamic viscosity (e.g., mu_liquidWater = 1e-3, mu_air = 1.8e-5)"
    annotation(Dialog(group="Advanced", enable=use_mu_default));

  PipeAdiabaticPlugFlow pipeSupplyAdiabaticPlugFlow(
    redeclare final package Medium = Medium,
    final m_flow_small=m_flow_small,
    final allowFlowReversal=allowFlowReversal,
    diameter=diameter,
    length=length,
    m_flow_nominal=m_flow_nominal)
    "Model for temperature wave propagation with spatialDistribution operator and hydraulic resistance"
    annotation (Placement(transformation(extent={{-10,50},{10,70}})));

  parameter Modelica.SIunits.SpecificHeatCapacity cp_default=
    Medium.specificHeatCapacityCp(state=sta_default) "Heat capacity of medium";

public
  Modelica.Blocks.Interfaces.RealInput T_amb
    "Ambient temperature for pipe's surroundings" annotation (Placement(
        transformation(
        extent={{-20,-20},{20,20}},
        rotation=270,
        origin={0,100})));
  BaseClasses.HeatLossDouble heatLossSupplyReverse(
    redeclare package Medium = Medium,
    diameter=diameter,
    length=length,
    thicknessIns=thicknessIns,
    C=C,
    Ra=Ra,
    Rs=Rs) annotation (Placement(transformation(extent={{-40,50},{-60,70}})));
  BaseClasses.HeatLossDouble heatLossSupply(
    redeclare package Medium = Medium,
    diameter=diameter,
    length=length,
    thicknessIns=thicknessIns,
    C=C,
    Ra=Ra,
    Rs=Rs)
    annotation (Placement(transformation(extent={{40,50},{60,70}})));
protected
  PipeAdiabaticPlugFlow pipeReturnAdiabaticPlugFlow(
    redeclare final package Medium = Medium,
    final m_flow_small=m_flow_small,
    final allowFlowReversal=allowFlowReversal,
    diameter=diameter,
    length=length,
    m_flow_nominal=m_flow_nominal)
    "Model for temperature wave propagation with spatialDistribution operator and hydraulic resistance"
    annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=180,
        origin={0,-60})));
public
  BaseClasses.HeatLossDouble heatLossReturn(
    redeclare package Medium = Medium,
    diameter=diameter,
    length=length,
    thicknessIns=thicknessIns,
    C=C,
    Ra=Ra,
    Rs=Rs) annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=180,
        origin={-50,-60})));
  BaseClasses.HeatLossDouble heatLossReturnReverse(
    redeclare package Medium = Medium,
    diameter=diameter,
    length=length,
    thicknessIns=thicknessIns,
    C=C,
    Ra=Ra,
    Rs=Rs) annotation (Placement(
        transformation(
        extent={{10,-10},{-10,10}},
        rotation=180,
        origin={50,-60})));
  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;

equation
  heat_losses = actualStream(port_b1.h_outflow) - actualStream(port_a1.h_outflow) + actualStream(port_a2.h_outflow) - actualStream(port_b2.h_outflow);

  connect(port_a1, heatLossSupplyReverse.port_b)
    annotation (Line(points={{-100,60},{-80,60},{-60,60}}, color={0,127,255}));
  connect(heatLossSupplyReverse.port_a, pipeSupplyAdiabaticPlugFlow.port_a)
    annotation (Line(points={{-40,60},{-10,60}}, color={0,127,255}));
  connect(pipeSupplyAdiabaticPlugFlow.port_b, heatLossSupply.port_a)
    annotation (Line(points={{10,60},{26,60},{40,60}}, color={0,127,255}));
  connect(heatLossSupply.port_b, port_b1)
    annotation (Line(points={{60,60},{80,60},{100,60}}, color={0,127,255}));
  connect(port_b2, heatLossReturn.port_b) annotation (Line(points={{-100,-60},{-80,
          -60},{-60,-60}}, color={0,127,255}));
  connect(heatLossReturn.port_a, pipeReturnAdiabaticPlugFlow.port_b)
    annotation (Line(points={{-40,-60},{-26,-60},{-10,-60}}, color={0,127,255}));
  connect(pipeReturnAdiabaticPlugFlow.port_a, heatLossReturnReverse.port_a)
    annotation (Line(points={{10,-60},{26,-60},{40,-60}}, color={0,127,255}));
  connect(heatLossReturnReverse.port_b, port_a2) annotation (Line(points={{60,-60},
          {100,-60},{100,-60}}, color={0,127,255}));
  connect(heatLossSupplyReverse.T_2out, heatLossReturnReverse.T_2in)
    annotation (Line(points={{-56,50},{-56,50},{-56,-6},{44,-6},{44,-50}},
        color={0,0,127}));
  connect(heatLossReturnReverse.T_2out, heatLossSupplyReverse.T_2in)
    annotation (Line(points={{56,-50},{56,-50},{56,-2},{-44,-2},{-44,50}},
        color={0,0,127}));
  connect(heatLossReturn.T_2out, heatLossSupply.T_2in) annotation (Line(points={
          {-56,-50},{-56,-50},{-56,-46},{-56,-8},{44,-8},{44,50}}, color={0,0,127}));
  connect(heatLossSupply.T_2out, heatLossReturn.T_2in) annotation (Line(points={
          {56,50},{56,50},{56,2},{56,-12},{-44,-12},{-44,-50}}, color={0,0,127}));
  connect(heatLossSupplyReverse.T_amb, T_amb) annotation (Line(points={{-50,70},
          {-50,76},{0,76},{0,100}}, color={0,0,127}));
  connect(heatLossSupply.T_amb, T_amb) annotation (Line(points={{50,70},{50,76},
          {0,76},{0,100}}, color={0,0,127}));
  connect(heatLossReturn.T_amb, T_amb) annotation (Line(points={{-50,-70},{-50,-78},
          {-70,-78},{-70,76},{0,76},{0,100}}, color={0,0,127}));
  connect(heatLossReturnReverse.T_amb, T_amb) annotation (Line(points={{50,-70},
          {50,-78},{68,-78},{68,76},{0,76},{0,100}}, color={0,0,127}));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}})),           Icon(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
        Rectangle(
          extent={{-100,40},{100,-40}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Rectangle(
          extent={{-100,30},{100,-30}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={0,127,255}),
        Rectangle(
          extent={{-26,30},{30,-30}},
          lineColor={0,0,255},
          fillPattern=FillPattern.HorizontalCylinder),
        Rectangle(
          extent={{-100,50},{100,40}},
          lineColor={175,175,175},
          fillColor={255,255,255},
          fillPattern=FillPattern.Backward),
        Rectangle(
          extent={{-100,-40},{100,-50}},
          lineColor={175,175,175},
          fillColor={255,255,255},
          fillPattern=FillPattern.Backward),
                                          Polygon(
          points={{0,100},{40,62},{20,62},{20,38},{-20,38},{-20,62},{-40,62},{0,
              100}},
          lineColor={0,0,0},
          fillColor={238,46,47},
          fillPattern=FillPattern.Solid)}),
    Documentation(revisions="<html>
<ul>
<li>
October 10, 2015 by Marcus Fuchs:<br/>
Copy Icon from KUL implementation and rename model; Replace resistance and temperature delay by an adiabatic pipe;
</li>
<li>
September, 2015 by Marcus Fuchs:<br/>
First implementation.
</li>
</ul>
</html>", info="<html>
<p>First implementation of a pipe with heat loss using the fixed resistance from Annex60 and the spatialDistribution operator for the temperature wave propagation through the length of the pipe. </p>
<p>This setup is meant as a benchmark for more sophisticated implementations. It seems to generally work ok except for the cooling effects on the standing fluid in case of zero mass flow.</p>
<p>The heat loss component adds a heat loss in design direction, and leaves the enthalpy unchanged in opposite flow direction. Therefore it is used before and after the time delay.</p>
</html>"));
end DoublePipe;
