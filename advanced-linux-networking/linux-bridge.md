#

# Introduction

A linux bridge behaves like a network switch. It forwards packets based on mac address table and hence it is a layer 2 device.

# Challenge#1 (Create a basic layer 2 bridge or switch)

```
sudo -s
ip link add test-int-1 type dummy
ip link add test-int-2 type dummy
brctl addbr test-bridge
brctl addif test-bridge test-int-1 test-int-2
brctl show test-bridge
brctl showmacs test-bridge

ip link show

ip link set dev test-bridge up
ip link set dev test-int-1 up
ip link set dev test-int-2 up
```

# Challenge#2 (Layer 3 interface to bridge - SVI)

#### Default gateway and NAT for container

```

ip addr add 192.168.25.1/24 dev test-bridge

```

# Challenge3 (add veth interface to the bridge)

### Note: This is in default namespace. Same are using host networking with docker - docker run --name container --network=host

```
ip link add veth-int1 type veth peer name veth-int1-br
ip link add veth-int2 type veth peer name veth-int2-br

ip link set veth-int1-br master test-bridge
ip link set veth-int2-br master test-bridge

ip link set up veth-int1
ip link set up veth-int2
ip link set up veth-int1-br
ip link set up veth-int2-br



ip addr add 192.168.25.10/24 dev veth-int1
ip addr add 192.168.25.11/24 dev veth-int2

# validations
root@linux-host-1:/home/nehali# brctl show test-bridge
bridge name     bridge id               STP enabled     interfaces
test-bridge             8000.1601e3095901       no              test-int-1
                                                        test-int-2
                                                        veth-int1-br
                                                        veth-int2-br
```
