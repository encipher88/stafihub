#!/bin/bash
echo -e '\n\e[42mCreate validator...\e[0m\n' && sleep 1
echo $PASSWORD |  stafihubd tx staking create-validator -y  --amount=99900000ufis --pubkey=$(stafihubd tendermint show-validator) --moniker=$MONIKER --commission-rate=0.10 --commission-max-rate=0.20 --commission-max-change-rate=0.01 --min-self-delegation=1 --from=$WALLET --chain-id=$CHAIN_ID --gas-prices=0.025ufis
echo -e '\n\e[42mRestarting system ...please wait 10sec \e[0m\n'
sudo systemctl restart stafihubd
sleep 10
stafihubd query staking validators --limit=3000 -oj  | jq -r '.validators[] | [(.tokens|tonumber / pow(10;6)), .description.moniker, .operator_address, .status, .jailed] | @csv'  | column -t -s"," | tr -d '"'| sort -k1 -n -r | nl
echo -e '\n\e[42mFIND YOUR MONIKER - IF YES - YOUR VALIDATOR CREATED  - IF NO - GO TO FAUCET IN DISCORD AND GET TOKENS \e[0m\n' && sleep 1
cd $HOME
