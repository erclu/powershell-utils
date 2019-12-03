[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost")]
param()

$job = Start-Job -Name "ExampleJob" -ScriptBlock {
  Start-Sleep -Seconds 5
  Write-Output "Hello from a job"
}

$cmdArgs = @{
  # XXX "EventHandlerExample" needs (??) to be hardcoded inside the scriptblock
  SourceIdentifier = "EventHandlerExample"
  InputObject      = $job
  EventName        = "StateChanged"
  Action           = {
    # Do things here

    # XXX Write-Output does not work here; the action runs as a job
    Write-Host "Hello from the handler"

    # Cleanup resources
    if ($Sender.HasMoreData) {
      Write-Host "`njob $($Sender.Name) says:`n$(Receive-Job $Sender)"
      Write-Host -NoNewline (& prompt)
    }
    Remove-Job $Sender.Id

    Unregister-Event -SourceIdentifier "EventHandlerExample"
    Remove-Job "EventHandlerExample"
  }
}
Register-ObjectEvent @cmdArgs
