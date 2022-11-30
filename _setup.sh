#!/bin/bash

# https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
__get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

_install_zsh() {
  sudo apt install -y zsh
  chsh -s $(which zsh)
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
  wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
  wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
  wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
  sudo mv MesloLGS\ NF\ *.ttf /usr/share/fonts/

  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  sed -i 's/^ZSH_THEME=.*$/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  sed -i 's/^plugins=.*$/plugins=(git aws zsh-syntax-highlighting)/g' ~/.zshrc
}

_setup_keys() {
  [[ ! -f ~/.ssh/id_rsa ]] && ssh-keygen -t rsa -b 4096
  [[ ! $(gpg2 -k | grep -w uid) ]] && gpg2 --full-generate-key
  GPG_KEY_ID=$(gpg2 --list-secret-keys --keyid-format=long | grep -m 1 sec | sed -n 's/^.*[a-z0-9]*\/\([A-Z0-9]*\).*/\1/p')
}

_setup_git() {
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

  GPG_KEY_ID=$(gpg2 --list-secret-keys --keyid-format=long | grep -m 1 sec | sed -n 's/^.*[a-z0-9]*\/\([A-Z0-9]*\).*/\1/p')
  read -p 'Git email:' GIT_EMAIL

  git config --global user.name "Wibisana Bramawidya"
  git config --global user.email ${GIT_EMAIL}
  git config --global user.signingkey ${GPG_KEY_ID}
  git config --global commit.gpgsign true

  gpg2 --armor --export ${GPG_KEY_ID}

  [ -f ~/.zshrc ] && echo >> ~/.zshrc
  [ -f ~/.zshrc ] && echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
}

_install_vim() {
  sudo apt install -y vim

  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  mv vim/.vimrc ${HOME}/.vimrc

  env SHELL=(which sh) vim +BundleInstall! +BundleClean +qall

  cat>>~/.zshrc <<EOF

function updatevim
    set -lx SHELL (which sh)
    vim +BundleInstall! +BundleClean +qall
end
EOF
}

_install_vscode() {
  wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O vscode.deb
  sudo dpkg -i vscode.deb

  code --install-extension eamodio.gitlens
  code --install-extension GitHub.vscode-pull-request-github
  code --install-extension ms-vscode-remote.remote-ssh
  code --install-extension golang.Go
  code --install-extension ms-python.python
  code --install-extension ms-toolsai.jupyter
  code --install-extension HashiCorp.terraform
  code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
  code --install-extension ms-azuretools.vscode-docker
  code --install-extension ms-vscode-remote.remote-containers
  code --install-extension ms-vscode.makefile-tools
  code --install-extension twxs.cmake
  code --install-extension ms-vscode-remote.remote-ssh-edit

  rm vscode.deb
}

_install_aws() {
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install

  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
  sudo dpkg -i session-manager-plugin.deb

  rm -rf awscliv2.zip aws
  rm session-manager-plugin.deb
}

_install_kube() {
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

  sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
  sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
  sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

  mkdir -p ~/.oh-my-zsh/completions
  chmod -R 755 ~/.oh-my-zsh/completions
  ln -s /opt/kubectx/completion/_kubectx.zsh ~/.oh-my-zsh/completions/_kubectx.zsh
  ln -s /opt/kubectx/completion/_kubens.zsh ~/.oh-my-zsh/completions/_kubens.zsh

  K9S_VERSION=$(__get_latest_release "derailed/k9s")
  wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_x86_64.tar.gz
  mkdir -p k9s
  tar -xvf k9s_Linux_x86_64.tar.gz -C k9s
  sudo mv k9s/k9s /usr/local/bin

  rm -rf kubectl k9s k9s_Linux_x86_64.tar.gz
}

_install_asdf() {
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
  . $HOME/.asdf/asdf.sh
  cat >>~/.zshrc <<EOF

# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit
EOF

  asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
  asdf plugin-add packer https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add vault https://github.com/asdf-community/asdf-hashicorp.git
}

_setup_aliases() {
  echo >> ~/.zshrc
  echo "alias sudo='sudo '" >> ~/.zshrc
  echo "alias v='vim'" >> ~/.zshrc
  echo "alias gcmm='git commit -m'" >> ~/.zshrc

  mv aliases/.kubectl_aliases && echo "source ~/.kubectl_aliases" >> ~/.zshrc
  mv aliases/.terraform_aliases && echo "source ~/.terraform_aliases" >> ~/.zshrc
  mv aliases/.terragrunt_aliases && echo "source ~/.terragrunt_aliases" >> ~/.zshrc
}
