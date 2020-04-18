type
  MolecularWeight = float
  Molecule = tuple
    MW: MolecularWeight

const
  carbon   : Molecule = (MW: 12.01100)
  hydrogen : Molecule = (MW: 1.00794)
  oxygen   : Molecule = (MW: 15.99940)
  sulfur   : Molecule = (MW: 32.06600)
  nitrogen : Molecule = (MW: 14.00674)
  helium   : Molecule = (MW: 4.00260)
  argon    : Molecule = (MW: 39.94800)


# * A gas is made up of int molecules of any of the elements
type
  GasComp = tuple
    Carbon   :int
    Hydrogen :int
    Oxygen   :int
    Sulfur   :int
    Nitrogen :int
    Helium   :int
    Argon    :int

# * c_ for composition, eg composition_methane
const
  # ?                             C,  H,  O,  S,  N, He, Ar
  c_methane         : GasComp = ( 1,  4,  0,  0,  0,  0,  0)
  c_ethane          : GasComp = ( 2,  6,  0,  0,  0,  0,  0)
  c_propane         : GasComp = ( 3,  8,  0,  0,  0,  0,  0)
  c_isoButane       : GasComp = ( 4, 10,  0,  0,  0,  0,  0)
  c_nButane         : GasComp = ( 4, 10,  0,  0,  0,  0,  0)
  c_isoPentane      : GasComp = ( 5, 12,  0,  0,  0,  0,  0)
  c_nPentane        : GasComp = ( 5, 12,  0,  0,  0,  0,  0)
  c_nHexane         : GasComp = ( 6, 14,  0,  0,  0,  0,  0)
  c_nHeptane        : GasComp = ( 7, 16,  0,  0,  0,  0,  0)
  c_nOctane         : GasComp = ( 8, 18,  0,  0,  0,  0,  0)
  c_nNonane         : GasComp = ( 9, 20,  0,  0,  0,  0,  0)
  c_nDecane         : GasComp = (10, 22,  0,  0,  0,  0,  0)

  c_hydrogen        : GasComp = ( 0,  2,  0,  0,  0,  0,  0)
  c_oxygen          : GasComp = ( 0,  0,  2,  0,  0,  0,  0)
  c_nitrogen        : GasComp = ( 0,  0,  0,  0,  2,  0,  0)
  c_helium          : GasComp = ( 0,  0,  0,  0,  0,  1,  0)
  c_argon           : GasComp = ( 0,  0,  0,  0,  0,  0,  1)

  c_water           : GasComp = ( 0,  2,  1,  0,  0,  0,  0)
  c_hydrogenSulfide : GasComp = ( 0,  2,  0,  1,  0,  0,  0)

  c_carbonMonoxide  : GasComp = ( 1,  0,  1,  0,  0,  0,  0)
  c_carbonDioxide   : GasComp = ( 1,  0,  2,  0,  0,  0,  0)

type
  MolecularWeightArray = array[7, MolecularWeight]

proc
  calcMolWeight(composition: GasComp): MolecularWeight =
  var weights: MolecularWeightArray

  weights = [
    carbon.MW    * float(composition.Carbon),
    hydrogen.MW  * float(composition.Hydrogen),
    oxygen.MW    * float(composition.Oxygen),
    sulfur.MW    * float(composition.Sulfur),
    nitrogen.MW  * float(composition.Nitrogen),
    helium.MW    * float(composition.Helium),
    argon.MW     * float(composition.Argon)
  ]

  result = 0
  for weight in weights:
    result = result + weight


