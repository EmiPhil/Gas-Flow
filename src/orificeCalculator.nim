import math

include "orificeCalculatorpkg/inputsParser.nim"
import "orificeCalculatorpkg/aga8/detail.nim"
import "orificeCalculatorpkg/aga3/aga3.nim"

type
  Flows = tuple
    Mass : float
    Actual : float
    Base : float

proc molLToKgm3 (molarMass : MolarMass, density : Density) : Density =
  # ? molarMass is in g/mol
  # ? density is in mol/l
  result = density * molarMass

proc orificeCalculator*(
  flowTemp : float,
  flowPressure : float,
  differentialPressure: float,

  composition : Composition,
  pipeInternalDiameter : float,
  orificeInternalDiameter : float,
  alphaPipe : float,
  alphaOrifice : float,
  baseTemp : float,
  basePressure : float,
  diffLo = 137.8951
) : Flows {.exportc.} =
  if differentialPressure <= diffLo:
    result = (
      0.0,
      0.0,
      0.0
    )
    return

  var
    # ? deg C to deg K
    fT : float = flowTemp + 273.15
    bT : float = baseTemp + 273.15

    # ? mm to m
    pipeId : float = pipeInternalDiameter / 1000
    orificeId : float = orificeInternalDiameter / 1000

    # ? To proper decimal level
    pipeA : float = alphaPipe * pow(10, -6.0)
    orificeA : float = alphaOrifice * pow(10, -6.0)

  var # ? AGA8
    baseDensity : DDetail = DensityDetail(bT, basePressure / 1_000, composition)
    baseProperties : GasBlendProps = PropertiesDetail(bT, baseDensity.Density, composition)

    density : DDetail = DensityDetail(fT, flowPressure / 1_000, composition)
    properties: GasBlendProps = PropertiesDetail(fT, density.Density, composition)

  var # ? AGA3
    orificeDiameter : Diameter = thermalExpansion(orificeA, orificeId, ReferenceTemp, fT)
    meterDiameter : Diameter = thermalExpansion(pipeA, pipeId, ReferenceTemp, fT)

    beta : Beta = diameterRatio(orificeDiameter, meterDiameter)
    velocityFactor : Velocity = velocityFactor(beta)

    dischargeCoefs : OrificeCoefsOfDischarge = dischargeConstants(meterDiameter, beta)

  var
    Kappa : float
    SiBaseDensity : Density = molLToKgm3(baseProperties.MolarMass, baseDensity.Density)
    SiDensity : Density = molLToKgm3(properties.MolarMass, density.Density)

  if properties.Kappa > 0:
    Kappa = properties.Kappa
  else:
    Kappa = 1

  var
    expansionFactor : ExpansionFactor = expansionFactor(
      beta,
      differentialPressure,
      flowPressure,
      Kappa
    )
    iterationFlowFactor : IterationFlowFactor = iterationFlowFactor(
      orificeDiameter,
      meterDiameter,
      differentialPressure,
      velocityFactor,
      0.0102680 / 1000,
      SiDensity,
      expansionFactor
    )
    dischargeCoefficient : DischargeCoef = dischargeCoefficient(dischargeCoefs, iterationFlowFactor)

  result = (
    massFlow(
      dischargeCoefficient.dFT,
      orificeDiameter,
      differentialPressure,
      velocityFactor,
      SiDensity,
      expansionFactor
    ),
    actualFlow(
      dischargeCoefficient.dFT,
      orificeDiameter,
      differentialPressure,
      velocityFactor,
      SiDensity,
      expansionFactor
    ),
    baseFlow(
      dischargeCoefficient.dFT,
      orificeDiameter,
      differentialPressure,
      velocityFactor,
      SiBaseDensity,
      SiDensity,
      expansionFactor
    )
  )

#[
  echo "d => ", orificeDiameter
  echo "D => ", meterDiameter
  echo "beta => ", beta
  echo "velocity factor => ", velocityFactor
  echo "expansionFactor => ", expansionFactor
  echo "iterationFlowFactor => ", iterationFlowFactor
  echo "coefs => ", dischargeCoefs
  echo "discharge coef => ", dischargeCoefficient

  echo "Mass Flow => ", result.Mass, " ", MassFlowUnit
  echo "Actual Flow => ", result.Actual, " ", VolumeFlowUnit
  echo "Base Flow => ", result.Base, " ", VolumeFlowUnit

  echo "Base density => ", SiBaseDensity
  echo "Blend density => ", SiDensity
  echo "Kappa => ", Kappa

  echo "Props => ", properties

]#
