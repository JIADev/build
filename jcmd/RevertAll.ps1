. "$PSScriptRoot\_shared\SourceControlTasks.ps1"

#defaults
$RevertPath = "."
$LongPathCheck = $false
$ignoreFolders = @(".hg", ".git", ".nuget")

#work lists
$junctionFolders = New-Object System.Collections.ArrayList
$emptyFolders = New-Object System.Collections.ArrayList
$longPathFolders = New-Object System.Collections.ArrayList

function EnsureCurrentFolderIsJ6($path) {
    
    $j6Exists = Test-Path "$path\j6"
    $repoExists = (Test-Path "$path\.git") -or (Test-Path "$path\.hg")

    if (!($j6Exists -and $repoExists)) {
        Write-Host "Path: $path"
        Write-Host "Must be in a folder with a /j6 sub-folder and a .git or .hg repository folder." -ForegroundColor Red
        Exit 1;
    }
}

function Remove-LongPathDirectory([string]$directory) {
    # create a temporary (empty) directory
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $tempDirectory = New-Item -ItemType Directory -Path (Join-Path $parent $name)

    robocopy /MIR $tempDirectory.FullName $directory | out-null
    Remove-Item $directory -Force | out-null

    Remove-Item $tempDirectory -Force | out-null
}

function RemoveJunctions([string[]]$folders) {
    $count = $folders.Length;
    foreach ($folder in $folders)
    {
        Write-Verbose "Removing junction: $folder"
        #[io.directory]::Delete($folder);
    }
    Write-Host "Removed $count junctions."
}

function RemoveEmptyFolders([string[]]$folders) {
    $count = $folders.Length
    foreach ($folder in $folders)
    {
        Write-Verbose "Removing Empty Folder: $folder"
        #[io.directory]::Delete($folder);
    }
    Write-Host "Removed $count empty folders."
}

function RemoveLongPathFolders($folders) {
    $count = $folders.Length
    foreach ($folder in $folders)
    {
        Write-Verbose "Removing Long Path: $folder"
        #Remove-LongPathDirectory $folder
    }
    Write-Host "Removed $count long path folders."
}

function CheckFolderContents(
    [String] $path, 
    [String[]] $files, 
    [String[]] $subfolders)
{
    if ($files.Length -eq 0 -and $subfolders.Length -eq 0)    
    {
        $emptyFolders.Add($path) | Out-Null;
    }

    #are we checking for long paths?
    if ($LongPathCheck)
    {
        $longFileNameMaxLen = 261
        $folderLen = $path.Length + 1; #+1 for seperator
        #get the character length of the longest file name in this folders
        $longestFileNameLen = 0;
        if ($files.Length -ne 0)
        {
            $longestFileNameLen = ($files | Measure-Object -Maximum).Maximum.ToString().Length
        }
        
        #if the folder length + the long file length is too long then add this
        #to the list of folders to cleanup
        if (($folderLen + $longestFileNameLen) -gt $longFileNameMaxLen)
        {
            $longPathFolders.Add($path) | Out-Null;
        }
    }
}

function ValidateFolder($folder) {
    #will fail for hidden or system files
    $folderObj = Get-Item $folder -ErrorAction SilentlyContinue
    
    if (!($folderObj)) { return $false; }

    if ( $folderObj.Attributes.ToString().Contains("ReparsePoint") -eq $true) {        
        #save this for reporting totals
        $junctionFolders.Add($folder) | Out-Null;
        return $false; #not valid
    }
    $folderLeafName = (Split-Path $folder -Leaf);
    if ($ignoreFolders -contains $folderLeafName)
    {
        return $false;
    }
    return $true;
}

function Recurse($path) {
    #$files = Get-ChildItem $path -File
    $files = [io.directory]::GetFiles($path)
    #$folders = Get-ChildItem $path -Directory
    $folders = [io.directory]::GetDirectories($path)
  
    CheckFolderContents $path $files $folders

    $validFolders = New-Object System.Collections.ArrayList
    foreach ($i in $folders) {
        if (ValidateFolder $i) { $validFolders.Add($i) | Out-Null }
    }

    foreach ($i in $validFolders) {
        Recurse $i
    }
}


# function Find-LongPaths($searchFolder)
# {
#     # Open a new file stream (nice and fast) and write all the paths and their lengths to it.
#     $j6LongFiles = 
#         Get-ChildItem -Path .\j6 -Recurse -Force | Select-Object -Property FullName | Sort-Object -Property FullNameLength -Descending | Where-Object {$_.FullName.Length -gt 261}

#         $customerLongFiles = 
#             Get-ChildItem -Path .\customer -Recurse -Force | Select-Object -Property FullName | Sort-Object -Property FullNameLength -Descending | Where-Object {$_.FullName.Length -gt 261}

#         # Write to the Console.
#         if ($writeToConsoleAsWell) { Write-Host $string }

#         #Write to the file.
#         $stream.WriteLine($string)
#     }
#     $stream.Close()
# }



function CheckPendingChanges($path) {
    if (SourceControl_HasPendingChanges)
    {
        Write-Host "Path: $path"
        Write-Host "ERROR: Folder has pending changes." -ForegroundColor Red
        Exit 1;
    }
}

function RevertRepoFolder($path) {
    SourceControl_RevertAll
}

function ParseArgs()
{
    $revertPathArg = $args | Where-Object{ $_ -notlike "-*" } | Select-Object -First 1;
    $longPathCheckArg = $args | Where-Object{ $_ -like "-LongPathCheck" } | Select-Object -First 1;

    #default
    if ($revertPathArg) {$script:RevertPath = $revertPathArg }
    if ($longPathCheckArg) {$script:LongPathCheck = $longPathCheckArg }

    #also make sure path is expanded
    $script:RevertPath = Resolve-Path -Path $script:RevertPath
}


#set variables from $args
ParseArgs

$RevertPath = "C:\dev\work2"
$LongPathCheck = $false

Push-Location $RevertPath
try {
    #are we in a j6 project folder?
    EnsureCurrentFolderIsJ6 $RevertPath

    #lets make sure we arent about to lose important code
    CheckPendingChanges $RevertPath

    Write-Host "Reverting $RevertPath" -ForegroundColor Yellow
    #walk the folders and 
    Recurse $revertPath

    RemoveJunctions $junctionFolders
    RemoveEmptyFolders $emptyFolders
    if ($LongPathCheck) { RemoveLongPathFolders $longPathFolders }

    RevertRepoFolder $RevertPath
}
finally {
    Pop-Location
}
