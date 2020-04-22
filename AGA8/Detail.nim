import math
import "../Inputs.nim"
include "DetailConstants.nim"

const TermCount = 58

var
  K3 : float
  xFields : array[1..CompCount, float]

proc xTermsDetail(comp : Composition) =
  var
    G, Q, Q2, F, U, xij, xi2 : float
    exit : bool = true

  # * Check to see if a component fraction has changed. If x is the same as the previous call, exit
  for i in 1..CompCount:
    if abs(comp[i] - xFields[i]) > 0.0000001:
      exit = false
    xFields[i] = comp[i]
  
  if exit:
    return

  K3 = 0
  
  for i in 1..18:
    Bs[i] = 0
  
  # ? Calculate pure fluid contributions
  for i, gasA in comp.pairs:
    if gasA == 0:
      continue

    xi2 = pow(gasA, 2)
    # ? K, U, and G are the sums of a pure fluid contribution and a binary pair contribution
    K3 += (gasA * Ki25[i])
    U += (gasA * Ei25[i])
    G += (gasA * Gi[i])
    # ? Q and F depend only on the pure fluid parts
    Q += (gasA * Qi[i])
    F += xi2 * Fi[i]

    for j in 1..18:
      # ? Pure fluid contributions to second virial coefficient
      Bs[j] += xi2 * Bsnij2[i][i][j]
  
  K3 = pow(K3, 2)
  U = pow(U, 2)

  # ? Binary pair contributions
  for i, gasA in comp.pairs:
    if gasA == 0:
      continue

    for j, gasB in comp.pairs:
      if gasB == 0:
        continue

      xij = 2 * gasA * gasB
      K3 += xij * Kij5[i][j]
      U += xij * Uij5[i][j]
      G += xij * Gij5[i][j]

      for k in 1..18:
        # ? Second virial coefficients of blend
        Bs[k] += xij * Bsnij2[i][j][k]
  
  K3 = pow(K3, 0.6)
  U = pow(U, 0.2)

  # ? Third virial and higher coefficients
  Q2 = pow(Q, 2)
  for n in 13..58:
    Csn[n] = an[n] * pow(U, un[n])
    if gn[n] == 1:
      Csn[n] *= G
    if qn[n] == 1:
      Csn[n] *= Q2
    if fn[n] == 1:
      Csn[n] *= F


type
  Alpha0 = tuple
    Helmholtz : float # ? Ideal gas Helmholtz energy (J/mol)
    PartialA : float # ? partial (Helmholtz / partial(T)) [J/(mol-k)]
    PartialB : float # ? T * partial^2 (Helmholtz / partial(T)^2) [J/(mol-k)

  AlphaRDensityDerivatives = tuple
    Helmholtz : float # ? Residual Helmholtz energy (J/mol)
    PartialA : float # ? D*partial  (ar)/partial(D) (J/mol)
    PartialB : float # ? D^2*partial^2(ar)/partial(D)^2 (J/mol)
    PartialC : float # ? D^3*partial^3(ar)/partial(D)^3 (J/mol)
  
  AlphaRTempDerivativesA = tuple
    PartialA : float # ? partial  (ar)/partial(T) [J/(mol-K)]
    PartialB : float # ? D*partial^2(ar)/partial(D)/partial(T) [J/(mol-K)]
  
  AlphaRTempDerivativesB = tuple
    PartialA : float # ? T*partial^2(ar)/partial(T)^2 [J/(mol-K)]

  AlphaR = tuple
    Density : AlphaRDensityDerivatives
    TempA : AlphaRTempDerivativesA
    TempB : AlphaRTempDerivativesB

const
  epsilon : float = 1e-15

