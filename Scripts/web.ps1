#!/usr/bin/env pwsh

$target = $args[0]
$links = @{
  "via"  = "https://usevia.app"
  "woo"  = "https://wootility.io"
}
if (-not $target) {
  Start-Process "https://google.com"
}
elseif ($links.ContainsKey($target)) {
  Start-Process $links[$target]
}
elseif ($target -match '^[a-z]+://') {
  Start-Process $target
}
elseif ($target -notcontains ".") {
  Start-Process "https://$target.com"
}
else {
  Start-Process "https://$target"
}
