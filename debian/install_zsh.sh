#!/bin/bash

# Update package list and install zsh
sudo apt update
sudo apt install -y zsh

# Install oh-my-zsh
sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Change oh-my-zsh theme to candy
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="candy"/' ~/.zshrc

# Uncomment the second line of .zshrc to add the path and remove any space after #
sed -i '2s/^#\s*//' ~/.zshrc

# Add alias ll='ls -lahF' to .zshrc
echo "alias ll='ls -lahF'" >> ~/.zshrc

# change default terminal
chsh -s $(which zsh)
zsh

# Reload zsh configuration
source ~/.zshrc

echo "Post-installation script completed successfully!"
