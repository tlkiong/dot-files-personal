COMPUTER_NAME=$$(scutil --get HostName)
WORK_PATH=$(HOME)/Desktop/work-local

SSH_FILE_PATH=$(HOME)/.ssh/$(COMPUTER_NAME)
SSH_CONFIG_FILE_PATH=$(HOME)/.ssh/config

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
	@echo "Checking git configuration..."
	@if [ -n "$$(git config --global user.name)" ]; then \
		echo "Git user.name is already set to: $$(git config --global user.name)"; \
	else \
		git config --global user.name "Kiong"; \
		echo "Set git user.name to: Kiong"; \
	fi

	@if [ -n "$$(git config --global user.email)" ]; then \
		echo "Git user.email is already set to: $$(git config --global user.email)"; \
	else \
		git config --global user.email "kiong90@gmail.com"; \
		echo "Set git user.email to: kiong90@gmail.com"; \
	fi

	@if [ -z "$$(git config --global pager.log)" ]; then \
		git config --global pager.log false; \
		echo "Disabled git log pager"; \
	fi

	@if [ -z "$$(git config --global pull.rebase)" ]; then \
		git config --global pull.rebase true; \
		echo "Configured git pull to rebase by default"; \
	else \
		echo "Git pull.rebase is already set to: $$(git config --global pull.rebase)"; \
	fi

	@if [ -z "$$(git config --global alias.lg)" ]; then \
		git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"; \
		echo "Configured git lg alias"; \
	fi

	@echo
	@if [ ! -d "$(WORK_PATH)" ]; then \
		echo "Creating '$(WORK_PATH)' directory"; \
		mkdir -p "$(WORK_PATH)"; \
	else \
		echo "Directory '$(WORK_PATH)' already exists"; \
	fi

	@echo "Checking for existing GitHub SSH key..."
	@if [ -f "$(SSH_FILE_PATH)" ]; then\
		echo "SSH key already exists at $(SSH_FILE_PATH)";\
		echo "Public key for reference:";\
		cat $(SSH_FILE_PATH).pub;\
		echo;\
	else\
		echo "Generating new GitHub SSH key...";\
		ssh-keygen -t ed25519 -C "kiong90@gmail.com" -f $(SSH_FILE_PATH) -q -P "" || (echo "Failed to generate SSH key" && exit 1);\
		echo "New SSH key generated successfully at $(SSH_FILE_PATH)";\
		echo "Public key to add to GitHub:";\
		cat $(SSH_FILE_PATH).pub;\
		echo;\
	fi

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

	@echo "Checking repositories..."
	@for repo in $${GIT_REPOSITORIES}; do \
		if [ -d "$(WORK_PATH)/$$repo" ]; then \
			echo "  Repository '$$repo' already exists at $(WORK_PATH)/$$repo"; \
		else \
			echo "  Cloning $$repo..."; \
			if git clone "git@github-personal:tlkiong/$$repo.git" "$(WORK_PATH)/$$repo"; then \
				echo "    Successfully cloned $$repo"; \
			else \
				echo "    Failed to clone $$repo" >&2; \
				exit 1; \
			fi; \
		fi; \
	done

	@echo
	@echo "Setting up configuration files..."
	@if [ -d "$(WORK_PATH)/dot-files-personal" ]; then \
		echo "  Found dot-files-personal repository"; \
		\
		ln -s "$(WORK_PATH)/dot-files-personal/.zshrc" ~/.zshrc; \
		echo "  Created symlink for .zshrc"; \
		\
		ln -s "$(WORK_PATH)/dot-files-personal/.tool-versions" ~/.tool-versions; \
		echo "  Created symlink for .tool-versions"; \
		\
		echo "  =====> Configuration setup completed"; \
	else \
		echo "  Error: dot-files-personal repository not found at $(WORK_PATH)/dot-files-personal" >&2; \
		echo "  =====> You need dot-files-personal to proceed <=====" >&2; \
		exit 1; \
	fi

	@echo
	@echo "Checking oh-my-zsh installation..."
	@if [ ! -d ~/.oh-my-zsh ]; then \
		echo "  Installing oh-my-zsh..."; \
		if sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then \
			echo "  oh-my-zsh installed successfully"; \
		else \
			echo "  Failed to install oh-my-zsh" >&2; \
			exit 1; \
		fi; \
	else \
		echo "  oh-my-zsh is already installed"; \
	fi

	@echo
	@echo "Checking Homebrew installation..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "  Installing Homebrew..."; \
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "  Failed to install Homebrew" >&2; exit 1; }; \
		echo "  Homebrew installed successfully"; \
		eval "$(/opt/homebrew/bin/brew shellenv)"; \
	else \
		echo "  Homebrew is already installed"; \
		echo "  Updating Homebrew..."; \
		if ! brew update; then \
			echo "  Warning: Failed to update Homebrew" >&2; \
		fi; \
	fi

	@echo
	@echo "Setting up zsh plugins..."
	@if [ ! -d "$${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then \
		echo "  Installing zsh-autosuggestions..."; \
		if git clone https://github.com/zsh-users/zsh-autosuggestions "$${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"; then \
			echo "  zsh-autosuggestions installed successfully"; \
		else \
			echo "  Failed to install zsh-autosuggestions" >&2; \
			exit 1; \
		fi; \
	else \
		echo "  zsh-autosuggestions is already installed"; \
	fi

	@if [ ! -d "$${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then \
		echo "  Installing zsh-syntax-highlighting..."; \
		if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"; then \
			echo "  zsh-syntax-highlighting installed successfully"; \
		else \
			echo "  Failed to install zsh-syntax-highlighting" >&2; \
			exit 1; \
		fi; \
	else \
		echo "  zsh-syntax-highlighting is already installed"; \
	fi

	@echo
	@echo "Installing brew dependencies..."
	@for dep in $${BREW_DEPS}; do \
		if ! brew list "$$dep" >/dev/null 2>&1; then \
			echo "  Installing $$dep..."; \
			if ! brew install "$$dep"; then \
				echo "  Warning: Failed to install $$dep" >&2; \
			fi; \
		else \
			echo "  $$dep is already installed"; \
		fi; \
	done

	@echo
	@echo "Installing brew cask dependencies..."
	@for dep in $${BREW_CASK_DEPS}; do \
		if ! brew list --cask "$$dep" >/dev/null 2>&1; then \
			echo "  Installing $$dep..."; \
			if ! brew install --cask "$$dep"; then \
				echo "  Warning: Failed to install $$dep" >&2; \
			fi; \
		else \
			echo "  $$dep is already installed"; \
		fi; \
	done

	@echo
	@echo "Setting up asdf plugins..."
	@for plugin in $${ASDF_PLUGINS}; do \
		if ! asdf plugin-list | grep -q "^$$plugin$$"; then \
			echo "  Adding asdf plugin: $$plugin"; \
			if ! asdf plugin-add "$$plugin"; then \
				echo "  Warning: Failed to add asdf plugin: $$plugin" >&2; \
			fi; \
		else \
			echo "  asdf plugin '$$plugin' is already installed"; \
		fi; \
	done

	@echo
	@echo "Updating asdf plugins..."
	if ! asdf plugin-update --all; then \
		echo "  Warning: Failed to update some asdf plugins" >&2; \
	fi

	@echo
	@echo "Installing asdf tools..."
	if ! asdf install; then \
		echo "  Warning: Failed to install some asdf tools" >&2; \
	fi

	@echo
	@echo "Checking PostgreSQL installation..."
	if ! command -v psql >/dev/null 2>&1; then \
		echo "  Installing latest PostgreSQL..."; \
		if ! brew install postgresql; then \
			echo "  Failed to install PostgreSQL" >&2; \
			exit 1; \
		else \
			POSTGRES_VERSION=$$(brew list --versions postgresql | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1); \
			echo "  Successfully installed PostgreSQL $${POSTGRES_VERSION}"; \
		fi; \
	else \
		POSTGRES_VERSION=$$(psql --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1); \
		echo "  PostgreSQL $${POSTGRES_VERSION} is already installed"; \
	fi

	@echo
	@echo "Starting PostgreSQL service..."
	if ! brew services restart postgresql; then \
		echo "  Failed to start PostgreSQL service" >&2; \
		exit 1; \
	else \
		echo "  PostgreSQL service started successfully"; \
	fi

	@echo
	@echo "Setting zsh as default shell..."
	if [ "$$SHELL" != "$$(which zsh)" ]; then \
		if chsh -s "$$(which zsh)"; then \
			echo "  Default shell changed to zsh"; \
		else \
			echo "  Warning: Failed to change default shell to zsh" >&2; \
		fi; \
	else \
		echo "  zsh is already the default shell"; \
	fi

	source ~/.zshrc
	@echo
	@echo "=====> Setup completed successfully! <====="
