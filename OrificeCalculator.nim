import parseopt

include "data/GasCompositions.nim"
include "ReadJson.nim"

var p = initOptParser()
var inputJson : string = ""

while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
    echo p.key
  of cmdArgument:
    inputJson = p.key

if inputJson == "":
  inputJson = "composition.json"

var
  composition : Composition = parseInput(readFile(inputJson))

var
  test: GasBlend = calcGasBlend(composition)
  props: GasBlendComponentProps = test.Props.GasBlendComponentProps

for name, i in gasIndex.fieldPairs:
  echo name, " => ", props[i].CalculatedProperties.RatioOfSpecificHeat

for name, i in test.fieldPairs:
  if name != "Props":
    echo name, " => ", i
