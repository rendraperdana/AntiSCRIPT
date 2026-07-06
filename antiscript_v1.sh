#!/usr/bin/env bash

quarantinedest=/home/quarantine/
monitorpath="/tmp/testscript/"
temp_path="/tmp/"
filetimestamp=null
file_size=0
file_size_limit=1000000000
mitigation_mode=0
#0=quarantine 1=replace

keyword_match_count=0

#You can modify this regex to match newly found page
keyword_match='^<\?php|\#\!\/bin\/'

echo "=========Configuration=========="
echo "Monitored Path: " $monitorpath
echo "Monitored Keyword: " $keyword_match
echo "Quarantine Path: " $quarantinedest
echo "File Size Limit: " $file_size_limit
echo "================================"
echo ""

intervensi_file () {
filesize=$(stat -c %s $path$files)
        if [ $file_size -le $file_size_limit ]; then
                keyword_match_count=$(grep -m 1 -Eo $keyword_match $path$files |sort -u| wc -l)

                if [ $keyword_match_count -ge 1 ]; then
                        if  [ $mitigation_mode -eq 0 ]; then
                                echo "AntiSCRIPT Mitigation Mode: Quarantine"
                                echo "AntiSCRIPT Found keyword match. " $keyword_match_count " string count detected"
                                filetimestamp=$(date +%d_%m_%Y_%H_%M_%S)
                                echo "AntiSCRIPT: moving file " $path$files " to " $quarantinedest$files$filetimestamp
                                mv $path$files $quarantinedest$files$filetimestamp -v
                                echo $path$files >> $quarantinedest$files$filetimestamp
                                chmod 400 $quarantinedest$files$filetimestamp

                        elif [ $mitigation_mode -eq 1 ]; then
                                echo "AntiSCRIPT Mitigation Mode: Replace"
                                readarray -t found_keyword <<< $(grep -Eo $keyword_match $path$files |sort -u)
                                echo "${found_keyword[@]}"
                                mv $path$files $temp_path -v

                                for keyword in "${found_keyword[@]}"
                                do
                                        count_array=0
                                        echo "Replacing Keyword: "$keyword
                                        sed -i "s/$keyword/anti-gacor/Ig" $temp_path$files
                                        count_array=$[$count_array +1]
                                done

                                mv $temp_path$files $path -v
                                echo "Replace Completed"
                        fi

                curl -s --data "text=$path$files$filetimestamp" --data "chat_id=[chatid]" 'https://api.telegram.org/[botid]:[botid]/sendMessage'

                        echo "AntiSCRIPT: quarantined to " $quarantinedest$files$filetimestamp
                        echo "AntiSCRIPT: process completed. Continue watching..."
                else
                        echo "AntiSCRIPT: Keyword match not found on file " $path$files
                fi
        else
                echo "AntiSCRIPT: File" $path$files " larger than 1 MB, skipping file scanning"
        fi
}

inotifywait -m -e ATTRIB,CLOSE_WRITE -c $monitorpath -r -q | while IFS="," read -r path action filesoraction files; do
echo "AntiSCRIPT: Watch variables: " $path $action $filesoraction $files

if ([[ $action == '"CLOSE_WRITE' ]] && [[ $filesoraction == 'CLOSE"' ]]) && ([[ $files == * ]]); then
  echo "AntiSCRIPT: Watch"  $monitorpath$files " : file written match the pattern, processing..." $files
        intervensi_file
fi

don
