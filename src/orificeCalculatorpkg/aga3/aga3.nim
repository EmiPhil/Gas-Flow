# ? Input variables in SI
import math

type
  Length* = float
  Diameter* = Length

  Temperature* = float
  Pressure* = float

  Density* = float

  VolumeFlow* = float
  MassFlow* = VolumeFlow

  Alpha* = float
  Viscosity* = float
  Velocity* = float

  MolecularWeight* = float

  Ratio* = float
  Beta* = Ratio

  Coef* = float

type
  unit = string

const
  LengthUnit* : unit = "m"
  TempUnit* : unit = "deg K"

  PressureUnit* : unit = "Pa"
  OrificeDifferentialPressureUnit* = PressureUnit
  
  FluidDensityUnit* : unit = "kg/m^3"
  
  MassFlowUnit* = "kg/s"
  VolumeFlowUnit* : unit = "m^3/s"

  AlphaUnit* : unit = "m/m-K"
  
  ViscosityUnit* : unit = "Pa.s"

const
  R* : float = 8_314.51 # ? Universal gas constant
  AirMolWeight* : MolecularWeight = 28.9625

  DischargeCoefConversion : float = 0.0254
  
  ReferenceTemp* : Temperature = 293.15

proc thermalExpansion*(
  alpha : Alpha,
  diameter : Diameter, 
  referenceTemp : Temperature,
  flowTemp : Temperature
) : Diameter =
  # * AGA 3 procedure 4.3.2.1/4.3.2.2
  # * Calculation of Orifice Plate Bore/Meter Tube Diameter from Reference/Measured Diameter

  # ? alpha = coefficient of thermal expansion
  result = diameter * (1 + alpha * (flowTemp - referenceTemp))

proc diameterRatio*(orificePlateBoreDiameter : Diameter, meterInternalDiameter : Diameter) : Beta =
  # * AGA 3 procedure 4.3.2.3
  # * Calculation of Flowing Diameter Ratio (beta) from Meter Tube and Orifice Bore Diameters
  # ? Input diameters should be at flowing conditions
  result = orificePlateBoreDiameter / meterInternalDiameter

proc velocityFactor*(beta : Beta) : Velocity =
  # * AGA 3 procedure 4.3.2.4
  # * Calculation of Velocity of Approach Factor
  # ? Beta from diameterRatio
  result = 1 / sqrt(1 - pow(beta, 4))

type
  OrificeCoefsOfDischarge* = tuple
    D0 : Coef
    D1 : Coef
    D2 : Coef
    D3 : Coef
    D4 : Coef

  DischargeParameters = tuple
    A : array[7, float]
    S : array[8, float]

const
  DischargeParams : DischargeParameters = (
    [0.5961, 0.0291, -0.229, 0.003, 2.8, 0.000511, 0.021],
    [0.0049, 0.0433, 0.0712, -0.1145, -0.2300, -0.0116, -0.5200, -0.1400],
  )


