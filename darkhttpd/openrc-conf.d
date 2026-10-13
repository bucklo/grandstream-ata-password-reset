# /etc/conf.d/darkhttpd on Alpine Linux (OpenRC).
#   apk add darkhttpd
#   mkdir -p /srv/ata-prov && cp cfg<mac>.xml /srv/ata-prov/
#   rc-update add darkhttpd && rc-service darkhttpd start
document_root="/srv/ata-prov"
addr="192.0.2.5"          # bind to the LAN address the ATA can reach
port="80"
logdir="/var/log/$SVCNAME" # access.log shows whether the ATA fetched its file
run_as_user=darkhttpd
run_as_group=www-data
run_in_chroot=yes
darkhttpd_args=""