type
  Pressure              = float
  Temperature           = float # degrees F
  SpecificHeatCapacity  = float # Btu/lbm-R
  HeatingValue          = float # btu/scf

  Percentage            = float
  Ratio                 = float

  GasProperties = tuple
    CriticalPressure    : Pressure
    CriticalTemperature : Temperature

    ConstantPressureSHC : SpecificHeatCapacity
    ConstantVolumeSHC   : SpecificHeatCapacity

    GrossHV             : HeatingValue
    IdealHV             : HeatingValue
  
  GasCalculatedProperties = tuple
    CriticalPressurePercentage    : Percentage
    CriticalTemperaturePercentage : Percentage

    ConstantPressureSHCPercentage : Percentage
    ConstantVolumeSHCPercentage   : Percentage

    RatioOfSpecificHeat           : Ratio
    RatioOfSpecificHeatPercentage : Percentage

    GrossHVPercentage             : Percentage
    IdealHVPercentage             : Percentage

    Mass                          : float


const
  # ?                                      cp,      ct, cpSHC, cvSHC,  grossHV,  idealHV
  p_methane         : GasProperties = ( 667.0, -116.66, 0.532, 0.403, 1010.000,  909.400)
  p_ethane          : GasProperties = ( 707.8,   90.07, 0.427, 0.361, 1769.700, 1618.700)
  p_propane         : GasProperties = ( 615.0,  205.92, 0.407, 0.362, 2516.100, 2314.900)
  p_isoButane       : GasProperties = ( 527.9,  274.41, 0.415, 0.158, 3251.900, 3000.400)
  p_nButane         : GasProperties = ( 548.8,  305.51, 0.415, 0.158, 3262.300, 3010.800)
  p_isoPentane      : GasProperties = ( 490.4,  368.96, 0.000, 0.000, 4000.900, 3699.000)
  p_nPentane        : GasProperties = ( 488.1,  385.70, 0.000, 0.000, 4008.900, 3703.900)
  p_nHexane         : GasProperties = ( 439.5,  451.80, 0.540, 0.509, 4755.900, 4403.900)
  p_nHeptane        : GasProperties = ( 397.4,  510.90, 0.535, 0.510, 5502.500, 5100.300)
  p_nOctane         : GasProperties = ( 361.1,  563.50, 0.409, 0.392, 6248.900, 5796.200)
  p_nNonane         : GasProperties = ( 330.7,  610.80, 0.000, 0.000, 6996.500, 6493.600)
  p_nDecane         : GasProperties = ( 304.6,  652.20, 0.584, 0.570, 7742.900, 7189.900)
  
  p_hydrogen        : GasProperties = ( 187.5, -400.30, 3.430, 2.440,  324.200,  273.930)
  p_oxygen          : GasProperties = ( 731.4, -181.41, 0.219, 0.157,    0.000,    0.000)
  p_nitrogen        : GasProperties = ( 492.8, -232.49, 0.248, 0.177,    0.000,    0.000)
  p_helium          : GasProperties = ( 32.99, -450.31, 1.250, 0.753,    0.000,    0.000)
  p_argon           : GasProperties = ( 710.4, -188.12, 0.125, 0.076,    0.000,    0.000)
  
  p_water           : GasProperties = (3200.1,  705.11, 0.445, 0.335,   50.312,    0.000)
  p_hydrogenSulfide : GasProperties = (1300.0,  212.40, 0.243, 0.187,  637.100,  586.800)
  p_carbonMonoxide  : GasProperties = ( 506.8, -220.51, 0.249, 0.178,  320.500,  320.500)
  p_carbonDioxide   : GasProperties = (1069.5,   87.73, 0.203, 0.158,    0.000,    0.000)

type
  Gas = tuple
    GasComp: GasComp
    GasProperties: GasProperties
    MolecularWeight: MolecularWeight
  Gasses = array[21, Gas]
  GasIndex = tuple
    Methane         : int
    Ethane          : int
    Propane         : int
    IsoButane       : int
    NButane         : int
    IsoPentane      : int
    NPentane        : int
    NHexane         : int
    NHeptane        : int
    NOctane         : int
    NNonane         : int
    NDecane         : int
    Hydrogen        : int
    Oxygen          : int
    Nitrogen        : int
    Helium          : int
    Argon           : int
    Water           : int
    HydrogenSulfide : int
    CarbonMonoxide  : int
    CarbonDioxide   : int


const
  gasIndex : GasIndex = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)

