#!/bin/bash
# Server update
sudo apt update && sudo apt upgrade -y


# Install packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu net-tools -y


# Install GO 1.17.1
ver="1.17.1"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile


# Install OpenVPN
apt install apt-transport-https -y
curl -fsSL https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/openvpn-repo-pkg-keyring.gpg

# Ubuntu	20.04	= focal
curl -fsSL https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-focal.list >/etc/apt/sources.list.d/openvpn3.list

apt update -y
apt install openvpn3 -y

# Build masa-node
git clone https://github.com/masa-finance/masa-node-v1.0
cd masa-node-v1.0/src
make all

cd $HOME/masa-node-v1.0/src/build/bin
cp * /usr/local/bin


# Install geth goquorum
cd $HOME
wget https://artifacts.consensys.net/public/go-quorum/raw/versions/v21.10.0/geth_v21.10.0_linux_amd64.tar.gz
tar -xvf geth_v21.10.0_linux_amd64.tar.gz
rm -v geth_v21.10.0_linux_amd64.tar.gz

chmod +x $HOME/geth
sudo mv $HOME/geth /usr/bin/

# Init masa-node
cd $HOME/masa-node-v1.0
geth --datadir data init ./network/testnet/genesis.json


# Set vars
PRIVATE_CONFIG=ignore
echo 'export PRIVATE_CONFIG='${PRIVATE_CONFIG} >> $HOME/.bash_profile
source $HOME/.bash_profile

sudo tee /etc/systemd/system/masad.service > /dev/null <<EOF
[Unit]
Description=MASA
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/geth --identity ${NODE_NAME} --datadir $HOME/masa-node-v1.0/data --bootnodes enode://ac6b1096ca56b9f6d004b779ae3728bf83f8e22453404cc3cef16a3d9b96608bc67c4b30db88e0a5a6c6390213f7acbe1153ff6d23ce57380104288ae19373ef@172.16.239.11:21000  --emitcheckpoints --istanbul.blockperiod 1 --mine --minerthreads 1 --syncmode full --verbosity 5 --networkid 190250 --rpc --rpccorsdomain "*" --rpcvhosts "*" --rpcaddr 127.0.0.1 --rpcport 8545 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul --port 30300
Restart=on-failure
RestartSec=10
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable masad
sudo systemctl restart masad



