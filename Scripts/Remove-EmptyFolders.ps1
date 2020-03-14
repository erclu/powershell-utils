[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (
  [System.IO.DirectoryInfo]
  $Path = "."
)

begin {
}

process {
  Get-ChildItem -Recurse -Directory -LiteralPath $Path |
    Where-Object { -not $_.GetFiles("*", "AllDirectories") } |
    Where-Object { $PSCmdlet.ShouldProcess($_.Name, "Remove folder and subfolders") } |
    Remove-Item -Recurse
}

end {
}
