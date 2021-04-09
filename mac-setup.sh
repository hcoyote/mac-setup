#!/bin/bash

sudo -v

#Install homebrew

if [ ! -x /usr/local/bin/brew ] ; then
    echo "installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Disabling system boot sound"
sudo nvram -d SystemAudioVolume

echo "Disabling Spotlight indexing for any volume that gets mounted and has not yet been indexed before"
sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

echo "Expanding the save panel by default"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

echo ""
echo "Automatically quit printer app once the print jobs complete"
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

echo "Disable Photos.app from starting everytime a device is plugged in"
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

echo "Increasing sound quality for Bluetooth headphones/headsets"
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

echo "Turn off keyboard illumination when computer is not used for 5 minutes"
defaults write com.apple.BezelServices kDimTime -int 300

echo "Requiring password immediately after sleep or screen saver begins"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

echo "Make Chrome use the right print dialog"
defaults write com.google.Chrome DisablePrintPreview -bool true

if [ ! -d $HOME/Pictures/Screenshots ]; then
    mkdir -p $HOME/Pictures/Screenshots
fi
echo "Setting location to $HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

echo "Setting screenshot format to PNG"
defaults write com.apple.screencapture type -string "png"

echo "Show icons for hard drives, servers, and removable media on the desktop"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

echo "Show all filename extensions in Finder by default"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "Display full POSIX path as Finder window title"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true


brew_taps="
hcoyote-personal
"

brew_apps=(
    ack
    bash
    ctags
    git
    gh
    go
    hub
    jq
    caskroom/cask/brew-cask
    mtr
    freerdp
    tmux
    homebrew/x11/freerdp
    myrepos
    nmap
    pdsh
    shellcheck
    aws-shell
    awscli
    packer
    terraform
    thefuck
    azure-cli
    maven
    mas
    pv
    zmwangx/npm-noob/noob
    rtm-cli
    watch
    xmlstarlet
    )

echo "Adding bash to /etc/shells"
grep -q /usr/local/bin/bash /etc/shells || sudo sed -i -e '$ a\
/usr/local/bin/bash
' /etc/shells

echo "Installing brew taps"
for tap in $brew_taps; do
    echo "    $tap"
    brew tap $tap
done



echo "Installing homebrew apps ${brew_apps[@]}"
brew install ${brew_apps[@]}

cask_apps=(
4k-youtube-to-mp3           cubicsdr                    font-montserrat             istat-menus                 macx-youtube-downloader     screenflick
alfred                      cyberduck                   font-roboto                 iterm2                      osxfuse                     slack
apache-directory-studio     dockertoolbox               freemind                    java                        packer                      terraform
atom                        dropbox                     gitbook                     jira-client                 pineapple                   vagrant
bartender                   evernote                    github-desktop              keybase                     pycharm                     virtualbox
boot2docker                 flux                        goland                      keycastr                    qlprettypatch               vlc
caffeine                    font-clear-sans             google-drive                kitematic                   r-app                       webex-nbr-player
chirp-daily                 font-droid-serif            gqrx                        kk7ds-python-runtime        real-vnc                    wireshark
controlplane                font-m-plus                 intellij-idea               little-snitch               rstudio                     xquartz
karabiner-elements
)
echo "Installing ${cask_apps[@]}"
brew cask install ${cask_apps[@]}

echo "Installing caskroom taps"
cask_taps="
fonts
versions
"
for tap in $cask_taps; do
    echo "    $tap"
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

# install atom packages
echo "Installing atom packages"

atom_packages=(
    vim-mode
)
for apm in $atom_packages ; do
    echo "  $apm"
    apm install $apm
done

# add some completion stuff.
curl -L https://raw.githubusercontent.com/docker/docker/master/contrib/completion/bash/docker -o /usr/local/etc/bash_completion.d/docker


# alfred workflows.
# http://www.alfredforum.com/topic/1710-another-nest-thermostat-workflow/
# https://github.com/jason0x43/alfred-hue/releases
# http://www.packal.org/workflow/packal-updater
# http://www.packal.org/workflow/homebrew-and-cask-alfred
# http://www.packal.org/workflow/github-command-bar
# http://www.packal.org/workflow/chrome-bookmarks

# control plane workflows
# 
