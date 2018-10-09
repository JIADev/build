# Built-in, default PowerShell prompt
function prompt {
    "[J6] $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}