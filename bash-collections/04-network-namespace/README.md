# Linux Network Namespace Manager

A Bash script for managing Linux network namespaces - isolated network stacks for secure testing and networking.

## Features

✅ Create and delete network namespaces
✅ Configure loopback interfaces
✅ Run commands in isolated network stacks
✅ Connect namespaces to physical networks
✅ Test network applications without affecting main system

## What are Network Namespaces?

Network namespaces are a Linux kernel feature that provides isolated network stacks. Each namespace has its own:
- Network interfaces
- IP routing tables
- Firewall rules
- Socket connections

This allows safe testing of network applications, containers, and VPNs without affecting the main system.

## Included Scripts

### bash.sh: Network Namespace Management

Basic management commands for network namespaces:

```bash
# Create a network namespace
ip netns add my-namespace

# Bring up loopback interface
ip netns exec my-namespace ip link set dev lo up

# Run command in namespace
ip netns exec my-namespace ip addr show
```

## Requirements

1. **Linux kernel 3.0+**: Network namespaces are built into modern Linux kernels
2. **iproute2**: The `ip` command suite

## Installation

No installation required - network namespace tools are built into the Linux kernel.

Just make the script executable:
```bash
chmod +x bash.sh
```

## Usage Examples

### Create and Configure a Namespace
```bash
# Create new namespace
sudo ip netns add test-namespace

# Bring up loopback interface
sudo ip netns exec test-namespace ip link set dev lo up

# Verify
 sudo ip netns exec test-namespace ip addr show
```

### Run Applications in Isolation
```bash
# Run a web server in the namespace
 sudo ip netns exec test-namespace python3 -m http.server 8000

# Access it from main namespace
 sudo ip netns exec test-namespace curl http://localhost:8000
```

### Connect Namespace to Physical Network
```bash
# Create veth pair
sudo ip link add veth0 type veth peer name veth1

# Attach one end to namespace
sudo ip link set veth1 netns test-namespace

# Configure IPs
sudo ip addr add 192.168.1.1/24 dev veth0
sudo ip netns exec test-namespace ip addr add 192.168.1.2/24 dev veth1

# Bring up interfaces
sudo ip link set dev veth0 up
sudo ip netns exec test-namespace ip link set dev veth1 up

# Enable routing
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 ! -d 192.168.1.0/24 -j MASQUERADE
```

## Real-World Case Study: Network Application Testing

### The Challenge
A network engineer needed to test a new firewall application without affecting their production network:

- Needed to test firewall rules in isolation
- Didn't want to risk breaking production network settings
- Needed to simulate different network environments

### The Solution
They used network namespaces to create a complete test environment:

```bash
# Create test environment
./bash.sh create test-env

# Run firewall in namespace
./bash.sh exec test-env ./firewall-app

# Test connectivity
./bash.sh exec test-env ping 8.8.8.8

# Cleanup when done
./bash.sh delete test-env
```

### Results
- ✅ Complete isolation from production network
- ✅ Safe testing of firewall rules
- ✅ Simulated complex network topologies
- ✅ No impact on main system

## Common Use Cases

1. **Application Testing**: Test network apps without affecting production
2. **Security Testing**: Test malware network behavior in isolation
3. **Network Development**: Develop and debug network protocols
4. **VPN Testing**: Test VPN connections safely
5. **Container Networking**: Understand container network models

## Cleanup

To delete a network namespace:
```bash
sudo ip netns delete my-namespace
```

## Troubleshooting

### "Cannot find command"
Ensure you're running commands with sudo:
```bash
sudo ip netns list
```

### "Operation not supported"
Ensure your Linux kernel supports network namespaces (modern kernels do by default)

### Network unreachable
Don't forget to bring up the loopback interface!
```bash
ip netns exec my-namespace ip link set dev lo up
```
