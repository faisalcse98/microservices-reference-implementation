[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
	[string]$InputPath,
    [Parameter(Mandatory=$true)]
	[string]$Method,
    [DateTime]$StartDateTime = [DateTime]::MinValue,
	[DateTime]$EndDateTime = [DateTime]::MaxValue
)

echo ""
echo "Input path: $($InputPath)"
echo "Start date: $($StartDateTime)"
echo "End date: $($EndDateTime)"

$count = 0
$proxyOverhead = 0
$actualOverhead = 0
$preTorchOverhead = 0
$postTorchOverhead = 0
$outsideOverhead = 0
$first = 1
$lastTick = 0

foreach($line in Get-Content $InputPath)
{
	$words = $line -split " "
	$CurrentDateTimeStr = $words[0]+"T"+$words[1]+$words[2]
	$CurrentDateTime = [datetime]::ParseExact($CurrentDateTimeStr, "yyyy-MM-ddTHH:mm:ss.fffzzz", $null)
	if($CurrentDateTime -ge $StartDateTime -and $CurrentDateTime -le $EndDateTime)
	{
		if($words.Count -ge 5 -and $words[4] -match "<Proxy\d+>_$($Method)")
		{
			$count++
			$proxyDiff = $words[8] - $words[5]
			$actualDiff = $words[7] - $words[6]
			$preTorchDiff = $words[6] - $words[5]
			$postTorchDiff = $words[8] - $words[7]
			$proxyOverhead = $proxyOverhead + $proxyDiff
			$actualOverhead = $actualOverhead + $actualDiff
			$preTorchOverhead = $preTorchOverhead + $preTorchDiff
			$postTorchOverhead = $postTorchOverhead + $postTorchDiff
			if($first -eq 1)
			{
				$first = 0
			}
			else
			{
				$outsideDiff = $words[5] - $lastTick
				$outsideOverhead = $outsideOverhead + $outsideDiff
			}
			$lastTick = $words[8]
		}
	}
}

echo ""
if($count -eq 0)
{
	echo "There is no data point for computation"
}
else
{
	$torchOverhead = $proxyOverhead - $actualOverhead
	$totalOverhead = $proxyOverhead + $outsideOverhead
	$proxyOverhead = $proxyOverhead/10000
	$actualOverhead = $actualOverhead/10000
	$torchOverhead = $torchOverhead/10000
	$preTorchOverhead = $preTorchOverhead/10000
	$postTorchOverhead = $postTorchOverhead/10000
	$outsideOverhead = $outsideOverhead/10000
	$totalOverhead = $totalOverhead/10000
	$proxyOverheadPerc = $proxyOverhead*100/$totalOverhead
	$actualOverheadPerc = $actualOverhead*100/$totalOverhead
	$torchOverheadPerc = $torchOverhead*100/$totalOverhead
	$preTorchOverheadPerc = $preTorchOverhead*100/$totalOverhead
	$postTorchOverheadPerc = $postTorchOverhead*100/$totalOverhead
	$outsideOverheadPerc = $outsideOverhead*100/$totalOverhead
	echo "Count: $($count)"
	echo "Total proxy overhead: $($proxyOverhead) ms [ $($proxyOverheadPerc) %]"
	echo "Total actual overhead: $($actualOverhead) ms [ $($actualOverheadPerc) %]"
	echo "Total Torch overhead: $($torchOverhead) ms [ $($torchOverheadPerc) %]"
	echo "Total pre-Torch overhead: $($preTorchOverhead) ms [ $($preTorchOverheadPerc) %]"
	echo "Total post-Torch overhead: $($postTorchOverhead) ms [ $($postTorchOverheadPerc) %]"
	echo "Total outside overhead: $($outsideOverhead) ms [ $($outsideOverheadPerc) %]"
	echo "Total overhead: $($totalOverhead) ms"
	
	$avgProxyOverhead = $proxyOverhead/$count
	$avgActualOverhead = $actualOverhead/$count
	$avgTorchOverhead = $torchOverhead/$count
	$avgPreTorchOverhead = $preTorchOverhead/$count
	$avgPostTorchOverhead = $postTorchOverhead/$count
	$avgOutsideOverhead = $outsideOverhead/$count
	$avgTotalOverhead = $totalOverhead/$count
	echo ""
	echo "Average proxy overhead: $($avgProxyOverhead) ms"
	echo "Average actual overhead: $($avgActualOverhead) ms"
	echo "Average Torch overhead: $($avgTorchOverhead) ms"
	echo "Average pre-Torch overhead: $($avgPreTorchOverhead) ms"
	echo "Average post-Torch overhead: $($avgPostTorchOverhead) ms"
	echo "Average outside overhead: $($avgOutsideOverhead) ms"
	echo "Average total overhead: $($avgTotalOverhead) ms"
}

echo ""
echo "Program finished successfully"
