#!/usr/bin/env bash

# Xray Subnet Mimicry - Routing Setup Script
# This script configures the Linux kernel and routing tables to allow
# Xray to intercept and route traffic for the 10.0.0.0/8 subnet.

set -euo pipefail

echo "Applying routing configuration..."

# 1. Enable IP Forwarding
# This is required for the server to act as a router/gateway.
sudo sysctl -w net.ipv4.ip_forward=1

# 2. IP Rule for mark 0x1 -> table 100
# Any packet marked with 0x1 (by our iptables/TPROXY rules) 
# will be forced to use routing table 100.
if sudo ip rule show | grep -q 'fwmark 0x1 lookup 100'; then
    echo "IP rule for mark 0x1 already exists."
else
    sudo ip rule add fwmark 0x1 lookup 100 priority 100
    echo "IP rule added for mark 0x1."
fi

# 3. Local route in table 100
# In table 100, we route everything to the local loopback.
# This "tricks" the kernel into handing the packet to our TPROXY inbound 
# listening on 127.0.0.1:12345.
if sudo ip route show table 100 2>/dev/null | grep -q 'local default dev lo'; then
    echo "Local route in table 100 already exists."
else
    sudo ip route add local 0.0.0.0/0 dev lo table 100
    echo "Local route added to table 100."
fi

echo "Routing configuration applied successfully."
exit 0
