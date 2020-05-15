$ErrorActionPreference = "Stop"
function EscapeFile2Echo
{
    param([System.String] $fileName)

    $ret = ""
    $lines = [System.IO.File]::ReadAllLines($fileName)
   	$nameOnly=[System.IO.Path]::GetFileNameWithoutExtension($fileName)

    foreach ($line in $lines)
    {
        foreach ($c in $line.ToCharArray())
        {
            $ic=[int]$c;
            if ( $ic -eq 96 -or $ic -eq 34 -or $ic -eq 92 -or $ic -eq 36)
            {
                $ret = [System.String]::Concat(@($ret, "\", $c.ToString()))
            }
            elseif ($ic -ge 32)
            {
                $ret = [System.String]::Concat(@($ret, $c.ToString()))
            }
            else
            {
                $ret = [System.String]::Concat(@($ret, "\x", [string]::Format("{0:X2}", [int]$c)))
            }
        }
        $ret = [System.String]::Concat(@($ret, [Environment]::NewLine))
    }
    return $ret
}

function WriteFile
{
    param([System.String] $fileName)

   	$nameOnly=[System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $escaped = EscapeFile2Echo $fileName
    $nl=[Environment]::NewLine
    $escaped_and_Queted="`"$($escaped)$($nl)`""
    $ret = "# $($nameOnly)
echo -e $($escaped_and_Queted) > /usr/local/bin/$($nameOnly) || 
echo -e $($escaped_and_Queted) | sudo tee /usr/local/bin/$($nameOnly) >/dev/null 2>&1;
chmod +x /usr/local/bin/$($nameOnly) >/dev/null || sudo chmod +x /usr/local/bin/$($nameOnly)
if [[ -f /usr/local/bin/$($nameOnly) ]]; then echo `"OK: $($nameOnly)`"; else `"Unable to extract $($nameOnly)`"; fi
"

	return $ret
}
 

Get-ChildItem -Path ../ -Filter *.sh -File | ForEach-Object {
    $_.FullName
} | ForEach-Object {
	$nameOnly=[System.IO.Path]::GetFileNameWithoutExtension($_)
	$content=Get-Content "$_"
	"$(WriteFile $_)"
}
