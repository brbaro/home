param(
  [string]$Val1,
  [string]$Val2,
  [string]$Val3
)

$regex = '^([0-9\.]+)\s*(.*)$'

if ($Val1 -match $regex) { $v1 = [double]$matches[1]; $u1 = $matches[2] }
if ($Val2 -match $regex) { $v2 = [double]$matches[1]; $u2 = $matches[2] }
if ($Val3 -match $regex) { $v3 = [double]$matches[1]; $u3 = $matches[2] }

if ($v1 -eq 0) {
  Write-Host "Error: Division by zero (val1)." -ForegroundColor Red
  exit 1
}

$v4 = ($v3 * $v2) / $v1
$u4 = if ($u1 -eq $u3) { $u2 } else { "" }

Write-Host ('{0}{1}' -f $v4, $u4)
