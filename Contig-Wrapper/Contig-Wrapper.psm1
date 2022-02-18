
if (-not (Get-Command -ErrorAction SilentlyContinue Contig.exe) ) {
  throw "CONTIG IS NOT AVAILABLE ON PATH"
}

function Invoke-Contig {
  Write-Output ("+" * 80)
  Contig.exe -nobanner $args
  Write-Output ("-" * 80)
  # Contig.exe -nobanner $args | Write-Output
  # Contig64.exe -nobanner $args | Write-Output
}

Set-Alias contig Invoke-Contig

function Test-FileFragmentation {
  [CmdletBinding()]
  param (
    # File to analyze
    [Parameter(Mandatory)]
    [System.IO.FileInfo]
    $file
  )

  begin {
  }

  process {
    Invoke-Contig -a $file
  }

  end {
  }
}

function Invoke-FileDefragmentation {
  [CmdletBinding()]
  param (
    # File to defragment
    [Parameter(Mandatory)]
    [System.IO.FileInfo]
    $file
  )

  begin {
  }

  process {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
      throw "retry as administrator"
    }

    $start = Get-Date;

    Invoke-Contig $file

    $elapsed = (Get-Date) - $start;

    Write-Output "$file defragmented in $elapsed"
  }

  end {
  }
}

Set-Alias defrag Invoke-FileDefragmentation

# TODO implement
function Read-ContigOutput {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]
    $rawOutput
  )

  begin {
  }

  process {
    Write-Verbose $rawOutput
  }

  end {
  }
}
