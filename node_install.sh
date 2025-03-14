#!/bin/bash

echo "Updating package lists..."
sudo apt update && sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y curl

echo "Adding Node.js 20 repository..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

echo "Installing Node.js..."
sudo apt install -y nodejs

echo "Verifying installation..."
node -v
npm -v

echo "Node.js installation completed successfully!"