proc Alpha0Detail(temp : Temperature, density : Density, comp : Composition) : Alpha0 =
  # ? Calculate the ideal gas Helmholtz energy and its derivatives with respect to temp and density.
  # ? This routine is not needed when only P (or Z) is calculated.
  var
    LogT, LogD, LogHyp, th0T, LogxD : float
    SumHyp0, SumHyp1, SumHyp2 : float
    em, ep, hcn, hsn : float
    th0, n0 : float
  
  if density > epsilon:
    LogD = log10(density)
  else:
    LogD = log10(epsilon)
  
  LogT = log10(temp)

  for i, gasPercentage in comp.pairs:
    if gasPercentage == 0:
      continue

    LogxD = LogD + log10(gasPercentage)
    
    for j in 4..7:
      th0 = th0i[i][j]
      n0 = n0i[i][j]

      if th0 == 0:
        continue

      th0T = th0 / temp
      ep = exp(th0T)
      em = 1 / ep
      hsn = (ep - em) / 2
      hcn = (ep + em) / 2

      if j == 4 or j == 6:
        LogHyp = log10(abs(hsn))
        SumHyp0 += n0 * LogHyp
        SumHyp1 += n0 * (LogHyp - th0T * hcn / hsn)
        SumHyp2 += n0 * pow(th0T / hsn, 2)
      else:
        LogHyp = log10(abs(hcn))
        SumHyp0 += - n0 * LogHyp
        SumHyp1 += - n0 * (LogHyp - th0T * hsn / hcn)
        SumHyp2 += n0 * pow(th0T / hcn, 2)
  
    result[0] += gasPercentage * (LogxD + n0i[i][1] + n0i[i][2] / temp - n0i[i][3] * LogT + SumHyp0)
    result[1] += gasPercentage * (LogxD + n0i[i][1] - n0i[i][3] * (1 + LogT) + SumHyp1)
    result[2] += - gasPercentage * (n0i[i][3] + SumHyp2)
  # ? rDetail is defined in DetailConstants.nim
  result[0] *= rDetail * temp
  result[1] *= rDetail
  result[2] *= rDetail

var
  TempOld : float = 0.0
  Tun : array[1..TermCount, float]

proc AlphaRDetail(itau : int, idel : int, temp : Temperature, density : Density) : AlphaR =
  # ? Calculate the derivatives of the residual Helmholtz energy (ar) with respect to T and D.
  # ? itau and idel are inputs that contain the highest derivatives needed.

  # ? xTerms must be called before this routine if x has changed

  # * Inputs:
  # *  itau - Set this to 1 to calculate "ar" derivatives with respect to T [i.e., ar(1,0), ar(1,1), and ar(2,0)], otherwise set it to 0.
  # *  idel - Currently not used, but kept as an input for future use in specifing the highest density derivative needed.
  # *  temp - Temperature (K)
  # *  density - Density (mol/l)
  var
    ckd, bkd, Dred : float
    Sum, s0, s1, s2, s3, RT : float
    kFloat : float
    Sum0, SumB, CoefD1, CoefD2, CoefD3, CoefT1, CoefT2 : array[1..TermCount, float]
    Dknn : array[10, float]
    Expn : array[5, float]

  if abs(temp - TempOld) > 0.0000001:
    for n in 1..TermCount:
      Tun[n] = pow(temp, un[n])
  TempOld = temp

  # ? Precalculations of common powers and exponents of density
  Dred = K3 * density
  Dknn[0] = 1
  for n in 1..high(Dknn):
    Dknn[n] = Dred * Dknn[n - 1]
  Expn[0] = 1
  for n in 1..high(Expn):
    Expn[n] = exp(-Dknn[n])
  RT = rDetail * temp

  for n in 1..TermCount:
    # ? Contributions to the Helmholtz energy and its derivatives with respect to temperature
    CoefT1[n] = rDetail * (un[n] - 1)
    CoefT2[n] = CoefT1[n] * un[n]

    # ? Contributions to the virial coefficients
    if n <= 18:
      Sum = Bs[n] * density
      if n >= 13:
        Sum += - Csn[n] * Dred
      SumB[n] = Sum * Tun[n]
    if n >= 13:
      kFloat = float(kn[n])
      # ? Contributions to the residual part of the Helmholtz energy
      Sum0[n] = Csn[n] * Dknn[bn[n]] * Tun[n] * Expn[kn[n]]
      # ? Contributions to the derivatives of the Helmholtz energy with respect to density
      bkd = float(bn[n]) - kFloat * Dknn[kn[n]]
      ckd = kFloat * kFloat * Dknn[kn[n]]
      CoefD1[n] = bkd
      CoefD2[n] = bkd * (bkd - 1) - ckd
      CoefD3[n] = (bkd - 2) * CoefD2[n] + ckd * (float(1 - kn[n]) - 2 * bkd)
  
  for n in 1..TermCount:
    # ? Density derivatives
    s0 = Sum0[n] + SumB[n]
    s1 = Sum0[n] * CoefD1[n] + SumB[n]
    s2 = Sum0[n] * CoefD2[n]
    s3 = Sum0[n] * CoefD3[n]

    result[0][0] += RT * s0
    result[0][1] += RT * s1
    result[0][2] += RT * s2
    result[0][3] += RT * s3

    # ? Temp derivatives
    if itau > 0:
      result[1][0] -= CoefT1[n] * s0
      result[1][1] -= CoefT1[n] * s1
      result[2][0] += CoefT2[n] * s0

