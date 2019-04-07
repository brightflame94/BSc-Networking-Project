set -e
# Number of requests
reqno=1000
# Make test directories
#
mkdir -p ./results/single/no_dpi
mkdir -p ./results/single/dpi
mkdir -p ./results/cluster/no_dpi
mkdir -p ./results/cluster/dpi
mkdir -p ./results/combined
#
#Make test files if they don't exist

#
#Get topology input
#
echo "Choose Topology [Single Firewall = 1, Firewall Cluster = 2]:"
read topology_val
#
# Parse topology choice
if [ $(($topology_val)) -eq 1 ]
then
	topology="single"
	dest_ip="172.16.0.1"
elif [ $(($topology_val)) -eq 2 ] 
then
	topology="cluster"
	dest_ip="172.18.0.1"
else
	echo "Invalid topology entry"
	exit
fi
#
# Get security input
echo "Choose Security [No DPI = 1, DPI = 2]:"
read security_val
#
# Parse security choice
if [ $(($security_val)) -eq 1 ]
then
	security="no_dpi"
elif [ $(($security_val)) -eq 2 ]
then
	security="dpi"
else
	echo "Invalid security entry"
	exit
fi
#
# Get test count
echo "Enter test number:"
read testno
#
#
echo "Choose test type [Standard = 1, Payload = 2]:"
read testtype
if [ $(($testtype)) -eq 1 ]
then
currentdir=./results/${topology}/${security}/
filename=${topology}_${security}_test${testno}
#Start Wireshark
#
touch ${currentdir}/${filename}_wscap
( wireshark -i enp1s0 -k -w ${currentdir}/${filename}_wscap ) &
sleep 7
#
#
currentdate=$(date '+%d/%m/%Y %H:%M:%S');
zenity --info --text "All http requests sent"
# stop wireshark
read -p "Once Wireshark has been closed press enter to continue."
#
echo "Exporting test results..."
mkdir -p ./results/combined/combined_${testno}
tshark -r ${currentdir}/${filename}_wscap -q -z conv,tcp > ${currentdir}/${filename}_tcpconv
#Average HTTP Requests per second
{ echo "$currentdate,$testno,$topology $security," | tr -d "\n"; \
grep "Requests per second:" ${currentdir}/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $4 }'; } >> ~/Desktop/results/combined/combined_${testno}/requests_per_second
#
#Average time per HTTP request
{ echo "$currentdate,$testno,$topology $security," | tr -d "\n"; \
grep "Time per request:" ${currentdir}/${filename}_ab_out | grep "(mean)" \
| awk 'BEGIN { FS = " " } ; { print $4 }'; } >> ~/Desktop/results/combined/combined_${testno}/average_request_time
#
#Total Time Taken
{ echo "$currentdate,$testno,$topology $security," | tr -d "\n"; \
grep "Time taken for tests:" ${currentdir}/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $5 }'; } >> ~/Desktop/results/combined/combined_${testno}/total_time_taken
#
#Total Data Transferred
{ echo "$currentdate,$testno,$topology $security," | tr -d "\n"; \
grep "Total transferred:" ${currentdir}/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $3 }'; } >> ~/Desktop/results/combined/combined_${testno}/total_data_transferred
#
#Transfer Rate
{ echo "$currentdate,$testno,$topology $security," | tr -d "\n"; \
grep "Transfer rate:" ${currentdir}/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $3 }'; } >> ~/Desktop/results/combined/combined_${testno}/transfer_rates
#
echo "All tests saved successfully."
#
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#
elif [ $(($testtype)) -eq 2 ]
then
mkdir -p ./results/${topology}/${security}/payload_tests_${testno}/other_files
currentdir=./results/${topology}/${security}/payload_tests_${testno}

for i in 1 2 3 4 5 6 7 8 9 10
do
echo "Payload $i:"
size=$(( 2 + (0.5 * ($i - 1)) ))
filename=${topology}_${security}_test${testno}_payload${i}
#Start Wireshark
#
touch ${currentdir}/other_files/${filename}_wscap
( wireshark -i enp1s0 -k -w ${currentdir}/other_files/${filename}_wscap ) &
sleep 7
#
#
currentdate=$(date '+%d/%m/%Y %H:%M:%S');
zenity --info --text "All http requests sent"
# stop wireshark
read -p "Once Wireshark has been closed press enter to continue."
#
echo "Exporting test results..."
tshark -r ${currentdir}/other_files/${filename}_wscap -q -z conv,tcp > ${currentdir}/other_files/${filename}_tcpconv
#Average HTTP Requests per second
{ echo "$currentdate,$size," | tr -d "\n"; \
grep "Requests per second:" ${currentdir}/other_files/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $4 }'; } >> ${currentdir}/requests_per_second
#
#Average time per HTTP request
{ echo "$currentdate,$size," | tr -d "\n"; \
grep "Time per request:" ${currentdir}/other_files/${filename}_ab_out | grep "(mean)" \
| awk 'BEGIN { FS = " " } ; { print $4 }'; } >> ${currentdir}/average_request_time
#
#Total Time Taken
{ echo "$currentdate,$size," | tr -d "\n"; \
grep "Time taken for tests:" ${currentdir}/other_files/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $5 }'; } >> ${currentdir}/total_time_taken
#
#Total Data Transferred
{ echo "$currentdate,$size," | tr -d "\n"; \
grep "Total transferred:" ${currentdir}/other_files/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $3 }'; } >> ${currentdir}/total_data_transferred
#
#Transfer Rate
{ echo "$currentdate,$size," | tr -d "\n"; \
grep "Transfer rate:" ${currentdir}/other_files/${filename}_ab_out \
| awk 'BEGIN { FS = " " } ; { print $3 }'; } >> ${currentdir}/transfer_rates
#
echo "All tests for payload ${i} saved successfully."
echo "------------------------------------------------------------------------"
#
done
#
echo "All payload tests completed successfully."

else
echo "Invalid test type"
echo "------------------------------------------------------------------------"
exit
fi
