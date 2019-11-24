function Pretty-Format {
    param([Hashtable] $arg, $indent = 5)
    $space=new-object system.string([char]32, $indent)
    # $arg.Keys | sort | % { "$($space)$($_): '$($arg[$_])'"; } | Join-String -Separator "`n"   
    $arg.Keys | sort | % { "$($space)$($_): $(if ($arg[$_].GetType().Name -eq "string") {[string]::Concat("'",$arg[$_].ToString(),"'")} else {$arg[$_]})"; } | Join-String -Separator "`n"
}

function Set-Console-Title {
    param($title)
    $Global:SayCounter++;
    $title="#$($SayCounter) $title";
    if ($Global:BuildConsoleTitle) { $title = "$($Global:BuildConsoleTitle) $title" }
    try
    {
        [Console]::Title = $title;
    }
    catch {}
}

function Say
{
    param([string] $message)
    $_black_circle="$([char] 9679)"
    $_white_circle="$([char] 9675)"
    $_black_square="$([char] 9632)"
    $Local:elapsed="$( Get-Elapsed ) "
    # Write-Host "$($_black_square) $([Environment]::MachineName): " -NoNewline
    Write-Host "$($_black_square) $($Local:elapsed)" -NoNewline -ForegroundColor Magenta
    Write-Host "$message" -ForegroundColor Yellow
    Set-Console-Title "$($Local:elapsed) $message"; 
}

function Get-Elapsed
{
    if ($Global:startAt -eq $null) { $Global:startAt = [System.Diagnostics.Stopwatch]::StartNew(); }
    [System.String]::Concat("[", (new-object System.DateTime(0)).AddMilliseconds($Global:startAt.ElapsedMilliseconds).ToString("HH:mm:ss"), "]");
}; Get-Elapsed | out-null;

function Output-To-Markdown{
    param([string] $output, $probe)
    
    $trimmedOutput=$output.Trim([char]13, [char]10)
    if ($trimmedOutput -like "/tmp/cmd-*") 
    {
        return "|ERR: _" + $trimmedOutput.Substring(51) + "_|"; 
    }
    elseif (($trimmedOutput -like "sudo: unknown user*") -or ($trimmedOutput -like "* not found")) {
        return "|ERR: _" + $trimmedOutput.Replace("`n", ". ") + "_|";
    }
    # Write-Host "trimmedOutput: $trimmedOutput"
    $outputAsArray=$trimmedOutput.Split([char]10)
    $outputAsMarkdown="";
    $outputLine=0;
    @($outputAsArray) | % {
        if ((-not $probe.Head) -or ($outputLine -lt $probe.Head)) {
            if ($outputAsMarkdown) { $outputAsMarkdown += "<br>" }
            $outputAsMarkdown += "**``" + $_ + "``**"
        }
        $outputLine++;
    }
    "|$($outputAsMarkdown)|"
}

function Get-File-Size-Info {
    param($fileName)
    try
    {
        "$(((New-Object System.IO.FileInfo($fileName)).Length / 1024 / 1024)) Mb"
    }
    catch{
        "[$($_.Exception.GetType().Name)]"
    }
}