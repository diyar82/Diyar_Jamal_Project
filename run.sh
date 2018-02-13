############################################################################
## Diyar Jamal diyar82@gmail.com 
############################################################################
## Clean the data
######################
way=$(pwd)
echo "This will take a while please be patient :) " ## Make sure program runs
Percent=`awk ' NR==1 {print $1 }' $way/input/percentile.txt`
tr "!" "_" <$way/input/itcont.txt >$way/text1.txt ## seperate raw data into line seperated data
awk 'BEGIN { FS = "|" ; ORS="!" }  {print $1 "|" $8 "|" substr($11,1,5) "|" substr($14,5,8) "|" $15 "|" $16 }' $way/text1.txt >> $way/text2.txt ## get only essential fields
tr "!" '\n' <$way/text2.txt >$way/text3.txt ## seperate raw data into line seperated data
sed -e '/|$/!d' < $way/text3.txt > $way/text4.txt ## Remove entries with Other ID
sed -e '/||/d' < $way/text4.txt > $way/text5.txt ## Remove entries with no zipcode
tr " " "_" <$way/text5.txt >$way/Clean.txt ## seperate raw data into line seperated data
rm $way/text1.txt $way/text2.txt $way/text3.txt $way/text4.txt $way/text5.txt 

echo "Output clean.txt created" ## Check point 1

######################
## Sort the data for easy comparision
######################

nl -n'rz' -s"|" $way/Clean.txt > $way/numbered.txt
sort -t"|" -n -k 4,4 -k 1,1  $way/numbered.txt > $way/sorted_zip.txt
awk 'BEGIN { FS = "|" }  {print $4 }' $way/sorted_zip.txt >> $way/Zips.txt
uniq -c $way/Zips.txt > $way/repeated_zip.txt
Line_Number=`wc -l <$way/repeated_zip.txt`
echo "Data Sorted" ## Check point 2 

######################
## Reading given data
######################

Counter=0
Line_Number=1
Line_Number=`wc -l <$way/repeated_zip.txt`
declare -a Pos  # Position in file
declare -a Rcp  # Recipient
declare -a Nam  # Doners name
declare -a Yrs  # Donation year
declare -a Amt  # Donation amount
declare -a Donation_Set #for statistics

Contrib_Count=0
Total_Contrib=0
for ((i=1; i<=$Line_Number;i++)); do 
Zip_code=`awk 'NR=='$i' {print $2 }' $way/repeated_zip.txt`
unset Donation_Set
echo "THe Zip code " $Zip_code " Is sorted out"
length=`awk 'NR=='$i' {print $1 }' $way/repeated_zip.txt`
Counter=$(($Counter+1))
if (( $length < 2 )); then continue;fi
end=$(($Counter+$length-1))

Pos=(`awk 'BEGIN { FS = "|" } 'NR==$Counter,NR==$end' {print $1 }' $way/sorted_zip.txt`)
Rcp=(`awk 'BEGIN { FS = "|" } 'NR==$Counter,NR==$end' {print $2 }' $way/sorted_zip.txt`)
Nam=(`awk 'BEGIN { FS = "|" } 'NR==$Counter,NR==$end' {print $3 }' $way/sorted_zip.txt`)
Yrs=(`awk 'BEGIN { FS = "|" } 'NR==$Counter,NR==$end' {print $5 }' $way/sorted_zip.txt`)
Amt=(`awk 'BEGIN { FS = "|" } 'NR==$Counter,NR==$end' {print $6 }' $way/sorted_zip.txt`)


Contrib_Count=0
Total_Contrib=0

######################
## start of loop 1 that looks at each individual doner
######################



A_End1=$(($length-1))  ##array start from 0 


for ((D=1; D<=$A_End1;D++)); do

Name1=${Nam[$D]}
Year1=${Yrs[$D]}
A_Begin=$(($D-1))


######################
## start of loop 2 that looks back to find repeating doner
######################

	for ((j=$A_Begin;j>=0;j--)); do
	Name2=${Nam[$j]}

	if [ "$Name2" == "$Name1" ] 
	then
######################
## Making sure the most recent donation is within same year or earlier
######################

	
		Year2=${Yrs[$j]}
		if [ $Year2 -le $Year1 ]
		then

		Position=${Pos[$D]}
		Recipient=${Rcp[$D]}
		Contribution=${Amt[$D]}
		Total_Contrib=$(($Total_Contrib+$Contribution))
		
######################
## Making donation set to compute percentile 
######################		
		Donation_Set[$Contrib_Count]=$Contribution ##Array start from 0
		Contrib_Count=$(($Contrib_Count + 1))

		int=`bc <<< ''$Percent'*'$Contrib_Count''`
		ceiling=`expr $int % 100`
		int=`bc <<< ''$int'/'100''`
		if [ $ceiling -gt 0 ] ;then int=$(($int+1));fi
	
		Donation_Set=(`echo ${Donation_Set[*]}|tr " " '\n'|sort -n`)
		Array_Correction=$(($int-1))
		Calc_Per=${Donation_Set[$Array_Correction]}
######################
## Shaping the end result
######################	
			
		echo $Position"|"$Recipient"|"$Zip_code"|"$Year1"|"$Calc_Per"|"$Total_Contrib"|"$Contrib_Count >> $way/Unsorted.txt	
		break	
		fi
	fi
unset Contribution
done
done
Counter=$end
done 
sort -t"|" -k 1  $way/Unsorted.txt > $way/sorted.txt
cut -d"|" -f2- $way/sorted.txt > $way/output/repeat_donors.txt
rm $way/Clean.txt $way/numbered.txt $way/Zips.txt $way/sorted_zip.txt $way/repeated_zip.txt $way/Unsorted.txt $way/sorted.txt



