function Pretty-Format {
    param([Hashtable] $arg, $indent = 5)
    $space=new-object system.string([char]32, $indent)
    # $arg.Keys | sort | % { "$($space)$($_): '$($arg[$_])'"; } | Join-String -Separator "`n"   
    $arg.Keys | sort | % { "$($space)$($_): $(if ($arg[$_].GetType().Name -eq "string") {[string]::Concat("'",$arg[$_].ToString(),"'")} else {$arg[$_]})"; } | Join-String -Separator "`n"
}

function Say
{
    param([string] $message)
    Write-Host "$( Get-Elapsed ) " -NoNewline -ForegroundColor Magenta
    Write-Host "$message" -ForegroundColor Yellow
}

function Get-Elapsed
{
    if ($Global:startAt -eq $null) { $Global:startAt = [System.Diagnostics.Stopwatch]::StartNew(); }
    [System.String]::Concat("[", (new-object System.DateTime(0)).AddMilliseconds($Global:startAt.ElapsedMilliseconds).ToString("mm:ss"), "]");
}; Get-Elapsed | out-null;
