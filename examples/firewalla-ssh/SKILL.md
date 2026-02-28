---
name: firewalla-ssh
description: >-
  SSH into the Firewalla Gold Pro router and run diagnostic or configuration
  commands on it. Provides access to the UniFi controller (running in Docker
  on the Firewalla) and its MongoDB database for network config queries.
  Use when connecting to Firewalla, running network diagnostics on the router,
  accessing UniFi controller settings, querying UniFi MongoDB, checking IGMP
  snooping, VLAN config, AP settings, or multicast configuration.
---

<!-- EXAMPLE SKILL: This is a redacted version of a real infrastructure skill.
     It shows how to encode SSH access, device management, and database queries
     into a Claude Code skill. Replace placeholders with your own values. -->

# Firewalla SSH Access

## Connection

```bash
ssh -i <SSH_KEY_PATH> pi@<ROUTER_IP>
```

**If key doesn't exist**, try password auth:
```bash
ssh pi@<ROUTER_IP>
```

If both fail, the key needs to be set up. Ask the user to run:
```bash
ssh-copy-id -i <SSH_KEY_PATH> pi@<ROUTER_IP>
# or generate a new key first:
ssh-keygen -t ed25519 -f <SSH_KEY_PATH>
```

Use `-o StrictHostKeyChecking=no -o ConnectTimeout=10` flags when scripting.

## Running Commands on Firewalla

Most useful commands require `sudo`. Firewalla runs Raspbian; standard Linux tools are available (`ip`, `iptables`, `tcpdump`, `dig`, `bridge`, etc.).

```bash
# One-liner pattern
ssh -i <SSH_KEY_PATH> pi@<ROUTER_IP> "sudo <command>"

# Interactive session
ssh -i <SSH_KEY_PATH> pi@<ROUTER_IP>
pi@firewalla:~ $ sudo -s
root@firewalla:~ # <commands>
```

## UniFi Controller Access

UniFi Network runs inside a Docker container called `unifi`. Access path:

```bash
# Step 1: SSH to Firewalla
ssh -i <SSH_KEY_PATH> pi@<ROUTER_IP>

# Step 2: Elevate
sudo -s

# Step 3: Enter UniFi container
sudo docker exec -it unifi /bin/bash

# Step 4: Open MongoDB (live config)
mongo --host 127.0.0.1 --port <MONGO_PORT> ace

# Or runtime stats (AP channels, associations, etc.)
mongo --host 127.0.0.1 --port <MONGO_PORT> ace_stat
```

**What does NOT work:**
- `ssh` directly into the `unifi` container
- `docker` commands without `sudo` on Firewalla

## MongoDB Quick Reference (`ace` database)

```js
// List all networks/VLANs
db.networkconf.find({}, {name:1, vlan:1, purpose:1, igmp_snooping:1}).pretty()

// Check IGMP snooping and multicast settings on a network
db.networkconf.find({name: "Default"}).pretty()

// List all APs and their config
db.device.find({type: "uap"}, {name:1, ip:1, model:1, radio_table:1}).pretty()

// Check switch config (US-8)
db.device.find({type: "usw"}).pretty()

// List all site settings
db.setting.find().pretty()

// Check RSTP / spanning tree config
db.networkconf.find({}, {name:1, dhcp_relay_enabled:1, lte_enabled:1}).pretty()
```

## MongoDB Quick Reference (`ace_stat` database)

```js
// AP runtime stats: channels, associations, TX power
db.stat_device_last.find({}, {name:1, "radio_table_stats":1}).pretty()

// Client associations
db.stat_client_latest.find().pretty()
```

## Useful Firewalla Shell Commands

```bash
# Check IGMP snooping state on bridge
cat /sys/devices/virtual/net/br0/bridge/multicast_snooping

# List Docker containers
sudo docker ps

# Firewalla flow log (Redis)
redis-cli keys "flow:*" | head -20

# DNS test through Firewalla
dig @127.0.0.1 example.com

# Packet capture on LAN interface (eth0 or similar)
sudo tcpdump -i eth0 -n 'igmp' -c 20
```

## Network Environment Reference

- **Firewalla IP:** <ROUTER_IP>
- **LAN subnet:** <LAN_SUBNET>/24
- **SSH user:** `pi`
- **SSH key:** `<SSH_KEY_PATH>`
- **UniFi container:** `unifi` (Docker)
- **MongoDB:** 127.0.0.1:<MONGO_PORT> (inside container)
- **Databases:** `ace` (config), `ace_stat` (runtime stats)
