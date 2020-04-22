import parseopt
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

meterInternalDiameter /= 100 # ? cm to m
orificePlateBoreDiameter /= 100
baseTemp += 273.15 # ? deg c to deg Kelvin

var # ? AGA8
  baseDensity : DDetail = DensityDetail(baseTemp, basePressure / 1_000, composition, 1e10)
  baseProps : GasBlendProps = PropertiesDetail(baseTemp, baseDensity.Density, composition)

  density : DDetail = DensityDetail(flowTemp, flowPressure / 1_000, composition)
  properties: GasBlendProps = PropertiesDetail(flowTemp, density.Density, composition)

var # ? AGA3
  orificeDiameter : Diameter = thermalExpansion(alphaOrifice, orificePlateBoreDiameter, ReferenceTemp, flowTemp)
  meterDiameter : Diameter = thermalExpansion(alphaPipe, meterInternalDiameter, ReferenceTemp, flowTemp)

  beta : Beta = diameterRatio(orificeDiameter, meterDiameter)
  velocityFactor : Velocity = velocityFactor(beta)

  dischargeCoefs : OrificeCoefsOfDischarge = dischargeConstants(meterDiameter, beta)

var Kappa : float

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
    0.010268,
    density.Density,
    expansionFactor
  )
  dischargeCoefficient : DischargeCoef = dischargeCoefficient(dischargeCoefs, iterationFlowFactor)

var flows : Flows = (
  massFlow(
    dischargeCoefficient.dFT,
    orificeDiameter,
    differentialPressure,
    velocityFactor,
    density.Density,
    expansionFactor
  ),
  actualFlow(
    dischargeCoefficient.dFT,
    orificeDiameter,
    differentialPressure,
    velocityFactor,
    density.Density,
    expansionFactor
  ),
  baseFlow(
    dischargeCoefficient.dFT,
    orificeDiameter,
    differentialPressure,
    velocityFactor,
    baseDensity.Density,
    density.Density,
    expansionFactor
  )
)

#for name, flow in flows.fieldPairs:
#  echo name, " -> ", flow, " ", MassFlowUnit

echo baseDensity
echo baseProps

#echo density
#echo properties

#[
var
  test: GasBlend = calcGasBlend(composition)
  props: GasBlendComponentProps = test.Props.GasBlendComponentProps

for name, i in gasIndex.fieldPairs:
  echo name, " => ", props[i].CalculatedProperties.RatioOfSpecificHeat

for name, i in test.fieldPairs:
  if name != "Props":
    echo name, " => ", i
]#
