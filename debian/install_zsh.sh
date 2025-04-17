#!/bin/bash

# Update package list and install zsh
sudo apt update
sudo apt install -y zsh

# Install oh-my-zsh
sh -c "\$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

# Change oh-my-zsh theme to candy
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="candy"/' ~/.zshrc

# Uncomment the second line of .zshrc to add the path and remove any space after #
sed -i '2s/^#\s*//' ~/.zshrc

# Add alias ll='ls -lahF' to .zshrc
echo "alias ll='ls -lahF'" >> ~/.zshrc

# Reload zsh configuration
source ~/.zshrc

echo "Post-installation script completed successfully!"
