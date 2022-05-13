#!/bin/bash
	echo -e "\n\e[42mPreparing to create wallet...\e[0m\n" && sleep 1
	apt install expect
	sleep 2
		if [[ ! $mnemonic ]]; then
		read -r -p "Enter bip39 mnemonic: " var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 var12 var13 var14 var15 var16 var17 var18 var19 var20 var21 var22 var23 var24 "
		echo 'export mnemonic='${mnemonic} >> $HOME/.bash_profile
	fi
	source $HOME/.bash_profile
sudo tee <<EOF >/dev/null $HOME/.stafihub/stafihub_add_key.sh 
#!/usr/bin/expect -f
EOF
echo "set timeout -1
spawn stafihubd keys add $WALLET --recover --home $HOME/.stafihub
expect -exact \"Enter your bip39 mnemonic\"
send -- \"$mnemonic\r\"

match_max 100000
expect -exact \"Enter keyring passphrase:\"
send -- \"$PASSWORD\r\"
expect -exact \"\r
Re-enter keyring passphrase:\"
send -- \"$PASSWORD\r\"
expect eof" >> $HOME/.stafihub/stafihub_add_key.sh
sudo chmod +x $HOME/.stafihub/stafihub_add_key.sh
$HOME/.stafihub/stafihub_add_key.sh &>> $HOME/.stafihub/$WALLET.txt

echo -e "You can find your mnemonic by the following command:"
echo -e "\e[32mcat $HOME/.stafihub/$WALLET.txt\e[39m"

export WALLET_ADDRESS=`cat $HOME/.stafihub/$WALLET.txt | grep address | awk '{split($0,addr," "); print addr[2]}' | sed 's/.$//'`
echo 'export WALLET_ADDRESS='${WALLET_ADDRESS} >> $HOME/.bash_profile
. $HOME/.bash_profile
echo -e '\n\e[45mYour wallet address:' $WALLET_ADDRESS '\e[0m\n'

cd $HOME

sleep 5

touch $HOME/.stafihub/valop.txt
sudo tee <<EOF >/dev/null $HOME/.stafihub/stafihub_add_valkey.sh 
#!/usr/bin/expect -f
EOF
echo "set timeout -1
spawn stafihubd keys show $WALLET --bech val -a
match_max 100000
expect -exact \"Enter keyring passphrase:\"
send -- \"$PASSWORD\r\"
expect -exact \"\r
Re-enter keyring passphrase:\"
send -- \"$PASSWORD\r\"
expect eof" >> $HOME/.stafihub/stafihub_add_valkey.sh
sudo chmod +x $HOME/.stafihub/stafihub_add_valkey.sh
$HOME/.stafihub/stafihub_add_valkey.sh &>> $HOME/.stafihub/valop.txt

export VALOPER_ADDRESS=`cat $HOME/.stafihub/valop.txt | grep '^stafivaloper' | awk '{print$1}' | sed 's/.$//'`
echo 'export VALOPER_ADDRESS='${VALOPER_ADDRESS} >> $HOME/.bash_profile
. $HOME/.bash_profile
echo -e '\n\e[45mYour validator address:' $VALOPER_ADDRESS '\e[0m\n'

echo -e "You can ask for tokens in the #faucet Discord channel. \e[32m!faucet send YOUR_WALLET_ADDRESS\e[39m!"
cd $HOME
