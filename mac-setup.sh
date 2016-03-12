#!/bin/sh

#Install homebrew

if [ ! -x /usr/local/bin/brew ] ; then 
	echo "installing homebrew"
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# disable system boot sound
sudo nvram -d SystemAudioVolume


brew_apps=(
	ack
	git
	go
	hub
	caskroom/cask/brew-cask 
	tmux
	homebrew/x11/freerdp
	nmap
	)

echo "Installing homebrew apps ${brew_apps[@]}"
brew install ${brew_apps[@]}

cask_apps=(
	alfred 
	boot2docker
	caffeine 
	iterm2 
	evernote 
	flux
	cyberduck 
	little-snitch 
	gitbook
	github-desktop
	sublime-text3
	virtualbox
	vagrant
	slack
	screenflick
	dropbox
	wireshark
	qlprettypatch
	vlc
)
echo "Installing ${cask_apps[@]}"
brew cask install ${cask_apps[@]}

echo "Installing caskroom taps"
cask_taps="
fonts
versions
"
for tap in $cask_taps; do
	echo "	$tap"
	brew tap caskroom/$tap
done

fonts=(
  font-m-plus
  font-clear-sans
  font-roboto
)

# install fonts
echo "installing fonts..."
brew cask install ${fonts[@]}

# alfred workflows.
# http://www.alfredforum.com/topic/1710-another-nest-thermostat-workflow/
# https://github.com/jason0x43/alfred-hue/releases
# http://www.packal.org/workflow/packal-updater
