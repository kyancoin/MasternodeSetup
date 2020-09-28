#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='kyan.conf'
CONFIGFOLDER='/root/.kyancore'
COIN_DAEMON='kyand'
COIN_CLI='kyan-cli'
COIN_TX='kyan-tx'
COIN_PATH='/usr/local/bin/'
OS_VERSION=$(lsb_release -d)
COIN_TGZP='https://github.com/kyancoin/KYAN/releases/download/v0.15.0.0.k/KYAN-0.15-Linux.zip'
COIN_BOOTSTRAP='https://github.com/kyancoin/KYAN/releases/download/v0.15.0.0.k/bootstrap.zip'
COIN_BOOTSTRAP_NAME=$(echo $COIN_BOOTSTRAP | awk -F'/' '{print $NF}')
COIN_TGZ=$(echo $COIN_TGZP | awk -F'/' '{print $NF}')
COIN_NAME='kyan'
COIN_NAME_OLD='kyand'
PROJECT_NAME='Kyanite Coin (KYAN)'
COIN_EXPLORER='https://explorer.kyancoin.net/'
COIN_PORT=7577
RPC_PORT=17577

NODEIP=$(curl -s4 icanhazip.com)

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m" 
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

LICON=$'#'

purgeOldInstallation() {
    echo -e "${YELLOW}Searching and removing old ${BLUE}$PROJECT_NAME ${GREEN}Masternode ${YELLOW}files and configurations${NC}"
	#stopping service
	systemctl stop $COIN_NAME.service  > /dev/null 2>&1 &
	systemctl stop $COIN_NAME_OLD.service  > /dev/null 2>&1 &
	echo -ne "${RED}${LICON}${LICON}${LICON} ${GREEN}(10%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(20%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(30%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(40%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(50%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(60%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(70%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(80%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(90%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(100%)${NC}\r"
	sleep 1
	echo -ne '\n'
	# sleep 10
    #kill wallet daemon
	killall $COIN_DAEMON > /dev/null 2>&1
    #remove old ufw port allow
    ufw delete allow $COIN_PORT/tcp > /dev/null 2>&1
    #remove old files
    rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1
    rm -rf ~/.$COIN_NAME > /dev/null 2>&1
    #remove binaries and $COIN_NAME utilities
    cd /usr/local/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
    echo -e "${GREEN}* Done${NONE}";
}

function install_sentinel() {
  echo -e "${GREEN}Installing sentinel.${NC}"
  apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
  git clone $SENTINEL_REPO $CONFIGFOLDER/sentinel >/dev/null 2>&1
  cd $CONFIGFOLDER/sentinel
  virtualenv ./venv >/dev/null 2>&1
  ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
  echo  "* * * * * cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py >> $CONFIGFOLDER/sentinel.log 2>&1" > $CONFIGFOLDER/$COIN_NAME.cron
  crontab $CONFIGFOLDER/$COIN_NAME.cron
  rm $CONFIGFOLDER/$COIN_NAME.cron >/dev/null 2>&1
}

function download_node() {
  echo -e "${GREEN}Downloading and Installing VPS ${BLUE}$PROJECT_NAME ${GREEN}Daemon${NC}"
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZP
  #compile_error
  unzip $COIN_TGZ >/dev/null 2>&1
  rm -r $COIN_TGZ >/dev/null 2>&1

  #compile_error
  chmod +x $COIN_DAEMON >/dev/null 2>&1
  chmod +x $COIN_CLI >/dev/null 2>&1
  chmod +x $COIN_DAEMON >/dev/null 2>&1
  chmod +x $COIN_CLI >/dev/null 2>&1
  chmod +x $COIN_TX >/dev/null 2>&1
  sudo cp $COIN_DAEMON $COIN_PATH >/dev/null 2>&1
  sudo cp $COIN_DAEMON /root/ >/dev/null 2>&1
  sudo cp $COIN_CLI $COIN_PATH >/dev/null 2>&1
  sudo cp $COIN_CLI /root/ >/dev/null 2>&1
  sudo cp $COIN_TX $COIN_PATH >/dev/null 2>&1
  sudo cp $COIN_TX /root/ >/dev/null 2>&1
  cd ~ >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

	echo -e "\n${GREEN}Reloading Service Daemon${NC}\n"
  	systemctl daemon-reload
	echo -ne "${RED}${LICON}${LICON}${LICON}## ${GREEN}(33%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}# ${GREEN}(66%)${NC}\r"
	sleep 1
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}## ${GREEN}(100%)${NC}\r"
	sleep 1
	echo -ne '\n'
    echo -e "${GREEN}* Done${NONE}";
