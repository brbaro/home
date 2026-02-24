if ($args.Count -eq 0) { exit }

$operation = $args[0]
$operands = $args[1..($args.Count - 1)]

$expression = switch -Exact ($operation) {
  "add" { $operands -join "+" }
  "sub" { $operands -join "-" }
  "mul" { $operands -join "*" }
  "div" { $operands -join "/" }
  "avg" { "(($($operands -join '+')) / $($operands.Count))" }
  Default { $args -join "" }
}

try {
  $result = Invoke-Expression ($expression `
    -replace 'pi', '3.14159265358979323846' `
    -replace '\$|,', '' `
    -replace '--', '+' `
    -replace 'x', '*'
    )

  if ($result -is [double] -or $result -is [decimal]) {
    [math]::Round($result, 4)
  } else {
    $result
  }
} catch {
  Write-Host no
  exit 1
}
