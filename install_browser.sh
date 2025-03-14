#!/bin/bash

echo "Updating package lists..."
sudo apt update && sudo apt upgrade -y

echo "Installing Falkon browser (lightweight and fast)..."
sudo apt install -y falkon

echo "Installation complete! You can start Falkon by running: falkon"
