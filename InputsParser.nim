import json
import "Inputs.nim"

type
  Coef = float
  Temperature = float
  Pressure = float

  InputData = tuple
    Composition : Composition
    MeterInternalDiameter : MeterInternalDiameter
    OrificePlateBoreDiameter : OrificePlateBoreDiameter
    PipeExpansionCoef : Coef
    OrificePlateExpansionCoef : Coef
    BaseTemp : Temperature
    BasePressure : Pressure


proc parseInput*(jsonStr: string): InputData =
  let jsonNode = parseJson(jsonStr)
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

  result[1] = jsonNode["meterInternalDiameter"].getFloat()
  result[2] = jsonNode["orificePlateBoreDiameter"].getFloat()

  result[3] = jsonNode["pipeExpansionCoef"].getFloat()
  result[4] = jsonNode["orificePlateExpansionCoef"].getFloat()

  result[5] = jsonNode["baseTemp"].getFloat()
  result[6] = jsonNode["basePressure"].getFloat()
