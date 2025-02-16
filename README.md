#  macOS dotfiles

This is a collection of dotfiles for macOS setup. It includes configurations for:

- [Git](.gitconfig)
- [Vim](.vimrc)
- [Neovim](https://github.com/sadiksaifi/nvim.git)
- [Zsh](.config/zsh/.zshrc)
- [Ghostty](.config/ghostty/config)
- [Aerospace](.config/aerospace/aerospace.toml)
- [Starship](.config/starship.toml)

## Installation

```bash
cd $HOME
git clone --separate-git-dir=$HOME/.macdots.git https://github.com/sadiksaifi/macdots.git tmpdotfiles

rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
rm -rf tmpdotfiles

alias dots='/usr/bin/git --git-dir=$HOME/.macdots.git/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no
```

## License

[GPL-3.0](LICENSE)
