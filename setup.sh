set -e

sudo apt install -y ca-certificates tmux git curl jq

bash -c "source _setup.sh && _install_zsh"
bash -c "source _setup.sh && _setup_keys"
bash -c "source _setup.sh && _setup_ssh"
bash -c "source _setup.sh && _setup_git"
bash -c "source _setup.sh && _install_vim"
bash -c "source _setup.sh && _install_vscode"
bash -c "source _setup.sh && _install_aws"
bash -c "source _setup.sh && _install_kube"
bash -c "source _setup.sh && _install_asdf"
bash -c "source _setup.sh && _setup_aliases"
