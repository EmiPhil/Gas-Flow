import json

proc parseInput(jsonStr: string): Composition =
  let jsonNode = parseJson(jsonStr)
  let comp = jsonNode["composition"]

  result[0]   = comp["methane"].getFloat()
  result[1]   = comp["ethane"].getFloat()
  result[2]   = comp["propane"].getFloat()
  result[3]   = comp["isoButane"].getFloat()
  result[4]   = comp["n-Butane"].getFloat()
  result[5]   = comp["isoPentane"].getFloat()
  result[6]   = comp["n-Pentane"].getFloat()
  result[7]   = comp["n-Hexane"].getFloat()
  result[8]   = comp["n-Heptane"].getFloat()
  result[9]   = comp["n-Octane"].getFloat()
  result[10]  = comp["n-Nonane"].getFloat()
  result[11]  = comp["n-Decane"].getFloat()
  result[12]  = comp["hydrogen"].getFloat()
  result[13]  = comp["oxygen"].getFloat()
  result[14]  = comp["nitrogen"].getFloat()
  result[15]  = comp["helium"].getFloat()
  result[16]  = comp["argon"].getFloat()
  result[17]  = comp["water"].getFloat()
  result[18]  = comp["hydrogenSulfide"].getFloat()
  result[19]  = comp["carbonMonoxide"].getFloat()
  result[20]  = comp["carbonDioxide"].getFloat()