const
  gasses : Gasses = [
    (c_methane         , p_methane         , calcMolWeight(c_methane)),
    (c_ethane          , p_ethane          , calcMolWeight(c_ethane)),
    (c_propane         , p_propane         , calcMolWeight(c_propane)),
    (c_isoButane       , p_isoButane       , calcMolWeight(c_isoButane)),
    (c_nButane         , p_nButane         , calcMolWeight(c_nButane)),
    (c_isoPentane      , p_isoPentane      , calcMolWeight(c_isoPentane)),
    (c_nPentane        , p_nPentane        , calcMolWeight(c_nPentane)),
    (c_nHexane         , p_nHexane         , calcMolWeight(c_nHexane)),
    (c_nHeptane        , p_nHeptane        , calcMolWeight(c_nHeptane)),
    (c_nOctane         , p_nOctane         , calcMolWeight(c_nOctane)),
    (c_nNonane         , p_nNonane         , calcMolWeight(c_nNonane)),
    (c_nDecane         , p_nDecane         , calcMolWeight(c_nDecane)),
    (c_hydrogen        , p_hydrogen        , calcMolWeight(c_hydrogen)),
    (c_oxygen          , p_oxygen          , calcMolWeight(c_oxygen)),
    (c_nitrogen        , p_nitrogen        , calcMolWeight(c_nitrogen)),
    (c_helium          , p_helium          , calcMolWeight(c_helium)),
    (c_argon           , p_argon           , calcMolWeight(c_argon)),
    (c_water           , p_water           , calcMolWeight(c_water)),
    (c_hydrogenSulfide , p_hydrogenSulfide , calcMolWeight(c_hydrogenSulfide)),
    (c_carbonMonoxide  , p_carbonMonoxide  , calcMolWeight(c_carbonMonoxide)),
    (c_carbonDioxide   , p_carbonDioxide   , calcMolWeight(c_carbonDioxide)),
  ]


type
  Composition = array[21, float]

const
  FtoRankine : float = 459.67

proc calcProperties(
  prop: GasProperties,
  percentage: Percentage,
  weight: MolecularWeight,
  name: string
): GasCalculatedProperties =
  var
    ratioSpecificHeat: HeatingValue
  
  case name
  of "IsoPentane", "NPentane":
    ratioSpecificHeat = 1.075
  of "NNonane":
    ratioSpecificHeat = 1.042
  else:
    ratioSpecificHeat = prop.ConstantPressureSHC / prop.ConstantVolumeSHC

  result = (
    prop.CriticalPressure * percentage,
    (prop.CriticalTemperature + FtoRankine) * percentage,

    prop.ConstantPressureSHC * percentage,
    prop.ConstantVolumeSHC * percentage,

    ratioSpecificHeat,
    (ratioSpecificHeat * percentage) / 100,

    (prop.GrossHV * percentage) / 100,
    (prop.IdealHV * percentage) / 100,

    weight * percentage
  )


type
  GasBlendComponentProp = tuple
    Properties: GasProperties
    CalculatedProperties: GasCalculatedProperties

  GasBlendComponentProps = array[21, GasBlendComponentProp]

  GasBlendProps = tuple
    Mass: MolecularWeight
    GasBlendComponentProps: GasBlendComponentProps


proc calcAllProperties(comp: Composition): GasBlendProps =
  var
    gas: Gas
    gasProps: GasBlendComponentProp
    resultArray: GasBlendComponentProps
    mass: float
  for name, i in gasIndex.fieldPairs:
    gas = gasses[i]
    gasProps = (
      gas.GasProperties,
      calcProperties(gas.GasProperties, comp[i], gas.MolecularWeight, name)
    )
    mass = mass + gasProps.CalculatedProperties.Mass
    resultArray[i] = gasProps
  result = (mass / 100, resultArray)


