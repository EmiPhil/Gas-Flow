const CompCount* = 21

type
  # ? Composition is a user defined array of the gasses in the gas blend
  Composition* = array[1..CompCount, float]

  MeterInternalDiameter* = float
  OrificePlateBoreDiameter* = float
