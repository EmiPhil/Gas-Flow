type
  Elevation = float
  AtmosphericPressure = float

proc calculateAtmosphericPressure(elevation: Elevation) : AtmosphericPressure =
  var
    # I'm not sure what these mean
    a : float = 14.54
    b : float = 55_096
    c : float = 361

  result = a * ((b - (elevation - c)) / (b + (elevation - c)))
