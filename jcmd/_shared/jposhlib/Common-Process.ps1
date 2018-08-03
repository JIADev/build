function ExecuteCommandsWithStatus($commands, [string]$operationName)
{
	$oldtitle = $host.ui.RawUI.WindowTitle

	function UpdateStatus([int] $step, [int] $totalSteps, [string] $stepName)
	{

	  $host.ui.RawUI.WindowTitle = "$oldtitle |> $operationName - $step of $totalSteps : $stepName"
	}

	$JobStartTime = Get-Date -format HH:mm:ss

	$totalSteps = $commands.Count
	$step = 0

	try {
	  for ($i = 0; $i -lt $totalSteps; $i++) {
			$commandKey = $commands[$i].name
			$command = $commands[$i].command
			$args = $commands[$i].args

			UpdateStatus $($i+1) $totalSteps $commandKey

			try {
				Write-Debug "ExecuteCommandsWithStatus: $command $args"
				#using splatting here: @args instead of $args
				$Error.clear()
				$global:LASTEXITCODE = 0
				& $command @args
				$success = $?
				if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}
				if (!$success -or ($exitCode -gt 0))
				{
					Write-Output "The command '$commandKey' exited with error code: $exitCode"
					Exit $exitCode
				}
			}
			catch {
				$success = $?
				if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}
				Write-Output "The command '$commandKey' exited with error code: $exitCode"
				Write-Output $_.Exception|format-list -force
				if ($exitCode -eq 0) {$exitCode = 1} #dont exit with 0 code if there was a problem
				Exit $exitCode
			}
	  }
	}
	finally {
	  $JobEndTime = Get-Date -format HH:mm:ss
	  $TimeDiff = New-TimeSpan $JobStartTime $JobEndTime
	  if ($TimeDiff.Seconds -lt 0) {
		$Hrs = ($TimeDiff.Hours) + 23
		$Mins = ($TimeDiff.Minutes) + 59
		$Secs = ($TimeDiff.Seconds) + 59 }
	  else {
		$Hrs = $TimeDiff.Hours
		$Mins = $TimeDiff.Minutes
		$Secs = $TimeDiff.Seconds }
	  $Difference = '{0:00}:{1:00}:{2:00}' -f $Hrs,$Mins,$Secs

	  $host.ui.RawUI.WindowTitle = $oldtitle

	  "------------------------------------------------------------"
	  "Start Time: $JobStartTime" 
	  "End Time: $JobEndTime"
	  "Elapsed Time: $Difference"
	  "------------------------------------------------------------"
	}
}