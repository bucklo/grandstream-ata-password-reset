# DHCP option 66 for one Grandstream ATA on MikroTik RouterOS 7.
# Replace the URL, IP, MAC and server name with your own.

# The value is a RouterOS expression: the single quotes inside make it a string.
/ip dhcp-server option
add code=66 name=ata-prov value="'http://192.0.2.5'"

# Attach it to the ATA's lease only (also pins its IP).
/ip dhcp-server lease
add address=192.0.2.17 mac-address=00:0B:82:AA:BB:CC server=lan \
    dhcp-option=ata-prov comment="Grandstream ATA provisioning"

# If the ATA already has a dynamic lease, convert it instead:
#   /ip dhcp-server lease make-static [find mac-address=00:0B:82:AA:BB:CC]
#   /ip dhcp-server lease set [find mac-address=00:0B:82:AA:BB:CC] dhcp-option=ata-prov
