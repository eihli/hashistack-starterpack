NOMAD_VERSION="1.0.1"
CONSUL_VERSION="1.9.1"

sleep 30

# Wait for DigitalOcean to finish its setup
ps aux | grep '\bapt-get\b' > /dev/null
while [ $? -eq "0" ]
do
    sleep 1
    ps aux | grep '\bapt-get\b' > /dev/null
done

sleep 1

sudo apt-get update
sudo apt-get install -y unzip

# Docker (for driver)
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt-get update
sudo apt-get install -y docker-ce

# Java (for driver)
sudo apt-get install -y openjdk-11-jdk

# Consul
curl -L "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    -o consul.zip
unzip consul.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
rm -f consul.zip
sudo mkdir --parents /etc/consul.d
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo chown --recursive consul:consul /etc/consul.d/
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul/

# Nomad
curl -L "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"\
    -o nomad.zip
unzip nomad.zip
sudo chown root:root nomad
sudo mv nomad /usr/local/bin/
rm -f nomad.zip
sudo mkdir --parents /etc/nomad.d
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
sudo chown --recursive nomad:nomad /etc/nomad.d/
sudo mkdir --parents /opt/nomad
sudo chown --recursive nomad:nomad /opt/nomad

# Envoy
curl -L https://getenvoy.io/cli | sudo bash -s -- -b /usr/local/bin
getenvoy run standard:1.16.2 -- --version
sudo cp ~/.getenvoy/builds/standard/1.16.2/linux_glibc/bin/envoy /usr/local/bin/

# CNI plugins so Nomad can configure the network namespace for
# Consul Connect sidecar proxy.
curl -L -o cni-plugins.tgz \
    https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
echo 'net.bridge.bridge-nf-call-arp-tables = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1' | sudo tee -a /etc/sysctl.d/10-bridge-nf-call.conf
