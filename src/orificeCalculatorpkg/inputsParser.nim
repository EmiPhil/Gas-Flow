import json
include "inputs.nim"

type
  Coef = float
  Temperature = float
  Pressure = float

  InputData* = tuple
    Composition : Composition
    PipeInternalDiameter : PipeInternalDiameter
    OrificePlateBoreDiameter : OrificePlateBoreDiameter
    PipeExpansionCoef : Coef
    OrificePlateExpansionCoef : Coef
    BaseTemp : Temperature
    BasePressure : Pressure
    DiffLo : Pressure

proc parseGasflowJson*(jsonNode: JsonNode): InputData =
  let comp = jsonNode["composition"]

  result[0][1]  = comp["methane"].getFloat()
  result[0][2]  = comp["nitrogen"].getFloat()
  result[0][3]  = comp["carbonDioxide"].getFloat()
  result[0][4]  = comp["ethane"].getFloat()
  result[0][5]  = comp["propane"].getFloat()
  result[0][6]  = comp["isoButane"].getFloat()
  result[0][7]  = comp["n-Butane"].getFloat()
  result[0][8]  = comp["isoPentane"].getFloat()
  result[0][9]  = comp["n-Pentane"].getFloat()
  result[0][10] = comp["n-Hexane"].getFloat()
  result[0][11] = comp["n-Heptane"].getFloat()
  result[0][12] = comp["n-Octane"].getFloat()
  result[0][13] = comp["n-Nonane"].getFloat()
  result[0][14] = comp["n-Decane"].getFloat()
  result[0][15] = comp["hydrogen"].getFloat()
  result[0][16] = comp["oxygen"].getFloat()
  result[0][17] = comp["carbonMonoxide"].getFloat()
  result[0][18] = comp["water"].getFloat()
  result[0][19] = comp["hydrogenSulfide"].getFloat()
  result[0][20] = comp["helium"].getFloat()
  result[0][21] = comp["argon"].getFloat()

  #var total : float = 0
  for i in 1..CompCount:
  #  total += result[0][i]
    result[0][i] /= 100 # * AGA8 expects mol mass to add up to 1
  # if total != 100.0:
    # echo "WARN: Mol masses do not exactly equal 100 (", total, ")."
    

  result[1] = jsonNode["pipeInternalDiameter"].getFloat()
  result[2] = jsonNode["orificePlateBoreDiameter"].getFloat()

  result[3] = jsonNode["pipeExpansionCoef"].getFloat()
  result[4] = jsonNode["orificePlateExpansionCoef"].getFloat()

  result[5] = jsonNode["baseTemp"].getFloat()
  result[6] = jsonNode["basePressure"].getFloat()

  result[7] = jsonNode{"diffLo"}.getFloat(300.0)

proc parseInput*(jsonStr: string): InputData =
  result = parseGasflowJson(parseJson(jsonStr))
