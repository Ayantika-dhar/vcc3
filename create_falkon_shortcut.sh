#!/bin/bash

echo "Creating Falkon desktop shortcut..."

# Ensure necessary directories exist
mkdir -p ~/.local/share/applications
mkdir -p ~/Desktop

# Define the shortcut file path
SHORTCUT_PATH="$HOME/.local/share/applications/falkon.desktop"

# Create the .desktop file
cat <<EOF > $SHORTCUT_PATH
[Desktop Entry]
Version=1.0
Type=Application
Name=Falkon Browser
Exec=falkon
Icon=falkon
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF

# Make the shortcut executable
chmod +x $SHORTCUT_PATH

echo "Shortcut created in Applications menu."

# Copy shortcut to Desktop
cp $SHORTCUT_PATH $HOME/Desktop/falkon.desktop
chmod +x $HOME/Desktop/falkon.desktop

echo "Falkon shortcut successfully created on Desktop!"
echo "If the icon doesn't appear, right-click on it and select 'Allow launching'."
