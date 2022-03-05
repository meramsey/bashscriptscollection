#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective Find A cPanel Server Global Domlogs Stats for last 5 days for all of their domains.
## How to use.
# ./ApacheDomlogsGlobal.sh
# sh ApacheDomlogsGlobal.sh
#
#echo $1

hostname="hostname"

CURRENTDATE=$(date +"%Y-%m-%d %T") # 2019-02-09 06:47:56
PreviousDay1=$(date --date='1 day ago' +"%Y-%m-%d")  # 2019-02-08
PreviousDay2=$(date --date='2 days ago' +"%Y-%m-%d") # 2019-02-07
PreviousDay3=$(date --date='3 days ago' +"%Y-%m-%d") # 2019-02-06
PreviousDay4=$(date --date='4 days ago' +"%Y-%m-%d") # 2019-02-05

datetimeDom=$(date +"%d/%b/%Y") # 09/Feb/2019
datetimeDom1DaysAgo=$(date --date='1 day ago' +"%d/%b/%Y")  # 08/Feb/2019
datetimeDom2DaysAgo=$(date --date='2 days ago' +"%d/%b/%Y") # 07/Feb/2019
datetimeDom3DaysAgo=$(date --date='3 days ago' +"%d/%b/%Y") # 06/Feb/2019
datetimeDom4DaysAgo=$(date --date='4 days ago' +"%d/%b/%Y") # 05/Feb/2019

echo "Apache Dom Logs POST Requests for ${CURRENTDATE}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r $datetimeDom /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs GET Requests for ${CURRENTDATE}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom" /usr/local/apache/domlogs/ | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${CURRENTDATE}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom" /usr/local/apache/domlogs/ | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs top ten IPs for ${CURRENTDATE}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs find the top number of uri's being requested for ${CURRENTDATE}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom" /usr/local/apache/domlogs/ | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "=============================================================" | tee -a $hostname-ApachelogsGlobal.txt

#Past few days stats
echo "Apache Dom Logs POST Requests for ${PreviousDay1}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom1DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs GET Requests for ${PreviousDay1}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom1DaysAgo" /usr/local/apache/domlogs/ | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay1}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom1DaysAgo" /usr/local/apache/domlogs/ | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs top ten IPs for ${PreviousDay1}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom1DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay1}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom1DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "=============================================================" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs POST Requests for ${PreviousDay2}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom2DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs GET Requests for ${PreviousDay2}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom2DaysAgo" /usr/local/apache/domlogs/ | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay2}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom2DaysAgo" /usr/local/apache/domlogs/ | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs top ten IPs for ${PreviousDay2}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom2DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay2}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom2DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "=============================================================" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs POST Requests for ${PreviousDay3}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom3DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs GET Requests for ${PreviousDay3}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom3DaysAgo" /usr/local/apache/domlogs/ | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay3}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom3DaysAgo" /usr/local/apache/domlogs/ | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs top ten IPs for ${PreviousDay3}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom3DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay3}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom3DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "=============================================================" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs POST Requests for ${PreviousDay4}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom4DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs GET Requests for ${PreviousDay4}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom4DaysAgo" /usr/local/apache/domlogs/ | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay4}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom4DaysAgo" /usr/local/apache/domlogs/ | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs top ten IPs for ${PreviousDay4}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom4DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "" | tee -a $hostname-ApachelogsGlobal.txt
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay4}" | tee -a $hostname-ApachelogsGlobal.txt
sudo grep -r "$datetimeDom4DaysAgo" /usr/local/apache/domlogs/ | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee -a $hostname-ApachelogsGlobal.txt
echo "=============================================================" | tee -a $hostname-ApachelogsGlobal.txt
