param (
    [int]$exitCode,
    [string]$ExceptionMessage
)

if ($ExceptionMessage)
{
    throw $ExceptionMessage
}
else
{
    Exit $exitCode
}