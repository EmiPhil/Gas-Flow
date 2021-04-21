import parseopt
import strutils

import "src/orificeCalculator.nim"

include "src/orificeCalculatorpkg/inputsParser.nim"

var p = initOptParser()

var
  inputJson : string = ""
  flowTemp : Temperature # deg C
  flowPressure : Pressure # Pa
  differentialPressure : Pressure # Pa
  raw : bool = false

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
    of "r": raw = true
  of cmdArgument:
    inputJson = p.key

if inputJson == "":
  inputJson = "input.json"

var jsonData : string = inputJson
if strutils.endsWith(inputJson, ".json"):
  jsonData = readFile(inputJson)

var
  (
    composition,
    pipeInternalDiameter,
    orificeInternalDiameter,
    alphaPipe,
    alphaOrifice,
    baseTemp,
    basePressure,
    diffLo
  ) = parseInput(jsonData)

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
  basePressure,
  diffLo
)

if raw:
  echo flows.Base
else:
  echo flows.Base * 3051.187, " MCF/day"
