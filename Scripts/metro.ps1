#!/usr/bin/env pwsh

if ($args.Count -gt 0) { $Page = $args[0] } else { $Page = "" }
Start-Process "ms-settings:$Page"
