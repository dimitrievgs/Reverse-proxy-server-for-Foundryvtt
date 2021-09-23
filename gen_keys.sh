#!/bin/bash
#$1 - target_dir, $2 - server_conf_file_name, $3 - peers_Nr, $4 - server-IP, $5 - UDP-port, $6 - server's network interface
#sudo /root/wireguard/gen_key /root/wireguard/keys server_conf 10 XXX.XXX.XXX.XXX 30000 eth0

dir_name=${1} #$(dirname "${1}")
echo $dir_name

info_file_name="${dir_name}/keys"
touch $info_file_name
> $info_file_name

help_file_name="${dir_name}/help_file"
touch $help_file_name

server_conf_name="${dir_name}/$2.conf"
touch $server_conf_name
> $server_conf_name

declare -a gkeys
declare -a pkeys

> $info_file_name
for (( number = 1; number <= $3 ; number++ ))
do
> $help_file_name
echo "Peer=$number" >> $info_file_name

#gk=$(wg genkey)
#echo "private_key=$gk" >> $info_file_name

pk=$(wg genkey | tee -a $help_file_name | wg pubkey)
gk=$(cat $help_file_name)

#echo "private_key=$gk" >> $info_file_name
#echo "public_key=$pk" >> $info_file_name
gkeys[$number]=$gk
pkeys[$number]=$pk
echo "private_key=${gkeys[$number]}" >> $info_file_name
echo "public_key=${pkeys[$number]}" >> $info_file_name

done


# make server config
echo "[Interface]" >> $server_conf_name
echo "Address=10.10.0.1/24" >> $server_conf_name
echo "ListenPort=$5" >> $server_conf_name
echo "PrivateKey=${gkeys[1]}" >> $server_conf_name
echo "PostUp=iptables -A FORWARD -i $2 -j ACCEPT; iptables -t nat -A POSTROUTING -o $6 -j MASQUERADE; ip6tables -A FORWARD -i $2 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $6 -j MASQUERADE" >> $server_conf_name
echo "PostDown=iptables -D FORWARD -i $2 -j ACCEPT; iptables -t nat -D POSTROUTING -o $6 -j MASQUERADE; ip6tables -D FORWARD -i $2 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $6 -j MASQUERADE" >> $server_conf_name

for (( cl_n = 2; cl_n <= $3 ; cl_n++ ))
do
echo "[Peer]" >> $server_conf_name
echo "PublicKey=${pkeys[$cl_n]}" >> $server_conf_name
echo "AllowedIPs=10.10.0.$cl_n/32" >> $server_conf_name
done

# make clients config
for (( cl_n = 2; cl_n <= $3 ; cl_n++ ))
do
client_conf_name="${dir_name}/client_${cl_n}.conf"
touch $client_conf_name
> $client_conf_name

echo "[Interface]" >> $client_conf_name
echo "PrivateKey=${gkeys[$cl_n]}" >> $client_conf_name
echo "Address=10.10.0.$cl_n/24" >> $client_conf_name
echo "[Peer]" >> $client_conf_name
echo "PublicKey=${pkeys[1]}" >> $client_conf_name
echo "Endpoint=$4:$5" >> $client_conf_name
echo "AllowedIPs=10.10.0.0/24" >> $client_conf_name
echo "PersistentKeepalive=25" >> $client_conf_name
done