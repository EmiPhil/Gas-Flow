import parseopt
import strutils

import "OrificeCalculator.nim"

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

var
  (
    composition,
    pipeInternalDiameter,
    orificeInternalDiameter,
    alphaPipe,
    alphaOrifice,
    baseTemp,
    basePressure
  ) = parseInput(readFile(inputJson))

var flows = orificeCalculator(
  flowTemp,
  flowPressure,
  differentialPressure,

  composition,
  pipeInternalDiameter,
  orificeInternalDiameter,
  alphaPipe,
  alphaOrifice,
  baseTemp,
  basePressure
)

echo flows.Base * 3051.187, " MCF/day"
