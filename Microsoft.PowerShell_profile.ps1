

if ($env:PSModulePath -notcontains [System.IO.Path]::Combine($env:USERPROFILE,
 'Documents', 'WindowsPowerShell', 'Modules')
 ) { 
    $env:PSModulePath += ';{0}' -f [System.IO.Path]::Combine($env:USERPROFILE, 
    'Documents', 'WindowsPowerShell', 'Modules') 
}

Write-Host "Greetings, Master" -ForegroundColor Yellow

# Configure PSReadLine options
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar

# Set up a rule to allow the use of the 'echo' alias
@{
    'Rules' = @{
        'PSAvoidUsingCmdletAliases' = @{
            'allowlist' = @('echo')
        }
    }
} | Out-Null

# Get theme from profile.ps1 or use a default theme
function Get-Theme {
    if (Test-Path -Path $PROFILE.CurrentUserAllHosts -PathType leaf) {
        $existingTheme = Select-String -Raw -Path $PROFILE.CurrentUserAllHosts -Pattern "oh-my-posh init pwsh --config"
        if ($null -ne $existingTheme) {
            Invoke-Expression $existingTheme
            return
        }
    } else {
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
    }
}

# Editor Configuration
$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR

# Define function to edit the user's profile
function Edit-Profile {
    nvim $PROFILE.CurrentUserAllHosts
}

# Define function to create a new file with ASCII encoding
function touch($file) { "" | Out-File $file -Encoding ASCII }

#Recursive Searching
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

#Public ip address Of Machine
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

#Shows the Time the System is run for
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function Redo-Profile {
    & $profile
}

#Unload the files
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

#Uploads the specified file's content to a hastebin-like service and returns the URL.
function hb {
    if ($args.Length -eq 0) {
        Write-Error "No file path specified."
        return
    }
    
    $FilePath = $args[0]
    
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }
    
    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Write-Output $url
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}

#Searches for a regex pattern in files within the specified directory or from the pipeline input.
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

#Shows the path of the command.
function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

#Kills processes by name.
function pkill($name) {
    Get-Process $name | Stop-Process -Force
}

#Lists processes by name.
function pgrep($name) {
    Get-Process $name
}

#Creates a new file with the specified name.
function nf($name) {
    New-Item -ItemType File -Name $name
}

#Creates and changes to a new directory.
function mkcd($dir) {
    New-Item -ItemType Directory -Name $dir | Set-Location
}

#Changes the current directory to the user's Documents folder.
function docs {
    Set-Location $env:USERPROFILE\Documents
}

#Changes the current directory to the user's Desktop folder.
function dtop {
    Set-Location $env:USERPROFILE\Desktop
}

#Kills a process by name.
function k9($name) {
    Get-Process $name | Stop-Process -Force
}

#Lists all files in the current directory with detailed formatting.
function la { 
Get-ChildItem -Path . -Force | Format-Table -AutoSize 
}
function ll { 
Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize 
}


# Function to check if the script is running as administrator
function Test-Admin {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}


function Show-Help {
    @"
PowerShell Profile Help
=======================

Edit-Profile - Opens the current user's profile for editing using the configured editor.

touch <file> - Creates a new empty file.

ff <name> - Finds files recursively with the specified name.

Get-PubIP - Retrieves the public IP address of the machine.

uptime - Displays the system uptime.

reload-profile - Reloads the current user's PowerShell profile.

unzip <file> - Extracts a zip file to the current directory.

hb <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.

grep <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.

which <name> - Shows the path of the command.

export <name> <value> - Sets an environment variable.# will Add soon

pkill <name> - Kills processes by name.

pgrep <name> - Lists processes by name.

nf <name> - Creates a new file with the specified name.

mkcd <dir> - Creates and changes to a new directory.

docs - Changes the current directory to the user's Documents folder.

dtop - Changes the current directory to the user's Desktop folder.

k9 <name> - Kills a process by name.

la - Lists all files in the current directory with detailed formatting.

ll - Lists all files, including hidden, in the current directory with detailed formatting.

Use 'Show-Help' to display this help message.


"@

}

Write-Host "Use 'Show-Help' to display help" -ForegroundColor Yellow