proc dischargeConstants*(meterInternalDiameter : Diameter, beta : Beta) : OrificeCoefsOfDischarge =
  # * AGA 3 procedure 4.3.2.5
  # * Calculation of Flange-Tapped Orifice Plate Coefficient of Discharge Constants
  # ? Beta from diameterRatio
  var
    Location1, Location2 : float
    DamHeight : float
    UpstreamTapCorrection, DownstreamTapCorrection : float
    SmallPipeCorrection : float
  
  # * Step 1. Calculate the dimensionless up and downstream locations
  Location1 = DischargeCoefConversion / meterInternalDiameter
  Location2 = DischargeCoefConversion / meterInternalDiameter

  # * Step 2. Calculate the dimensionless downstream dam height
  DamHeight = (2 * Location2) / (1 - beta)

  # * Step 3. Calculate up and downstream tap correction factors
  UpstreamTapCorrection = (
      DischargeParams.S[1] +
      DischargeParams.S[2] * pow(2.71828, (-8.5 * Location1)) +
      DischargeParams.S[3] * pow(2.71828, (-6.0 * Location2))
   ) * pow(beta, 4) / (1 - pow(beta, 4))

  DownstreamTapCorrection = DischargeParams.S[5] *
    (DamHeight + DischargeParams.S[6] * pow(DamHeight, 1.3)) * pow(beta, 1.1)

  # * Step 4. Calculate the small pipe correction factor
  if meterInternalDiameter > (DischargeParams.A[4] * DischargeCoefConversion):
    # * Large pipe
    SmallPipeCorrection = 0
  else:
    SmallPipeCorrection = DischargeParams.A[3] *
      (1 - beta) * (DischargeParams.A[4] - meterInternalDiameter / DischargeCoefConversion)

  # * Step 5. Calculate the orifice plate coefficient of discharge constants at Reynolds num of 4000
  result.D0 = DischargeParams.A[0] +
    DischargeParams.A[1] * pow(beta, 2) +
    DischargeParams.A[2] * pow(beta, 8) +
    UpstreamTapCorrection + DownstreamTapCorrection + SmallPipeCorrection
  result.D1 = DischargeParams.A[5] * pow(beta, 0.7) * pow(250, 0.7)
  result.D2 = DischargeParams.A[6] * pow(beta, 4) * pow(250, 0.35)
  result.D3 = DischargeParams.S[0] * pow(beta, 4) * pow(beta, 0.8) * pow(4.75, 0.8) * pow(250, 0.35)
  result.D4 = (DischargeParams.S[4] * UpstreamTapCorrection +
    DischargeParams.S[7] * DownstreamTapCorrection) * pow(beta, 0.8) * pow(4.75, 0.8)

proc upstreamPressure*(downstreamPressure : Pressure, differentialPressure : Pressure) : Pressure =
  # * AGA 3 procedure 4.3.2.6
  # * Calculation of Upstream Flowing Fluid Pressure from Downstream Static Pressure
  # ? downstreamPressure and upstreamPressure are the flowing pressures of those taps
  result = differentialPressure + downstreamPressure

type
  ExpansionFactor* = float

proc expansionFactor*(
  beta : Beta,
  differentialPressure : Pressure,
  flowPressure : Pressure,
  isentropicExponent : float
) : ExpansionFactor =
  # * AGA 3 procedure 4.3.2.7
  # * Calculation of Compressible Fluid Expansion Factor
  # ? beta from diameterRatio

  var
    DifferentialToFlowPressureRatio : Ratio
    ExpansionFactorPressureConst : float
  
  # * Step 1. Calculate the orifice differential pressure to flowing pressure ratio
  DifferentialToFlowPressureRatio = differentialPressure / flowPressure

  # * Step 2. Calculate the expansion factor pressure constant
  ExpansionFactorPressureConst = (0.41 + 0.35 * pow(beta, 4)) / isentropicExponent

  result = 1 - (ExpansionFactorPressureConst * DifferentialToFlowPressureRatio)

type
  IterationFlowFactor* = float

proc iterationFlowFactor*(
  orificePlateBoreDiameter : Diameter,
  meterInternalDiameter : Diameter,
  differentialPressure : Pressure,
  velocityFactor : Velocity, # ? E_v
  viscocity : Viscosity, # ? absolute (mu)
  density : Density, # ? rho_f
  expansionFactor : ExpansionFactor # ? Y
) : IterationFlowFactor =
  # * AGA procedure 3 4.3.2.8
  # * Calculation of Iteration Flow Factor
  var
    flowIc : float
    flowIp : float
  # * Step 1. Calculate intermediary values
  flowIc = (4000 * meterInternalDiameter * viscocity) /
    (velocityFactor * expansionFactor * pow(orificePlateBoreDiameter, 2))
  flowIp = sqrt(abs(2 * density * differentialPressure))

  # * Step 2. Test for limiting value of iteration flow factor and limir accordingly
  if flowIc < 1000 * flowIp:
    result = flowIc / flowIp
  else:
    result = 1000

type
  Flag = bool

  DischargeCoef* = tuple
    dFT : Coef
    flag : Flag

const
  ReynoldXSwitch : float = 1.142139337256165 # ? value of X where low Reynolds number switch occurs
  ReynoldLowA = 4.343524261523267 # ? correlation constant for low Reynolds number
  ReynoldLowB = 3.764387693320165 # ? correlation constant for low Reynolds number

