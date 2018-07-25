function ExecuteCommandsWithStatus($commands)
{
	$oldtitle = $host.ui.RawUI.WindowTitle

	function UpdateStatus([int] $step, [int] $totalSteps, [string] $stepName)
	{

	  $host.ui.RawUI.WindowTitle = "$oldtitle |> $statusActivity - $step of $totalSteps : $stepName"
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
		  #using splatting here: @args instead of $args
		  & $command @args

		  $exitCode = $GLOBAL:LASTEXITCODE
		  if ($exitCode -gt 0)
		  {
			Write-Output "The command '$commandKey' exited with error code: $exitCode"
			Exit $exitCode
		  }
		}
		catch {
		  $ec = $GLOBAL:LASTEXITCODE
		  Write-Output "The command '$commandKey' exited with error code: $ec"
		  Write-Output $_.Exception|format-list -force
		  if ($ec -eq 0) {$ec = 1} #dont exit with 0 code if there was a problem
		  Exit $ec
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