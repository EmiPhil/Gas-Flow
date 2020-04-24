import parseopt
import math
import strutils

import "AGA8/Detail.nim"
import "AGA3/AGA3.nim"

include "InputsParser.nim"

var p = initOptParser()

var
  inputJson : string = ""
  flowTemp : Temperature # deg C
  flowPressure : Pressure # Pa
  differentialPressure : Pressure # Pa

while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
    case p.key
    of "i", "input": inputJson = p.val
    of "fT", "flowTemp", "flowTemperature": flowTemp = parseFloat(p.val)
    of "fP", "flowPressure": flowPressure = parseFloat(p.val)
    of "dP", "differentialPressure": differentialPressure = parseFloat(p.val)
  of cmdArgument:
    inputJson = p.key

if inputJson == "":
  inputJson = "input.json"

flowTemp += 273.15 # ? deg c to deg Kelvin

var
  (
    composition,
    meterInternalDiameter,
    orificePlateBoreDiameter,
    alphaPipe,
    alphaOrifice,
    baseTemp,
    basePressure
  ) = parseInput(readFile(inputJson))

meterInternalDiameter /= 1000 # ? mm to m
orificePlateBoreDiameter /= 1000
alphaPipe *= pow(10, -6.0)
alphaOrifice *= pow(10, -6.0)
baseTemp += 273.15 # ? deg c to deg Kelvin

var # ? AGA8
  baseDensity : DDetail = DensityDetail(baseTemp, basePressure / 1_000, composition)
  baseProperties : GasBlendProps = PropertiesDetail(baseTemp, baseDensity.Density, composition)

  density : DDetail = DensityDetail(flowTemp, flowPressure / 1_000, composition)
  properties: GasBlendProps = PropertiesDetail(flowTemp, density.Density, composition)

var # ? AGA3
  orificeDiameter : Diameter = thermalExpansion(alphaOrifice, orificePlateBoreDiameter, ReferenceTemp, flowTemp)
  meterDiameter : Diameter = thermalExpansion(alphaPipe, meterInternalDiameter, ReferenceTemp, flowTemp)

  beta : Beta = diameterRatio(orificeDiameter, meterDiameter)
  velocityFactor : Velocity = velocityFactor(beta)

  dischargeCoefs : OrificeCoefsOfDischarge = dischargeConstants(meterDiameter, beta)

proc molLToKgm3 (molarMass : MolarMass, density : Density) : Density =
  # ? molarMass is in g/mol
  # ? density is in mol/l
  result = density * molarMass

var
  Kappa : float
  SiBaseDensity : Density = molLToKgm3(baseProperties.MolarMass, baseDensity.Density)
  SiDensity : Density = molLToKgm3(properties.MolarMass, density.Density)

if properties.Kappa > 0:
  Kappa = properties.Kappa
else:
  Kappa = 1

type
  Flows = tuple
    Mass : MassFlow
    Actual : MassFlow
    Base : MassFlow

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

var flows : Flows = (
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

  echo "Mass Flow => ", flows.Mass, " ", MassFlowUnit
  echo "Actual Flow => ", flows.Actual, " ", VolumeFlowUnit
  echo "Base Flow => ", flows.Base, " ", VolumeFlowUnit

  echo baseDensity
  echo baseProperties
  echo density
  echo properties
]#

echo flows.Base * 3051.187, " MCF/day"
