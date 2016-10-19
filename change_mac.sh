# Change mac address to something random
export interface=$1
ifconfig $interface ether 00:$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//')
