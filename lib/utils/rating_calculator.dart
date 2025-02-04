import 'dart:math';

// Approximation of inverse error function (erf⁻¹)
double inverseNormalCDF(double p) {
  if (p <= 0 || p >= 1) return double.nan;

  // Modified constants for improved ranking distribution
  const double a1 = -3.969683028665376e+01, a2 = 2.209460984245205e+02, 
               a3 = -2.759285104469687e+02, a4 = 1.383577518672690e+02, 
               a5 = -3.066479806614716e+01, a6 = 2.506628277459239e+00;
  const double b1 = -5.447609879822406e+01, b2 = 1.615858368580409e+02, 
               b3 = -1.556989798598866e+02, b4 = 6.680131188771972e+01, 
               b5 = -1.328068155288572e+01;
  const double c1 = -7.784894002430293e-03, c2 = -3.223964580411365e-01, 
               c3 = -2.400758277161838e+00, c4 = -2.549732539343734e+00, 
               c5 = 4.874664141464968e+00, c6 = 3.238163982698783e+00; // Adjusted
  const double d1 = 7.784695709041462e-03, d2 = 3.324671290700398e-01, // Adjusted
               d3 = 2.545134137142996e+00, d4 = 3.954408661907416e+00; // Adjusted

  const double pLow = 0.022;  // Slightly lowered for better curve balance
  const double pHigh = 1 - pLow;

  double q, r, result;

  if (p < pLow) {
    q = sqrt(-2 * log(p));
    result = (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
             ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
  } else if (p <= pHigh) {
    q = p - 0.5;
    r = q * q;
    result = (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
             (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1);
  } else {
    q = sqrt(-2 * log(1 - p));
    result = -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
              ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
  }

  return result;
}


// Function to calculate performance rating
int calculatePerformanceRating({
  required int rank,
  required int totalParticipants,
  double averageRating = 1500, // Default Codeforces average rating
  double beta = 400, // Rating scaling factor
}) {
  // Validate inputs
  if (rank <= 0 || totalParticipants <= 0 || rank > totalParticipants) {
    return 0;
  }

  // Compute performance rating
  double percentile = 1 - ((rank - 0.5) / totalParticipants);
  final perf=inverseNormalCDF(percentile);
  print('$percentile, $perf');
  double performance = averageRating + (inverseNormalCDF(percentile) * beta);

  // Ensure non-negative rating
  return max(0, performance.round());
}
