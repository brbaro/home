param([string]$Number)

if ($Number -match '^\d+$') {
  [bigint]$step = [bigint]$Number
  [bigint]$reversed = 0
  while ($step -gt 0) {
    $ones = $step % 10
    $reversed = ($reversed * 10) + $ones
    $step = [bigint]($step / 10)
  }
  $reversed
}
