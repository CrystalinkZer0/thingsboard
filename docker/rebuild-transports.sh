#!/bin/bash

# Script to rebuild ThingsBoard transport services with updated Kafka routing config
# This script compiles the updated code and refreshes the transport containers

echo "==============================================="
echo "ThingsBoard Transport Rebuild Script"
echo "==============================================="
echo ""

cd ~/thingsboard-docker || exit 1

# Step 1: Backup current source
echo "[1/5] Creating backup of current source code..."
if [ -d "thingsboard.backup" ]; then
    rm -rf thingsboard.backup
fi
cp -r thingsboard thingsboard.backup
echo "✓ Backup created"
echo ""

# Step 2: Pull latest code from git
echo "[2/5] Pulling latest code from git..."
cd thingsboard || exit 1
git pull origin getmarket-iot
cd ~/ thingsboard-docker || exit 1
echo "✓ Code updated"
echo ""

# Step 3: Compile queue module
echo "[3/5] Compiling queue module with updated configuration..."
cd thingsboard/
mvn -pl 'common/queue' -DskipTests -Dlicense.skip=true -am install 2>&1 | tail -20
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✓ Queue module compiled successfully"
else
    echo "✗ Queue compilation failed"
    exit 1
fi
echo ""

# Step 4: Copy updated .env files to docker directory
echo "[4/5] Ensuring updated .env files are in place..."
cp -v docker/tb-mqtt-transport.env ~/thingsboard-docker/ 2>/dev/null || true
cp -v docker/tb-http-transport.env ~/thingsboard-docker/ 2>/dev/null || true
cp -v docker/tb-coap-transport.env ~/thingsboard-docker/ 2>/dev/null || true
echo "✓ Configuration files updated"
echo ""

# Step 5: Rebuild transport Docker images
echo "[5/5] Rebuilding transport Docker images..."
cd ~/thingsboard-docker || exit 1

echo "Stopping current transports..."
docker compose down --remove-orphans tb-mqtt-transport1 tb-mqtt-transport2 tb-http-transport1 tb-http-transport2 tb-coap-transport 2>/dev/null || true
sleep 5

echo "Building new transport images..."
docker compose build tb-mqtt-transport1 tb-mqtt-transport2 tb-http-transport1 tb-http-transport2 tb-coap-transport

echo "Starting updated transports..."
docker compose up -d tb-mqtt-transport1 tb-mqtt-transport2 tb-http-transport1 tb-http-transport2 tb-coap-transport

sleep 10
echo ""
echo "==============================================="
echo "Rebuild Complete!"
echo "==============================================="
echo ""
echo "Verifying configuration..."
docker exec thingsboard-ce-tb-mqtt-transport1-1 env | grep "QUEUE_ROUTING" || echo "Configuration NOT loaded - may need manual intervention"
echo ""
echo "Transport startup logs (tail):"
docker logs --tail 5 thingsboard-ce-tb-mqtt-transport1-1 2>&1 | head -3
echo ""
echo "Note: Services may take 3-5 minutes to fully initialize"
echo "Monitor with: docker logs -f thingsboard-ce-tb-mqtt-transport1-1"