# ? ##################
# ? Exports          #
# ? ##################
type
  PDetail* = tuple
    Pressure : Pressure
    Compressibility : Compressibility

# ? Calculated in the Pressure subroutine, but not included as an argument since it is only used internally in the density algorithm.
var dPdDsave : float

proc MolarMassDetail*(composition : Composition) : MolarMass =
  # * Calculate the molar mass of the gas blend
  for i, percentComposition in composition.pairs:
    result = result + (percentComposition * molarMasses[i])

proc PressureDetail*(temp: Temperature, density: Density, comp: Composition) : PDetail =
  # ? Calculate pressure as a function of temperature and density.  The derivative d(P)/d(D) is also calculated
  # ? for use in the iterative DensityDetail subroutine (and is only returned as a common variable).
  var alphaR : AlphaR
  
  xTermsDetail(comp)
  alphaR = AlphaRDetail(0, 2, temp, density)

  result.Compressibility = 1 + alphaR.Density.PartialA / rDetail / temp
  result.Pressure = density * rDetail * temp * result.Compressibility

  # ? d(P) / d(D) for use in density iteration
  dPdDsave = rDetail * temp + 2 * alphaR.Density.PartialA + alphaR.Density.PartialB

type
  DDetail* = tuple
    Density : Density
    ErrCode : int
    ErrMsg : string

proc DensityDetail*(temp : Temperature, pressure : Pressure, comp : Composition,
                    density : Density = -1) : DDetail =
  # ? Calculate density as a function of temperature and pressure.  This is an iterative routine that calls PressureDetail
  # ? to find the correct state point.  Generally only 6 iterations at most are required.
  # ? If the iteration fails to converge, the ideal gas density and an error message are returned.
  # ? No checks are made to determine the phase boundary, which would have guaranteed that the output is in the gas phase.
  # ? It is up to the user to locate the phase boundary, and thus identify the phase of the T and P inputs.
  # ? If the state point is 2-phase, the output density will represent a metastable state.

  var
    plog, vlog, dpdlv, vdiff, tolr : float
    pDetail : PDetail

  result.ErrCode = 0
  result.ErrMsg = ""

  if abs(pressure) < epsilon:
    result.Density = 0
    return

  tolr = 0.0000001
  if density > -epsilon:
    result.Density = pressure / rDetail / temp # ? Ideal gas estimate
  else:
    result.Density = abs(density)
  
  plog = log10(pressure)
  vlog = -log10(result.Density)

  for it in 1..20:
    if vlog < -7 or vlog > 100:
      result.ErrCode = 1
      result.ErrMsg = "Calculation failed to converge in DETAIL method, ideal gas density returned."
      result.Density = pressure / rDetail / temp
      return result
    result.Density = exp(-vlog)
    pDetail = PressureDetail(temp, density, comp)

    if dPdDsave < epsilon or pDetail.Pressure < epsilon:
      vlog += 0.1
    else:
      # ? Find the next density with a first order Newton's type iterative scheme, with
      # ? log(P) as the known variable and log(v) as the unknown property.
      # ? See AGA 8 publication for further information.
      dpdlv = -result.Density * dPdDsave # ? d(p)/d[log(v)]
      vdiff = (log10(pDetail.Pressure) - plog) * pDetail.Pressure / dpdlv
      vlog = vlog - vdiff
      if abs(vdiff) < tolr:
        result.Density = exp(-vlog)
        return result
  
  result.ErrCode = 1
  result.ErrMsg = "Calculation failed to converge in DETAIL method, ideal gas density returned."
  result.Density = pressure / rDetail / temp