proc dischargeCoefficient*(
  dischargeCoefs : OrificeCoefsOfDischarge,
  iterationFlowFactor : IterationFlowFactor
) : DischargeCoef =
  # * AGA 3 procedure 4.3.2.9
  # * Calculation of Flange-Tapped Orifice Plate Coefficient of Discharge

  var
    (d0, d1, d2, d3, d4) = dischargeCoefs
    coef : float = 1
    reynolds : float
    r35 : float # ? reynolds ^ 0.35
    r70 : float # ? reynolds ^ 0.70
    rlbr : float # ? ReynoldsLowB / reynolds
    r80 : float # ? reynolds ^ 0.80
    fC : float
    dC : float

  # * Step 1.  Initialize C_dFT to a value at infinite Reynolds number
  result.dFt = d0
  result.flag = false

  # * Steps 2, 3, 4, 5: 
  # * 2. Calculate reynolds, the ratio of 4000 to the assumed Reynolds number
  # * 3. Calculate correlation value of dFT, fC at the assumed Reynolds number, and the derivaitive
  # *    of the correlation with respect to the assumed value of dFT, dC, then
  # * 4. Calculate the amount to change the guess for dFT, coef
  # * 5. Iterate until the absolute value of coef is less than 0.000005
  while abs(coef) >= 0.000005:
    # * Step 2
    reynolds = iterationFlowFactor / result.dFt
    r80 = pow(reynolds, 0.80)
    # * Step 3
    if reynolds < ReynoldXSwitch:
      r35 = pow(reynolds, 0.35)

      fC = d0 + (d1 * r35 + d2 + d3 * r80) * r35 + d4 * r80
      dC = (0.7 * d1 * r35 + 0.35 * d2 + 1.15 * d3 * r80) * r35 + 0.8 * d4 * r80
    else:
      r70 = pow(reynolds, 0.70)
      rlbr = ReynoldLowB / reynolds
      fC = d0 + d1 * r70 + (d2 + d3 * r80) * (ReynoldLowA - rlbr) + d4 * r80
      dC = 0.7 * d1 * r70 + (d2 + d3 * r80) * rlbr + 0.8 * d3 * (ReynoldLowA - rlbr) * r80 +
        0.8 * d4 * r80
    # * Step 4
    coef = (result.dFT - fC) / (1 + dC / result.dFT)
    result.dFT = result.dFT - coef
  
  # * Step 6. If the value of reynolds > 1, set flag
  if reynolds > 1:
    result.flag = true

proc massFlow*(
  dischargeCoef : Coef, # ? dFT
  orificePlateBoreDiameter : Diameter,
  differentialPressure : Pressure,
  velocityFactor : Velocity, # ? E_v
  density : Density, # ? rho_f
  expansionFactor : ExpansionFactor # ? Y
) : MassFlow =
  # * AGA 3 procedure 4.3.2.10
  # * Calculation of Mass Flow Rate
  
  var flowMass : float = (PI / 4) * velocityFactor * pow(orificePlateBoreDiameter, 2)
  result = flowMass * dischargeCoef * expansionFactor * sqrt(abs(2 * density * differentialPressure))

  if (differentialPressure < 0):
    result *= -1

proc actualFlow*(
  dischargeCoef : Coef, # ? dFT
  orificePlateBoreDiameter : Diameter,
  differentialPressure : Pressure,
  velocityFactor : Velocity, # ? E_v
  density : Density, # ? rho_f
  expansionFactor : ExpansionFactor # ? Y
) : MassFlow =
  # * AGA 3 procedure 4.3.2.11
  # * Calculation of Volume Flow Rate at Flowing (Actual) Conditions

  result = massFlow(dischargeCoef, orificePlateBoreDiameter, differentialPressure,
    velocityFactor, density, expansionFactor) / density

proc baseFlow*(
  dischargeCoef : Coef, # ? dFT
  orificePlateBoreDiameter : Diameter,
  differentialPressure : Pressure,
  velocityFactor : Velocity, # ? E_v
  baseDensity: Density, # ? rho_b
  density : Density, # ? rho_f
  expansionFactor : ExpansionFactor # ? Y
) : MassFlow =
  # * AGA 3 procedure 4.3.2.12
  # * Calculation of Volume Flow Rate at Base (Standard) Conditions
  result = massFlow(dischargeCoef, orificePlateBoreDiameter, differentialPressure,
    velocityFactor, density, expansionFactor) / baseDensity
