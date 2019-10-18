#!/bin/bash

### FUNCTIONS ###

error() { printf "Something went wrong, maybe it was the script, maybe it was you, who knows."; exit; }

confdrive() { \
	dialog --title "Confirm drive" --msgbox "Please confirm the drive you installed choose to intall arch on..." 8 26

	lsblk
	echo ""

	PS3='Choose a drive: '
	options=("/dev/sda/" "/dev/sdb/" "/dev/sdc/" "/dev/sdd/" "/dev/sd0")
	select opt in "${options[@]}"
	do
		case $opt in
			"/dev/sda/")
				drive="/dev/sda"
				break
			;;
			"/deb/sdb/")
				drive="/dev/sdb"
				break
			;;
			"/dev/sdc/")
				drive="/dev/sdc"
				break
			;;
			"/dev/sdd/")
				drive="/dev/sdd"
				break
			;;
			"/dev/sd0/")
				drive="/dev/sd0/"
				break
			;;
			*) echo "invalid option $REPLY";;
		esac
	done
}

locale() { \
	rc=$(dialog --title "Region/City" --inputbox "In order for some programs to work properly (discord, etc) you need to configure your region and city. The format should look like Region/City" 12 60)
	ln -sf /usr/share/zoneinfo/"$rc" /etc/localtime
	
	dialog --title "locale" --msgbox "In order for your system to work properly you are going to need to configure your locale. Uncomment (remove the #) which locale is yours. (If you live in america then uncomment '#en-US.UTF-8 UTF-8'" 10 40

	vim /etc/locale.gen
	locale-gen
}

grub() { \
	dialog --title "grub" --msgbox "When installing Arch, you need a boot manager to actually boot into your install. One of the most popular, and the one we are going to be installing is called grub." 10 40

	mkdir /boot/efi
	mount "$drive"1 /boot/efi
	grub-install --target=x86_64-efi --bootloader-id=grub-uefi --recheck
	mkdir /boot/grub/locale
	cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
	grub-mkconfig -o /boot/grub/grub.cfg

	dialog --title -grub "installation done" -msgbox "Grub has been successfuly installed" 7 15
}

getuserandpass() { \
	dialog --title "Creating a user" --msgbox "Next LPI is going to help you create your personal user, setup its password, and also set the root password" 9 30

	name=$(dialog --inputbox "First, please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit
	while ! echo "$name" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
		name=$(dialog --no-cancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	pass1=$(dialog --no-cancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;

	dialog --title "Setting root password" --msgbox "Last we need to set root password just incase anything goes wrong with your main account" 9 30

	rpass1=$(dialog --no-cancel --passwordbox "Enter a password for root." 10 60 3>&1 1>&2 2>&3 3>&1)
	rpass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$rpass1" = "$rpass2" ]; do
		unset pass2
		pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;
}

adduserandpass() { \
	dialog --infobox "Adding user \"$name\"..." 4 50
	useradd -m -g wheel "$name"
	echo "$name:$pass1" | chpasswd
	unset pass1 pass2 ;

	dialog --infobox "Setting root password..." 4 50
	echo "root:$rpass1" | chpasswd
	unset rpass1 rpass2 ;
}

sudoers() { \
	dialog --title "Edit user permissions" --msgbox " Lastly, we need to edit user permissions. Here you can allow your personal user to do whatever you want, or restrict it in anyway. For more infomation, check the arch wiki about the sudoers file. (NOTE: User is apart of group 'Wheel'" 10 50
	vim /etc/sudoers
}

wificonfig() { \
	dialog --title "Wifi Config" --msgbox "The last thing we need to do is setup NetworkManager. Network manager is used to manage networks, so just choose your network, connect, then exit and you'll be on your way!" 10 40

	systemctl enable NetworkManager
}

### THE ACTUAL SCRIPT ###

### this is how everything happens ###

# Confirm the $drive variable for installation of grub
confdrive || error "User Exited."

# Configure the locale
locale || error "User Exited."

# Install and configure grub
grub

# Make user
getuserandpass || error "User Exited."

# Add user and set root password
adduserandpass || error "Failed to add user and pass."

# Configure the sudoers file
sudoers || error "User Exited."

# Setup networkmanager
wificonfig || error "User Exited."
