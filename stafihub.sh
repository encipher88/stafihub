#!/bin/bash

echo "-------------------------------------------------------------------------------"
echo -e '\e[40m\e[92m                                                                     '
echo -e '                                                                                 '
echo -e '           ####     +#:             ##*             ##                           '    
echo -e '           ## ##    +#:                             ##                           '   
echo -e ' ##@.-##   ##  ##   +#:   ###:+##+  @#  :###*:###   ####:*###   ##:.%##   +###$$.'
echo -e '##     $$  ##   ##  +#:  ##     %$  @#  :#%     ##  ##     ##  ##     ##  +#-    '  
echo -e '####%***   ##    ##.+#:  ##         @#  :#:     ##  ##     ##  ##*******  +#     '  
echo -e '@#         ##     ##=#:  %#     %$  @#  :##    ##.  ##     ##  ##         +#     '  
echo -e ' ######@%  ##      ###:    #####+   @#  :#:#####    ##     ##   *#####%   +#     '  
echo -e '                                        :#:                                      '   
echo -e '                                        :#:                                      '
echo -e '                                                                                 '
echo -e '\e[0m                                                                            '
echo "-------------------------------------------------------------------------------"

sleep 2

exists()
{
  command -v "$1" >/dev/null 2>&1
}

service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

sleep 3

function setupVars {

	if [ ! $MONIKER ]; then
	read -p "Enter node name: " MONIKER
	echo 'export MONIKER='$MONIKER >> $HOME/.bash_profile
	fi

	if [[ ! $PASSWORD ]]; then
		read -p "Enter wallet password: " PASSWORD
		echo 'export PASSWORD='${PASSWORD} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[45mYour wallet password:' $PASSWORD '\e[0m\n'
	
echo "export WALLET=wallet" >> $HOME/.bash_profile
echo "export CHAIN_ID=stafihub-public-testnet-3" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo 'Your node name: ' $MONIKER
echo 'Your wallet name: ' $WALLET
echo 'Your chain name: ' $CHAIN_ID
echo '================================================='

	sleep 1
	
}





function installDeps {
	echo -e '\n\e[42mPreparing to install\e[0m\n' && sleep 1
	cd $HOME
sudo apt update
sudo apt install make clang pkg-config libssl-dev build-essential git expect jq ncdu bsdmainutils -y < "/dev/null"

cd $HOME
wget -O go1.18.1.linux-amd64.tar.gz https://golang.org/dl/go1.18.1.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz && rm go1.18.1.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
GOPATH=$HOME/go
PATH=$GOPATH/bin:$PATH
go version

echo -e '\n\e[42mSystem update\e[0m\n' && sleep 1
}


function installSoftware {
	sudo systemctl disable stafihubd 
	sudo systemctl stop stafihubd 
	sudo rm -r $HOME/Stafihub $HOME/.Stafihub
	. $HOME/.bash_profile
	 git clone --branch public-testnet-v3 https://github.com/stafihub/stafihub
	 cd $HOME/stafihub && make install
	 
	 stafihubd init $MONIKER --chain-id $CHAIN_ID
wget -O $HOME/.stafihub/config/genesis.json "https://raw.githubusercontent.com/stafihub/network/main/testnets/stafihub-public-testnet-3/genesis.json"
stafihubd tendermint unsafe-reset-all --home ~/.stafihub

rm "/root/.stafihub/config/addrbook.json"
curl -s https://raw.githubusercontent.com/encipher88/stafihub/main/addrbook.json > ~/.stafihub/config/addrbook.json

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.01ufis\"/" $HOME/.stafihub/config/app.toml
sed -i '/\[grpc\]/{:a;n;/enabled/s/false/true/;Ta};/\[api\]/{:a;n;/enable/s/false/true/;Ta;}' $HOME/.stafihub/config/app.toml
peers="4e2441c0a4663141bb6b2d0ea4bc3284171994b6@46.38.241.169:26656,79ffbd983ab6d47c270444f517edd37049ae4937@23.88.114.52:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.stafihub/config/config.toml


echo -e '\n\e[42mNode was intalled\e[0m\n' && sleep 1

}




function installService {
echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1

echo "[Unit]
Description=StaFiHub Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which stafihubd) start
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/stafihubd.service
sudo mv $HOME/stafihubd.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable stafihubd
sudo systemctl restart stafihubd

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service stafihubd status | grep active` =~ "running" ]]; then
  echo -e "Your Stafihub node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mjournalctl -u stafihubd -f\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
  
  echo -e "You can ask for tokens in the #faucet Discord channel. \e[32m!faucet send YOUR_WALLET_ADDRESS\e[39m!"
  
  
else
  echo -e "Your Stafihub node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
. $HOME/.bash_profile
}


function createWallet {
	source $HOME/.bash_profile
	wget -q -O createkeys.sh https://raw.githubusercontent.com/encipher88/stafihub/main/createkeys.sh && chmod +x createkeys.sh 
	bash $HOME/createkeys.sh
}



function recoverWallet {
	source $HOME/.bash_profile
	wget -q -O recoverkey.sh https://raw.githubusercontent.com/encipher88/stafihub/main/recoverkey.sh && chmod +x recoverkey.sh 
	bash $HOME/recoverkey.sh	
}

function deleteStafihub {
	sudo systemctl disable stafihubd 
	sudo systemctl stop stafihubd 
	sudo rm -r $HOME/stafihub $HOME/.stafihub
}



function createValidator {
	source $HOME/.bash_profile
	wget -q -O validator.sh https://raw.githubusercontent.com/encipher88/stafihub/main/validator.sh && chmod +x validator.sh 
	bash $HOME/validator.sh
	echo -e "You can ask for tokens in the #faucet Discord channel. \e[32m!faucet send YOUR_WALLET_ADDRESS\e[39m!"
}





PS3='Please enter your choice (input your option number and press enter): '
options=("Install" "Create wallet" "Restore wallet" "Create validator" "Delete" "Quit")

select opt in "${options[@]}"
do
    case $opt in
        "Install")
            echo -e '\n\e[42mYou choose install...\e[0m\n' && sleep 1
			setupVars
			installDeps
			installSoftware
			installService
			break
            ;;
		"Create wallet")
			echo -e '\n\e[33mYou choose create wallet...\e[0m\n' && sleep 1
			createWallet
			echo -e '\n\e[33mYour wallet was saved in $HOME/.Stafihub/keys folder!\e[0m\n' && sleep 1
			break
            ;;
		"Restore wallet")
			echo -e '\n\e[33mYou choose recovery wallet...\e[0m\n' && sleep 1
			recoverWallet
			echo -e '\n\e[33mYour wallet was recovered\e[0m\n' && sleep 1
			break
            ;;
			
		"Create validator")
			echo -e '\n\e[33mYou choose create Validator...\e[0m\n' && sleep 1
			createValidator
			echo -e '\n\e[33mCheck your validator in explorer.\e[0m\n' && sleep 1
			break
            ;;
			
		"Delete")
            echo -e '\n\e[31mYou choose delete...\e[0m\n' && sleep 1
			deleteStafihub
			echo -e '\n\e[42mStafihub was deleted!\e[0m\n' && sleep 1
			break
            ;;
        "Quit")
            break
            ;;
        *) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
