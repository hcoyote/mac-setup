#!/bin/bash

sudo -v

# install rosetta if needed
if [[ "$(arch)" =~ "arm64" ]] ; then
    echo Installing Rosetta just in case
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

#Install homebrew
PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
export PATH

if [ ! -x /opt/homebrew/bin/brew ] ; then
    echo "installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
#hcoyote-personal
"

brew_apps=(

    bdw-gc
    c-ares
    ca-certificates
    cairo
    docker-machine
    fontconfig
    fortune
    freetype
    gettext
    gh
    giflib
    github-keygen
    glib
    gmp
    gnutls
    graphite2
    guile
    harfbuzz
    helm
    icu4c
    jpeg-turbo
    kubernetes-cli
    libevent
    libgcrypt
    libgpg-error
    libidn2
    libmaxminddb
    libnet
    libnghttp2
    libpng
    libsmi
    libssh
    libtasn1
    libtiff
    libtool
    libunistring
    libx11
    libxau
    libxcb
    libxdmcp
    libxext
    libxrender
    little-cms2
    lua
    lz4
    lzo
    m4
    minikube
    nettle
    openjdk
    openssl@1.1
    p11-kit
    packer
    pcre2
    pixman
    pkg-config
    readline
    ripgrep
    tcptraceroute
    terraform
    unbound
    xorgproto
    xz
    zstd

    )

echo "Adding bash to /etc/shells"
grep -q /usr/local/bin/bash /etc/shells || sudo sed -i -e '$ a\
/usr/local/bin/bash
' /etc/shells

echo "Installing brew taps"
for tap in $brew_taps; do
    sudo -v
    echo "    $tap"
    brew tap $tap
done



echo "Installing homebrew apps ${brew_apps[@]}"
for app in ${brew_apps[@]}; do
    echo checking ${app}
    brew list ${app} >/dev/null 2>&1 || brew install ${app}
done

cask_apps=(
    1password
    4k-youtube-to-mp3
    alfred
    apache-directory-studio
    bartender
    caffeine
    controlplane
    cyberduck
    docker
    dropbox
    elgato-camera-hub
    elgato-control-center
    evernote
    font-clear-sans
    font-montserrat
    font-roboto
    freemind
    github
    goland
    google-chrome
    google-drive
    intellij-idea
    istat-menus
    iterm2
    karabiner-elements
    keybase
    keycastr
    kitematic
    little-snitch
    macfuse
    macx-youtube-downloader
    notion
    obs
    pineapple
    pycharm
    qlprettypatch
    rstudio
    screenflick
    shottr
    vagrant
    vlc
    wireshark
    xquartz

)
echo "Installing ${cask_apps[@]}"
for app in ${cask_apps[@]}; do
    sudo -v
    echo checking ${app}
    brew list --cask ${app} >/dev/null 2>&1 || brew install --cask ${app}
done

echo "Installing caskroom taps"
cask_taps="
fonts
versions
drivers
"
for tap in $cask_taps; do
    echo "    $tap"
    brew tap homebrew/cask-$tap
done

fonts=(
  font-clear-sans
  font-roboto
)

# install fonts
echo "installing fonts..."
brew install ${fonts[@]}

# add some completion stuff.
if [ ! -f /opt/homebrew/etc/bash_completion.d/docker ] ; then
    curl -L https://raw.githubusercontent.com/docker/docker/master/contrib/completion/bash/docker -o /opt/homebrew/etc/bash_completion.d/docker
fi


# alfred workflows.
# http://www.alfredforum.com/topic/1710-another-nest-thermostat-workflow/
# https://github.com/jason0x43/alfred-hue/releases
# http://www.packal.org/workflow/packal-updater
# http://www.packal.org/workflow/homebrew-and-cask-alfred
# http://www.packal.org/workflow/github-command-bar
# http://www.packal.org/workflow/chrome-bookmarks

# control plane workflows
# 

if [ ! -d $HOME/.oh-my-zsh ] ; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo oh-my-zsh already loaded
fi
