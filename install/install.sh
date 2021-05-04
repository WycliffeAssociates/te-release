#!/bin/bash

#run this next line if you need to make this file executable
# sudo chmod +x /home/ott/install.sh

set -e

COLOR='\033[0;35m'
NC='\033[0m'

USER=$1

if [ -z "$1" ]
  then
    USER="ott"
fi

if [[ $(grep -c "^$USER:" /etc/passwd) = 0 ]]; then
	echo "Error: User '$USER' doesn't exist" 1>&2
	exit 1
fi

cd /home/$USER/btt-exchanger

HEIGHT=10
WIDTH=70
CHOICE_HEIGHT=3
TITLE="Access Point"
MENU="Choose one of the following options:"

OPTIONS=("1" "Run a Wifi Access Point on the server hardware"
         "2" "Run an external access point (e.g. TP-Link TL-WR802N)")

CHOICE=$(whiptail --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                3>&1 1>&2 2>&3)

case $CHOICE in
        1)
            sudo cp /home/$USER/btt-exchanger/cron_dockerup_server_ap /etc/cron.d/cron_dockerup_server_ap
            ;;
        2)
            sudo cp /home/$USER/btt-exchanger/cron_dockerup_external_ap /etc/cron.d/cron_dockerup_external_ap
            ;;
esac

echo -e "${COLOR}----------| Installing neccessary software for the server... |----------${NC}"

sudo apt update && sudo apt install -y curl python3-pip apt-transport-https ca-certificates software-properties-common jq
sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update && sudo apt install -y docker-ce
sudo pip install docker-compose==1.27
sudo chmod -R +x /home/$USER/btt-exchanger/scripts

echo -e "${COLOR}----------| Downloading clients |----------${NC}"

URL=$(curl 'https://api.github.com/repos/bible-translation-tools/btt-exchanger/releases?per_page=1' | jq -r '.[] | .assets[] | select(.name == "clients.zip") | .browser_download_url')
curl -L $URL --output clients.zip
rm -rf clients/
unzip clients.zip

echo -e "${COLOR}----------| Downloading TranslationRecorder|----------${NC}"

URL=$(curl 'https://api.github.com/repos/Bible-Translation-Tools/BTT-Recorder/releases?per_page=1' | jq -r '.[0] | .assets[].browser_download_url')
curl -L $URL --output clients/bttRecorder.apk

echo -e "${COLOR}----------| Downloading AdminTools into admintools dir |----------${NC}"

URL=$(curl 'https://api.github.com/repos/bible-translation-tools/btt-exchanger/releases?per_page=1' | jq -r '.[] | .assets[] | select(.name == "admintools.zip") | .browser_download_url')
curl -L $URL --output admintools.zip
rm -rf admintools/
unzip admintools.zip
cd admintools
URL=$(curl 'https://api.github.com/repos/wycliffeassociates/tr-chunk-browser/releases?per_page=1' | jq -r '.[0] | .assets[].browser_download_url')
curl -L $URL -O
URL=$(curl 'https://api.github.com/repos/wycliffeassociates/trconverterandroid/releases?per_page=1' | jq -r '.[0] | .assets[].browser_download_url')
curl -L $URL -O
cd /home/$USER/btt-exchanger

sudo -- sh -c -e "echo '10.0.0.1	opentranslationtools.org' >> /etc/hosts"

echo -e "${COLOR}----------| Pulling Docker Images... |----------${NC}"

sudo docker-compose -f docker-compose-ext-ap.yaml pull
sudo docker-compose -f docker-compose-server-ap.yaml pull

clear
if [ $CHOICE == 1 ]; then read -n 1 -s -r -p "Installation complete. press Enter to reboot" && sleep 1 && sudo systemctl reboot; fi
if [ $CHOICE == 2 ]; then read -n 1 -s -r -p "Installation complete. Please unplug network cable then press Enter to reboot" && sleep 1 && sudo systemctl reboot; fi