#   sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1
  echo -e "\n${BLUE}$PROJECT_NAME ${GREEN}Service Status\n${NC}"
  systemctl status $COIN_NAME.service
  echo -e "\n${BLUE}=======================================================================================================${NC}\n"


  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}


function create_config() {
  echo -e "${YELLOW}Downloading and extracting bootstrap${NC}"
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  cd $CONFIGFOLDER >/dev/null 2>&1
  wget $COIN_BOOTSTRAP >/dev/null 2>&1
  unzip $COIN_BOOTSTRAP_NAME >/dev/null 2>&1
  rm -r $COIN_BOOTSTRAP_NAME >/dev/null 2>&1
  cd ~
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
#----
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
#----
listen=1
server=1
daemon=1
#----
EOF
}

$COIN_PATH$COIN_DAEMON -daemon
	echo -ne "${RED}${LICON}${LICON}${LICON} ${GREEN}(10%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(20%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(30%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(40%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(50%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(60%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(70%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(80%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(90%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(100%)${NC}\r"
	sleep 3
	echo -ne '\n'
    echo -e "${GREEN}* Done${NONE}";
    # sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.${$NC}"
   exit 1
  fi
  BLS_PUBLIC_KEY=$(kyan-cli bls generate | grep public | awk -F: '{ print $2 }' | awk -F\" '{ print $2 }')
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the ${GREEN}Masternode Key${NC}"
	echo -ne "${RED}${LICON}${LICON}${LICON} ${GREEN}(10%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(20%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(30%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(40%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(50%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(60%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(70%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(80%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(90%)${NC}\r"
	sleep 3
	echo -ne "${RED}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON}${LICON} ${GREEN}(100%)${NC}\r"
	sleep 3
	echo -ne '\n'
    echo -e "${GREEN}* Done${NONE}";
#   sleep 30

function create_key() {
  BLS_SECRET_KEY=$(kyan-cli bls generate | grep secret | awk -F: '{ print $2 }' | awk -F\" '{ print $2 }')
  BLS_PUBLIC_KEY=$(kyan-cli bls generate | grep public | awk -F: '{ print $2 }' | awk -F\" '{ print $2 }')
  
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
maxconnections=256
bind=$NODEIP:$COIN_PORT
externalip=$NODEIP
masternodeblsprivkey=${BLS_SECRET_KEY}
EOF
}


function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}


function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
# if [[ $(lsb_release -d) != *16.04* ]]; then
#   echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
#   exit 1
# fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC} Please Run again.."
  exit 1
fi
}

function prepare_system() {
echo -e "${YELLOW}Preparing the VPS to setup ${BLUE}$PROJECT_NAME ${GREEN}Masternode${NC}"

rm /var/lib/apt/lists/lock > /dev/null 2>&1
rm /var/cache/apt/archives/lock > /dev/null 2>&1
rm /var/lib/dpkg/lock > /dev/null 2>&1

apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${PURPLE}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install libzmq3-dev -y >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ libstdc++6 unzip libzmq5 >/dev/null 2>&1

# if [[ $(lsb_release -d) == *16.04* ]]; then
# 	add-apt-repository -y ppa:ubuntu-toolchain-r/test >/dev/null 2>&1
# 	apt-get update >/dev/null 2>&1
# 	apt-get -y upgrade >/dev/null 2>&1
# 	apt-get -y dist-upgrade >/dev/null 2>&1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_atomic.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_atomic.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_chrono.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_chrono.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_date_time.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_date_time.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_iostreams.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_iostreams.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_prg_exec_monitor.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_prg_exec_monitor.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_serialization.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_serialization.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_system.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_unit_test_framework.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_unit_test_framework.so.1.65.1
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_wserialization.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_wserialization.so.1.65.1

# 	# libevent_* version fixes
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libevent-2.0.so.5.1.9 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.6
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libevent_core-2.0.so.5.1.9 /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.6
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libevent_extra-2.0.so.5.1.9 /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.6
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libevent_openssl-2.0.so.5.1.9 /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.6
# 	sudo ln -s /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.0.so.5.1.9 /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.6
# fi

# if [ "$?" -gt "0" ];
#   then
#     echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
#     echo "apt-get update"
#     echo "apt -y install software-properties-common"
#     echo "apt-add-repository -y ppa:bitcoin/bitcoin"
#     echo "apt-get update"
#     echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
# libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
# bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
#  exit 1
# fi
clear
}

function important_information() {
 echo
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "$PROJECT_NAME Wallet is up and running listening on port ${GREEN}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "Check Status: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "Check ${RED}$COIN_CLI getblockcount${NC} and compare to ${GREEN}$COIN_EXPLORER${NC}."
 echo -e "Or check ${RED}$COIN_CLI mnsync status${NC} and it it's ${GREEN}IsSynced: true{NC} then follow the next step."
 echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN Status(wait for Hotnode and remote activation status before go to next step)"
 
 
 
 function register_your_masternode() {
  echo -e "${YELLOW}Enter your ${BLUE}$PROJECT_NAME ${GREEN}collateralHash${YELLOW} from your debug console ${RED}masternode outputs${YELLOW} command${NC}"
  read -e collateralHash
  
  echo -e "${YELLOW}Enter your ${BLUE}$PROJECT_NAME ${GREEN}collateralIndex(0 or 1)${YELLOW} from your debug console ${RED}masternode outputs${YELLOW} command${NC}"
  read -e collateralIndex
  
  echo -e "${YELLOW}Enter your ${BLUE}$PROJECT_NAME ${GREEN}Owner address${RED}(It must be newly created and unused address)${NC}"
  read -e ownerKeyAddr
  
  echo -e "${YELLOW}Enter your ${BLUE}$PROJECT_NAME ${GREEN}Reward address${RED}(This address will receive masternode reward)${NC}"
  read -e payoutAddress
  
  echo -e "${YELLOW}Enter your ${BLUE}$PROJECT_NAME ${GREEN}FeeSourceAddress${RED}(This address need little balance to make a transation, 1 $PROJECT_NAME will be enough, make sure you send 1 $PROJECT_NAME to this address)${NC}"
  read -e feeSourceAddress
 
 echo -e "${YELLOW}Enter the following command in your debug console${RED}(Make sure your wallet in unlock)${NC}"
 echo -e "${GREEN}protx register_prepare $collateralHash$ $collateralIndex$ $NODEIP:$COIN_PORT $ownerKeyAddr ${BLS_PUBLIC_KEY} $ownerKeyAddr 0 $payoutAddress $feeSourceAddress${NC}"
    
  echo -e "${YELLOW}Paste the Outputs${RED}(Make sure you copy and paste correctly)${NC}"
  read -e OUTPUTS
  collateralAddress=$($OUTPUTS | grep collateralAddress | awk -F: '{ print $2 }' | awk -F\" '{ print $2 }')
  signMessage=$($OUTPUTS | grep signMessage | awk -F: '{ print $2 }' | awk -F\" '{ print $2 }')
  tx=$($OUTPUTS | grep tx | awk -F: '{ print $2 }' | awk -F\" '{ print $2 }')  

 echo -e "${YELLOW}Enter the following command in your debug console${RED}(Sign the ProRegTx transaction)${NC}"
echo -e "${GREEN}signmessage $collateralAddress $signMessage
echo -e "${YELLOW}Paste the Outputs${RED}(Make sure you copy and paste correctly)${NC}"
read -e sig

echo -e "${YELLOW}Enter the following command in your debug console${RED}(Submit the signed message)${NC}"
echo -e "${GREEN}protx register_submit $tx $sig${NC}"

echo -e "${GREEN}The output will look like this: aba8c22f8992d78fd4ff0c94cb19a5c30e62e7587ee43d5285296a4e6e5af062, Your masternode is now registered and will appear on the Deterministic Masternode List after the transaction is mined to a block. You can view this list on the Masternodes Tab${NC}"
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  #install_sentinel
  important_information
  configure_systemd
  register_your_masternode
}


${LICON}${LICON}${LICON}## Main ${LICON}${LICON}${LICON}##
clear

purgeOldInstallation
checks
prepare_system
download_node
setup_node
set_scripts_and_aliases
