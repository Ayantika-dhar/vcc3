#!/bin/bash

echo "Updating package lists..."
sudo apt update && sudo apt upgrade -y

echo "Installing XFCE (Xubuntu Desktop)..."
sudo apt install -y xubuntu-core

echo "Installation complete! Reboot your system to apply changes."
echo "Run 'sudo reboot' and then 'startxfce4' after login."