type
  SpecificGravity         = float
  DensityAtBaseConditions = float

  CriticalPressure        = float
  CriticalTemperature     = float
  RatioSpecificHeats      = float

  GasBlendData = tuple
    HigherHeatingValue      : HeatingValue
    LowerHeatingValue       : HeatingValue

    CriticalPressure        : CriticalPressure
    CriticalTemperature     : CriticalTemperature
    RatioSpecificHeats      : RatioSpecificHeats

  GasBlend = tuple
    Props: GasBlendProps

    SpecificGravity         : SpecificGravity

    HigherHeatingValue      : HeatingValue
    LowerHeatingValue       : HeatingValue

    CriticalPressure        : CriticalPressure
    CriticalTemperature     : CriticalTemperature
    RatioSpecificHeats      : RatioSpecificHeats

proc calcGasBlendSpecificGravity(mass: MolecularWeight): SpecificGravity =
  var
    oxygenMultiplier : float = 0.2095
    oxygen : MolecularWeight = calcMolWeight(c_oxygen)
    nitrogenMultiplier : float = 0.7805
    nitrogen: MolecularWeight = calcMolWeight(c_nitrogen)

  result = mass / (oxygen * oxygenMultiplier + nitrogen * nitrogenMultiplier)

proc calcGasBlendData(componentProps: GasBlendComponentProps): GasBlendData =
  for i in low(componentProps)..high(componentProps):
    result[0] = result[0] + componentProps[i].CalculatedProperties.GrossHVPercentage
    result[1] = result[1] + componentProps[i].CalculatedProperties.IdealHVPercentage
    result[2] = result[2] + componentProps[i].CalculatedProperties.CriticalPressurePercentage
    result[3] = result[3] + componentProps[i].CalculatedProperties.CriticalTemperaturePercentage
    result[4] = result[4] + componentProps[i].CalculatedProperties.RatioOfSpecificHeatPercentage
  result[2] = result[2] / 100
  result[3] = result[3] / 100

proc calcGasBlend(comp: Composition): GasBlend = 
  var
    gasProps: GasBlendProps = calcAllProperties(comp)
    specificGravity: SpecificGravity = calcGasBlendSpecificGravity(gasProps.Mass)
    (
      higherHeatingValue,
      lowerHeatingValue,
      criticalPressure,
      criticalTemperature,
      ratioSpecificHeats
    ) = calcGasBlendData(gasProps.GasBlendComponentProps)
    
  result = (
    gasProps,
    specificGravity,
    higherHeatingValue,
    lowerHeatingValue,
    criticalPressure,
    criticalTemperature,
    ratioSpecificHeats
    )




var
  testComp : Composition = [
    96.13920,
    2.00090,
    0.42310,
    0.06530,
    0.07120,
    0.01920,
    0.01420,
    0.01940,
    0.00000,
    0.00000,
    0.00000,
    0.00000,

    0.00000,
    0.00000,
    0.52220,
    0.00000,
    0.00000,

    0.00000,
    0.00000,
    0.00000,
    0.72540
  ]

var
  test: GasBlend = calcGasBlend(testComp)
  props: GasBlendComponentProps = test.Props.GasBlendComponentProps

for name, i in gasIndex.fieldPairs:
  echo name, " => ", props[i].CalculatedProperties.RatioOfSpecificHeat

for name, i in test.fieldPairs:
  if name != "Props":
    echo name, " => ", i

#[
    CriticalPressurePercentage    : Percentage
    CriticalTemperaturePercentage : Percentage

    ConstantPressureSHCPercentage : Percentage
    ConstantVolumeSHCPercentage   : Percentage

    RatioOfSpecificHeat           : Ratio
    RatioOfSpecificHeatPercentage : Percentage

    GrossHVPercentage             : Percentage
    IdealHVPercentage             : Percentage


p_methane
p_ethane
p_propane
p_isoButane
p_nButane
p_isoPentane
p_nPentane
p_nHexane
p_nHeptane
p_nOctane
p_nNonane
p_nDecane
p_hydrogen
p_oxygen
p_nitrogen
p_helium
p_argon
p_water
p_hydrogenSulfide
p_carbonMonoxide
p_carbonDioxide
]#

