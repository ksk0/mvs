# MVS — My Vim Setup

```sh
wget -qO- https://raw.githubusercontent.com/ksk0/mvs/main/.install.sh | bash
```

MVS is a small, Git-managed Vim setup intended mainly for sysadmin and general editing work.

It provides:

- local or global installation
- automatic per-user setup in global mode
- automatic updates from Git
- automatic `vim-plug` installation
- automatic installation of missing plugins
- a clean directory for user-specific Vim configuration

## Installation

The installer asks whether you want:

- **LOCAL** — install MVS for the current user
- **GLOBAL** — install a system bootstrap so each user gets MVS automatically on first Vim start

Existing Vim configuration is preserved before MVS installs its own files.

## User configuration

Put local/user-specific Vim configuration in:

```text
~/.vim/vimrc.d/
```

Files are loaded in filename order, so numeric prefixes can be used if desired:

```text
~/.vim/vimrc.d/
├── 10-options.vim
├── 20-mappings.vim
└── 90-local.vim
```

User configuration is intentionally loaded after plugins as well, so local settings can override plugin defaults.

## Plugins

Plugin declarations are stored in:

```text
~/.vim/plugins
```

For example:

```vim
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
```

Missing plugins are installed automatically on the next Vim startup.

## Scope

MVS deliberately keeps Vim lightweight.

The focus is on:

- navigation
- text editing
- Git
- fuzzy finding
- file operations
- sysadmin work

Development-heavy IDE functionality is intentionally left out of the base setup.
