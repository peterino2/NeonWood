#!/bin/bash
cd "$(dirname "$0")"
pwd
cd ../sdks/vulkan_sdk/1.3.268.0/
unzip aarch64.zip
VULKAN_SDK_SETUP_PATH=$(pwd)/aarch64
echo "I want to add the following variables to your .bashrc"
line1="export VULKAN_SDK=$VULKAN_SDK_SETUP_PATH"
line2="export PATH=\$PATH:$VULKAN_SDK_SETUP_PATH/bin"
echo $line1
echo #line2
while true; do
	read -p "is this ok?" yn
	case $yn in
		[Yy]* ) echo $line1 >> ~/.bashrc; echo $line2 >> ~/.bashrc; break;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "done! vulkan sdk unpacked for rpi4, run source ~/.bashrc to update variables."