type
  Energy = float # ? J/mol

  InternalEnergy = Energy # ? J/mol
  Enthalpy = Energy # ? J/mol
  Entropy = float # ? J/(mol-K)
  
  HeatCapacity = float # ? J/(mol-K)
  Speed = float # ? m/s

  GasBlendDerivatives* = tuple
    dPdD : float # ? First derivative of pressure with respect to density at constant temperature [kPa/(mol/l)]
    d2PdD2 : float # ? Second derivative of pressure with respect to density at constant temperature [kPa/(mol/l)^2]
    d2PdTD : float # ? Second derivative of pressure with respect to temperature and density [kPa/(mol/l)/K] (currently not calculated)
    dPdT : float # ? First derivative of pressure with respect to temperature at constant density (kPa/K)

  GasBlendProps* = tuple
    Pressure : Pressure
    Compressibility : Compressibility
    Derivatives : GasBlendDerivatives
    InternalEnergy : InternalEnergy
    Enthalpy : Enthalpy
    Entropy : Entropy
    IsochoricHeatCapacity : HeatCapacity
    IsobaricHeatCapacity : HeatCapacity
    SpeedOfSound : Speed
    GibbsEnergy : Energy
    JouleThomsonCoef : float # ? K/kPa
    Kappa : float # ? Isentropic Exponent

proc PropertiesDetail*(temp: Temperature, density: Density, comp: Composition) : GasBlendProps =
  var
    alpha0 : Alpha0
    alphaR : AlphaR
    molarMass : MolarMass

    A, RT: float
  
  molarMass = MolarMassDetail(comp)
  echo molarMass
  xTermsDetail(comp)

  # ? Calculate the ideal gas Helmholtz energy, and its first and second derivatives with respect to temperature.
  alpha0 = Alpha0Detail(temp, density, comp)
  # ? Calculate the real gas Helmholtz energy, and its derivatives with respect to temperature and/or density.
  alphaR = AlphaRDetail(2, 3, temp, density)

  RT = rDetail * temp

  result.Compressibility = 1 + alphaR.Density.PartialA / RT
  result.Pressure = density * RT * result.Compressibility

  result.Derivatives.dPdD = RT + 2 * alphaR.Density.PartialA + alphaR.Density.PartialB
  result.Derivatives.dPdT = density * rDetail + density * alphaR.TempA.PartialB

  A = alpha0.Helmholtz + alphaR.Density.Helmholtz
  result.Entropy = -alpha0.PartialA - alphaR.TempA.PartialA

  result.InternalEnergy = A + temp * result.Entropy
  result.IsochoricHeatCapacity = -(alpha0.PartialB + alphaR.TempB.PartialA)

  if density > epsilon:
    result.Enthalpy = result.InternalEnergy + result.Pressure / density
    result.GibbsEnergy = A + result.Pressure / density
    result.IsobaricHeatCapacity =
      result.IsochoricHeatCapacity + temp *
      pow(result.Derivatives.dPdT / density, 2) / result.Derivatives.dPdD
    result.Derivatives.d2PdD2 = (
        2 * alphaR.Density.PartialA + 4 * alphaR.Density.PartialB + alphaR.Density.PartialC
      ) / density
    result.JouleThomsonCoef = (
        temp / density * result.Derivatives.dPdT / result.Derivatives.dPdD - 1
      ) / result.IsobaricHeatCapacity / density
  else:
    result.Enthalpy = result.InternalEnergy + RT
    result.GibbsEnergy = A + RT
    result.IsobaricHeatCapacity = result.IsochoricHeatCapacity + rDetail
    result.Derivatives.d2PdD2 = 0
    result.JouleThomsonCoef = 1E+20 # ? =(dB/dT*T-B)/Cp for an ideal gas, but dB/dT is not calculated here
  
  result.SpeedOfSound = 1000 * result.IsobaricHeatCapacity / result.IsochoricHeatCapacity *
    result.Derivatives.dPdD / molarMass

  if result.SpeedOfSound < 0:
    result.SpeedOfSound = 0
  
  result.SpeedOfSound = sqrt(result.SpeedOfSound)
  result.Kappa = result.SpeedOfSound * result.SpeedOfSound * molarMass / (
    RT * 1000 * result.Compressibility
  )

  result.Derivatives.d2PdTD = 0

