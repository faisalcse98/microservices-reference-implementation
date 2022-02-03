while getopts i:m:s:e: flag; do
    case "${flag}" in
        i) inputPath=${OPTARG};;
        m) method=${OPTARG};;
        s) startDateTime=${OPTARG};;
        e) endDateTime=${OPTARG};;
    esac
done

invalidInput=false
if [ -z "$inputPath" ]; then
	echo "-i [input-path] is required"
	invalidInput=true
fi
if [ -z "$method" ]; then
	echo "-m [method-name] is required"
	invalidInput=true
fi
if [ "$invalidInput" = true ]; then
	exit
fi

if [ -z "$startDateTime" ]; then
	startDateTime='0000-01-01 00:00:00'
fi
if [ -z "$endDateTime" ]; then
	endDateTime='9999-12-31 23:59:59'
fi

echo
echo "InputPath: $inputPath";
echo "Method: $method";
echo "StartDateTime: $startDateTime";
echo "EndDateTime: $endDateTime";

#while read -r line ; do
cat $inputPath | tr -d '\r' | 
{
	count=0
	proxyOverhead=0
	actualOverhead=0
	preTorchOverhead=0
	postTorchOverhead=0
	outsideOverhead=0
	first=1
	lastTick=0

	while read line ; do
		IFS=' '
		read -a words <<< "$line"
		IFS='.'
		read -a timeparts <<< "${words[1]}"
		currentDateTime="${words[0]} ${timeparts[0]}"
		if [[ "$currentDateTime" > "$startDateTime" || "$currentDateTime" == "$startDateTime" ]]; then
			if [[ "$currentDateTime" < "$endDateTime" || "$currentDateTime" == "$endDateTime" ]]; then
				if [[ "${#words[@]}" -ge 5 ]]; then
					if [[ "${words[4]}" == *">_$method" ]]; then
						t1=${words[5]}
						t2=${words[6]}
						t3=${words[7]}
						#t4=$(echo ${words[8]} | tr -d '\r')
						t4=${words[8]}
						#echo "$t1 $t2 $t3 $t4"
						count=$((count+1))
						proxyDiff=$((t4-t1))
						actualDiff=$((t3-t2))
						preTorchDiff=$((t2-t1))
						postTorchDiff=$((t4-t3))
						proxyOverhead=$((proxyOverhead+proxyDiff))
						actualOverhead=$((actualOverhead+actualDiff))
						preTorchOverhead=$((preTorchOverhead+preTorchDiff))
						postTorchOverhead=$((postTorchOverhead+postTorchDiff))
						if [[ $first == 1 ]]; then
							first=0
						else
							outsideDiff=$((t1-lastTick))
							outsideOverhead=$((outsideOverhead+outsideDiff))
						fi
						lastTick=$t4
						#if [[ $count == 10 ]]; then
						#	break
						#fi
						res=$((count%1000))
						if [[ $res == 0 ]]; then
							echo "$count is done"
						fi
						#echo $count
					fi
				fi
			fi
		fi
	done

	if [[ $count == 0 ]]; then
		echo "There is no data point for computation"
	else
		torchOverhead=$((proxyOverhead - actualOverhead))
		totalOverhead=$((proxyOverhead + outsideOverhead))
		proxyOverhead=$(awk -v a=$proxyOverhead 'BEGIN { print a/10000 }')
		actualOverhead=$(awk -v a=$actualOverhead 'BEGIN { print a/10000 }')
		torchOverhead=$(awk -v a=$torchOverhead 'BEGIN { print a/10000 }')
		preTorchOverhead=$(awk -v a=$preTorchOverhead 'BEGIN { print a/10000 }')
		postTorchOverhead=$(awk -v a=$postTorchOverhead 'BEGIN { print a/10000 }')
		outsideOverhead=$(awk -v a=$outsideOverhead 'BEGIN { print a/10000 }')
		totalOverhead=$(awk -v a=$totalOverhead 'BEGIN { print a/10000 }')
		proxyOverheadPerc=$(awk -v a="$proxyOverhead" -v b="$totalOverhead" 'BEGIN { print a*100/b }')
		actualOverheadPerc=$(awk -v a="$actualOverhead" -v b="$totalOverhead" 'BEGIN { print a*100/b }')
		torchOverheadPerc=$(awk -v a="$torchOverhead" -v b="$totalOverhead" 'BEGIN { print a*100/b }')
		preTorchOverheadPerc=$(awk -v a="$preTorchOverhead" -v b="$totalOverhead" 'BEGIN { print a*100/b }')
		postTorchOverheadPerc=$(awk -v a=$"postTorchOverhead" -v b="$totalOverhead" 'BEGIN { print a*100/b }')
		outsideOverheadPerc=$(awk -v a="$outsideOverhead" -v b="$totalOverhead" 'BEGIN { print a*100/b }')
		echo "Count: $count"
		echo "Total proxy overhead: $proxyOverhead ms [ $proxyOverheadPerc %]"
		echo "Total actual overhead: $actualOverhead ms [ $actualOverheadPerc %]"
		echo "Total Torch overhead: $torchOverhead ms [ $torchOverheadPerc %]"
		echo "Total pre-Torch overhead: $preTorchOverhead ms [ $preTorchOverheadPerc %]"
		echo "Total post-Torch overhead: $postTorchOverhead ms [ $postTorchOverheadPerc %]"
		echo "Total outside overhead: $outsideOverhead ms [ $outsideOverheadPerc %]"
		echo "Total overhead: $totalOverhead ms"
		
		avgProxyOverhead=$(awk -v a="$proxyOverhead" -v b="$count" 'BEGIN { print a/b }')
		avgActualOverhead=$(awk -v a="$actualOverhead" -v b="$count" 'BEGIN { print a/b }')
		avgTorchOverhead=$(awk -v a="$torchOverhead" -v b="$count" 'BEGIN { print a/b }')
		avgPreTorchOverhead=$(awk -v a="$preTorchOverhead" -v b="$count" 'BEGIN { print a/b }')
		avgPostTorchOverhead=$(awk -v a="$postTorchOverhead" -v b="$count" 'BEGIN { print a/b }')
		avgOutsideOverhead=$(awk -v a="$outsideOverhead" -v b="$count" 'BEGIN { print a/b }')
		avgTotalOverhead=$(awk -v a="$totalOverhead" -v b="$count" 'BEGIN { print a/b }')
		echo ""
		echo "Average proxy overhead: $avgProxyOverhead ms"
		echo "Average actual overhead: $avgActualOverhead ms"
		echo "Average Torch overhead: $avgTorchOverhead ms"
		echo "Average pre-Torch overhead: $avgPreTorchOverhead ms"
		echo "Average post-Torch overhead: $avgPostTorchOverhead ms"
		echo "Average outside overhead: $avgOutsideOverhead ms"
		echo "Average total overhead: $avgTotalOverhead ms"
	fi
}

echo 
echo "Program finished successfully"
