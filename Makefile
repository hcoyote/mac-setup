
update: update-zsh update-bin 

update-zsh:
	rsync -avp zshrc ${HOME}/.zshrc
	rsync -avp oh-my-zsh/* ${HOME}/.oh-my-zsh/custom

update-bin:
	rsync -avp bin/ ${HOME}/bin/
