COMPUTER_NAME=$$(scutil --get HostName)
WORK_PATH=~/Desktop/work-local

SSH_FILE_PATH=~/.ssh/$(COMPUTER_NAME)
SSH_CONFIG_FILE_PATH=~/.ssh/config

PYTHON_CONFIG_FILE_PATH=./setup.py

GIT_REPOSITORIES=dot-files-personal

BREW_DEPS=wifi-password coreutils git asdf zsh-syntax-highlighting postgresql@16 libpq commitizen
BREW_CASK_DEPS=iterm2 visual-studio-code github docker vlc maccy zoom postman
ASDF_PLUGINS=ruby nodejs pnpm


define newline


endef

define python_config_file_content
import socket
from pathlib import Path

computerName = socket.gethostname()

sshFilePath = f"~/.ssh/{computerName}"
sshConfigPath = f"{Path.home()}/.ssh/config"

fileContents = f"""Host *
  AddKeysToAgent yes
  UseKeychain yes

Host github-personal
  HostName github.com
  User git
  IdentityFile {sshFilePath}
  IdentitiesOnly yes
"""

with open(sshConfigPath, mode="w+") as f:
  f.write(fileContents)

print("Successfully created ~/.ssh/config file")
endef

setup:
	@echo
	@echo "Set scutil HostName"
	sudo scutil --set HostName `hostname`

	@echo
	@echo "Setting up git config"
	git config --global user.name "Kiong"
	git config --global user.email "kiong90@gmail.com"

	@echo
	@echo "Creating '$(WORK_PATH)' directory"
	@mkdir -p $(WORK_PATH)

	@echo "Generating github SSH key"
	@if [ ! -f $(SSH_FILE_PATH) ]; then\
		ssh-keygen -t ed25519 -C "kiong90@gmail.com" -f $(SSH_FILE_PATH) -q -P "";\
	fi
	@echo
	@cat $(SSH_FILE_PATH).pub
	@echo

	@if [ ! -f $(SSH_CONFIG_FILE_PATH) ]; then\
		echo "Creating ~/.ssh/config file";\
		echo '$(subst $(newline),\n,${python_config_file_content})' > $(PYTHON_CONFIG_FILE_PATH);\
		python3 ./$(PYTHON_CONFIG_FILE_PATH);\
		rm ./setup.py;\
		echo;\
	fi

	@eval "$(ssh-agent -s)"

	@read -p 'Have you upload the SSH key above to github? [Y]: '
	@echo

	@echo "Cloning tlkiong repositories ..."
	@for repo in ${GIT_REPOSITORIES}; do \
		if [ -d $(WORK_PATH)/$$repo ]; then \
			echo " -> $$repo is cloned at $(WORK_PATH)/$$repo";\
		else \
			echo " -> Cloning $$repo ...";\
			git clone git@github-personal:tlkiong/$$repo.git $(WORK_PATH)/$$repo;\
		fi \
	done

	@echo
	@if [ -d $(WORK_PATH)/dot-files-personal ]; then \
		echo "Setting up configs";\
		cp $(WORK_PATH)/dot-files-personal/.zshrc ~/.zshrc  ;\
		cp $(WORK_PATH)/dot-files-personal/.tool-versions ~/.tool-versions  ;\
		echo " =====> Config setup done";\
	else \
		echo;\
		echo " =====> You need dot-files-personal to proceed <====="; exit 1;\
	fi

	@if [ ! -d ~/.oh-my-zsh ]; then \
		echo "Installing oh-my-zsh";\
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";\
	fi

	@echo
	@if [ $$(which -s brew) != '' ]; then \
		echo "Installing homebrew";\
		zsh -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" -y; \
	else \
		echo "Updating homebrew";\
		brew update;\
	fi

	@echo
	@if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then \
		echo "Installing zsh-autosuggestions";\
		git clone https://github.com/zsh-users/zsh-autosuggestions $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions;\
	fi
	@echo "Installed zsh-autosuggestions"

	@if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then \
		echo "Installing zsh-syntax-highlighting";\
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting;\
	fi
	@echo "Installed zsh-syntax-highlighting"

	@echo
	@echo "Installing brew dependencies"
	@for dep in ${BREW_DEPS}; do if !(brew list $$dep >/dev/null); then brew install $$dep; else echo " =====> $$dep installed"; fi done

	@echo
	@echo "Installing brew cask dependencies"
	@for dep in ${BREW_CASK_DEPS}; do if !(brew list --cask $$dep >/dev/null); then brew install --cask $$dep; else echo " =====> $$dep installed"; fi done

	@echo
	@echo "Installing asdf plugins"
	@for plugin in ${ASDF_PLUGINS}; do if [[ $$(asdf plugin-list | grep "$$plugin") == "" ]]; then asdf plugin-add $$plugin || true; else echo " =====> $$plugin installed"; fi done

	@echo
	@echo "Updating asdf plugins ..."
	@asdf plugin-update --all

	@echo
	@echo "Running asdf install"
	@asdf install

	@if !(brew list postgresql@16 >/dev/null); then \
		echo; \
		echo "Installing postgresql@16"; \
		brew list postgresql@16; \
	fi

	@echo
	@echo "Starting postgresql@16 service using brew"
	brew services restart postgresql@16

	@zsh
	chsh -s $$(which zsh)

	source ~/.zshrc
	echo " =====> Setup done"
