#!/bin/sh

# Regular Colors
BLACK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow
BLUE='\033[0;34m'         # Blue
PURPLE='\033[0;35m'       # Purple
CYAN='\033[0;36m'         # Cyan
WHITE='\033[0;37m'        # White
NC='\033[0m'              # No Color

echo "${YELLOW} checking internet connection ${NC}\n"

INTERNET_STATUS="UNKNOWN"
TIMESTAMP=`date +%s`

    ping -c 1 -W 0.7 8.8.4.4 > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        if [ "$INTERNET_STATUS" != "UP" ]; then
            echo "${BLUE}Internet connection is UP, continuing${NC}\n   `date +%Y-%m-%dT%H:%M:%S%Z` $((`date +%s`-$TIMESTAMP))";
            INTERNET_STATUS="UP"
	    rm -rf ~/Desktop/check-qortal-status.sh
	    curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/check-qortal-status.sh && mv check-qortal-status.sh ~/qortal && chmod +x ~/qortal/check-qortal-status.sh
	    curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/start-qortal.sh && chmod +x start-qortal.sh
	    curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/refresh-qortal.sh && chmod +x refresh-qortal.sh
	fi
    else
        if [ "$INTERNET_STATUS" = "UP" ]; then
            echo "${RED}Internet Connection is DOWN, please fix connection and restart device, script will re-run automatically after 7 min.${NC}\n `date +%Y-%m-%dT%H:%M:%S%Z` $((`date +%s`-$TIMESTAMP))";
            INTERNET_STATUS="DOWN"
	    sleep 30
	    exit 1
        fi
    fi


echo "${YELLOW} Checking hash of qortal.jar on liocal machine VS newest released qortal.jar on github ${NC}\n"

cd ~/qortal
md5sum qortal.jar > "local.md5"
cd


echo "${CYAN} Grabbing newest released jar to check hash ${NC}\n"

curl -L -O https://github.com/qortal/qortal/releases/latest/download/qortal.jar

md5sum qortal.jar > "remote.md5"


LOCAL=$(cat ~/qortal/local.md5)
REMOTE=$(cat ~/remote.md5)


if [ "$LOCAL" = "$REMOTE" ]; then

    echo "${BLUE} Your Qortal Core is up-to-date! No action needed. ${NC}\n"
    sleep 3
    rm ~/qortal.jar
    rm ~/qortal/local.md5 remote.md5
    mkdir ~/qortal/new-scripts
    mkdir ~/qortal/new-scripts/backups
    mv ~/qortal/new-scripts/auto-fix-qortal.sh ~/qortal/new-scripts/backups
    cp ~/auto-fix-qortal.sh ~/qortal/new-scripts/backups/original.sh
    cd ~/qortal/new-scripts
    curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/auto-fix-qortal.sh
    chmod +x auto-fix-qortal.sh
    cd
    cp ~/qortal/new-scripts/auto-fix-qortal.sh .


else

    echo "${RED} Your Qortal Core is OUTDATED, refreshing and starting qortal... ${NC}\n"
    cd qortal
    killall -9 java
    sleep 3
    rm -rf db
    rm ~/qortal/qortal.jar
    rm log.t*
    cp ~/qortal.jar ~/qortal
    rm ~/qortal.jar
    rm ~/remote.md5 local.md5
    ./start.sh
    mkdir ~/qortal/new-scripts
    mkdir ~/qortal/new-scripts/backups
    cp ~/qortal/new-scripts/auto-fix-qortal.sh ~/qortal/new-scripts/backups
    rm ~/qortal/new-scripts/auto-fix-qortal.sh
    cp ~/auto-fix-qortal.sh ~/qortal/new-scripts/backups/original.sh
    cd ~/qortal/new-scripts
    curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/auto-fix-qortal.sh
    chmod +x auto-fix-qortal.sh
    cd
    cp ~/qortal/new-scripts/auto-fix-qortal.sh .
fi

  if [ "$(uname -m | grep 'armv7l')" != "" ]; then
      echo "${WHITE} 32bit ARM detected, using ARM 32bit compatible modified start script${NC}\n"
      curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/start-modified-memory-args.sh
      chmod +x start-modified-memory-args.sh
      mv start-modified-memory-args.sh ~/qortal/start.sh
  else
      echo "${WHITE} Machine is not ARM 32bit, continuing to check memory and assign correct start script...${NC}\n"
  fi

if command -v raspi-config >/dev/null 2>&1 ; then
	echo "${YELLOW} Raspberry Pi machine detected, creating pi cron and exiting...${NC}\n"
	curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/auto-fix-cron
	crontab auto-fix-cron
	rm auto-fix-cron
	exit 1
    else echo "${YELLOW} Not a Raspberry pi machine, continuing...${NC}\n"

fi

totalm=$(free -m | awk '/^Mem:/{print $2}')

echo "${YELLOW} Checking system RAM ... $totalm System RAM ... Configuring system for optimal RAM settings...${NC}\n"
    if [ "$totalm" -le 6000 ]; then
        echo "${WHITE} Machine has less than 6GB of RAM, Downloading correct start script for your configuration...${NC}\n"
        curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/start-modified-memory-args.sh && mv start-modified-memory-args.sh ~/qortal/start.sh && chmod +x ~/qortal/start.sh
    elif [ "$totalm" -ge 6001 ] && [ "$totalm" -le 16000 ]; then
        echo "${WHITE} Machine has between 6GB and 16GB of RAM, Downloading correct start script for your configuration...${NC}\n"
        curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/start-6001-to-16000m.sh && mv start-6001-to-16000m.sh ~/qortal/start.sh && chmod +x ~/qortal/start.sh
    else echo "${WHITE} Machine has more than 16GB of RAM, using default start script and continuing...${NC}\n"
        curl -L -O https://raw.githubusercontent.com/Qortal/qortal/master/start.sh && mv start.sh ~/qortal/start.sh && chmod +x ~/qortal/start.sh
    fi



    if command -v gnome-terminal >/dev/null 2>&1 ; then

        echo "${YELLOW} Setting up auto-fix-visible on GUI-based system... first, creating new crontab entry without auto-fix-startup... ${NC}\n"
        sleep 2
        curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/auto-fix-GUI-cron
        crontab auto-fix-GUI-cron
        rm auto-fix-GUI-cron
        echo "${YELLOW} Setting up new ${NC}\n ${WHITE} 'auto-fix-qortal-GUI.desktop' ${NC}\n ${YELLOW} file for GUI-based machines to run 7 min after startup in a visual fashion. Entry in 'startup' will be called ${NC}\n ${WHITE} 'auto-fix-visible' ${NC}\n"
        curl -L -O https://raw.githubusercontent.com/crowetic/QORTector-scripts/main/auto-fix-qortal-GUI.desktop
        mkdir ~/.config/autostart
        cp auto-fix-qortal-GUI.desktop ~/.config/autostart
        rm ~/auto-fix-qortal-GUI.desktop
        echo "${YELLOW} Your machine will now run 'auto-fix-qortal.sh' script in a fashion you can SEE, 7 MIN AFTER YOU REBOOT your machine. The normal 'background' process for auto-fix-qortal will continue as normal.${NC}\n"
        exit 1

    else echo "${YELLOW} Non-GUI system detected, skipping 'auto-fix-visible' setup ${NC}\n"

fi

sleep 10
exit 1
