#  macOS dotfiles

A collection of configuration files for setting up and maintaining a personalized macOS development environment.

## Installation

```bash
cd $HOME
git clone --separate-git-dir=$HOME/.macdots.git https://github.com/sadiksaifi/macdots.git tmpdotfiles

rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
rm -rf tmpdotfiles

alias dots='/usr/bin/git --git-dir=$HOME/.macdots.git/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no
```

## About this setup
This repository uses the Git bare-repo method for managing dotfiles.
The actual repository lives in ~/.macdots.git, while your $HOME directory acts as the working tree.
This keeps your home folder clean and avoids the clutter of a visible .git directory.

If you want a detailed explanation of how this approach works (and why it’s great), check out the full guide on my blog: [Manage Dotfiles with Git Bare Repository](https://blog.sadiksaifi.dev/manage-dotfiles-with-git-bare-repository/)

## License

[GPL-3.0](LICENSE)
