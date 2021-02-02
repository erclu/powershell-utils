
if (-not (Get-Command -ErrorAction SilentlyContinue Contig.exe) ) {
  throw "CONTIG IS NOT AVAILABLE ON PATH"
}

###### TODO is it needed?
# Requires -RunAsAdministrator

function Invoke-Contig {
  # Contig64.exe -nobanner $args
  Contig.exe -nobanner $args
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
    $start = Get-Date;

    Invoke-Contig $file

    $elapsed = (Get-Date) - $start;

    Write-Verbose "defrag of $file completed in $elapsed"
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
