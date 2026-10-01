# MVS Project Handoff

This file is intended as a technical handoff for future development of **MVS (My Vim Setup)**. It preserves the current architecture, design decisions, reasoning, and known edge cases well enough to continue development without reconstructing the discussion from scratch.

## 1. Project purpose

MVS is not primarily a Vim configuration repository. It is a **deployment, bootstrap, update, and plugin-management mechanism** for a classic Vim environment.

The intended split is:

- **MVS**: installation, bootstrap, repository updates, vim-plug setup, plugin lifecycle, config-loading lifecycle.
- **Personal/common Vim configuration**: increasingly expected to move into a dedicated Vim plugin such as `my-vim-config`.
- **User-specific/local configuration**: kept in `~/.vim/vimrc.d/` and deliberately loaded with final precedence.
- **Neovim**: used separately for development-heavy workflows. MVS/Vim should remain lightweight and suitable for sysadmin/general editing.

The core philosophy is modularity, small stable boot files, and one self-maintaining `~/.vim` tree.

---

## 2. Repository name and identity

The Git repository is called:

```text
mvs
```

meaning roughly **My Vim Setup**.

The repository itself is cloned directly into:

```text
~/.vim
```

There is no extra wrapper directory such as `~/.vim/mvs`.

MVS ownership of an existing `~/.vim` tree is identified by a tracked marker file:

```text
~/.vim/.mvs-repo
```

The marker is intentionally separate from implementation files such as `.bootstrap.vim`, so repository identity does not depend on the current bootstrap implementation.

Expected logic:

```text
~/.vim absent
    -> install

~/.vim/.mvs-repo exists
    -> this is an MVS-managed tree

~/.vim exists but marker is absent
    -> treat as foreign configuration
    -> preserve it before installing MVS
```

Prefer preserving foreign files/directories as `.ORG`, `.ORG.1`, etc.

When replacing an existing foreign `~/.vim`, clone first into a temporary directory such as:

```text
~/.vim.MVS.NEW
```

Verify that cloning succeeded and that `.mvs-repo` is present before moving the old tree aside.

---

## 3. Installation modes

The installer must explicitly ask:

```text
LOCAL or GLOBAL?
```

Do **not** infer installation type from whether the installer runs as root.

Running as root does not necessarily mean the user wants global installation.

The installer is intended to be started with a one-line command such as:

```sh
wget -qO- https://raw.githubusercontent.com/<USER>/mvs/main/.install.sh | bash
```

Because stdin contains the downloaded script, interactive input in `.install.sh` should be read from `/dev/tty`.

### LOCAL installation

Local installation immediately provisions the current user's environment:

```text
clone mvs -> ~/.vim
preserve foreign ~/.vim if needed
preserve foreign ~/.vimrc if needed
create:
    ~/.vimrc -> ~/.vim/vimrc
```

The installer performs the initial clone itself.

### GLOBAL installation

Global installation should **not** populate the current user's `~/.vim`.

Instead, `.install.sh` installs only:

```text
/etc/vim/vimrc.local
```

The contents of `/etc/vim/vimrc.local` should be generated directly from a heredoc inside `.install.sh`.

Reason: `.install.sh` should be self-contained and should not have to download an additional template from the repository merely to install the global bootstrap hook.

The global bootstrap exists so that **every user gets the same MVS setup automatically on first Vim use**.

On a user's first Vim start, `/etc/vim/vimrc.local` should:

1. detect whether `~/.vim/.mvs-repo` exists;
2. if not, clone MVS into a temporary location;
3. preserve a foreign `~/.vim` if one exists;
4. move the new MVS tree into `~/.vim`;
5. preserve an unrelated `~/.vimrc` if one exists;
6. create:

```text
~/.vimrc -> ~/.vim/vimrc
```

After that first per-user bootstrap, the user's `~/.vim` manages its own lifecycle.

This is the key distinction:

```text
GLOBAL installation:
    installs a system-wide per-user bootstrap trigger

LOCAL installation:
    directly creates the current user's MVS environment
```

After initial creation, the resulting user-side layout should be identical in both modes.

---

## 4. `~/.vimrc`

The preferred model is always:

```text
~/.vimrc -> ~/.vim/vimrc
```

This is intentional.

The rationale is that if a user later edits `~/.vimrc`, they are actually editing the canonical MVS entry file rather than accidentally creating a competing startup path.

Existing unrelated `~/.vimrc` should be preserved before creating the symlink.

Earlier ideas involving a managed bootstrap stub in `~/.vimrc` were abandoned.

---

## 5. Stable startup chain

The desired startup chain is fixed and easy to follow:

```text
~/.vimrc
    ↓
~/.vim/vimrc
    ↓
~/.vim/.bootstrap.vim
    ↓
~/.vim/.init.vim
    ↓
MVS/internal configuration
    ↓
user configuration
```

The chain should remain the same even when configuration is re-sourced.

Do not turn `vimrc` into a traffic controller that conditionally skips `.bootstrap.vim` or `.init.vim`.

Instead, each stage should inspect shared state and decide internally which of its tasks need to run.

This makes the control flow obvious to a future reader:

```text
vimrc -> bootstrap -> init
```

every time.

---

## 6. `vimrc`

`~/.vim/vimrc` should remain extremely small and effectively immutable.

Its job is only to enter the MVS chain:

```vim
execute 'source ' . fnameescape(expand('~/.vim/.bootstrap.vim'))
```

A symlink from `vimrc` to `.bootstrap.vim` was considered, but rejected because a real tiny file is clearer for future inspection.

---

## 7. `.bootstrap.vim`

`.bootstrap.vim` should also remain very small and stable.

Its responsibilities are:

1. on the first setup pass of the current Vim process, check/update the MVS Git repository;
2. always hand control to the current `.init.vim`.

The bootstrap should not contain general configuration work.

### Repository update policy

The update mechanism can use Git directly, e.g.:

```text
git -C ~/.vim fetch
compare HEAD with @{upstream}
git -C ~/.vim merge --ff-only @{upstream}
```

Avoid separate DNS-connectivity tests.

A successful DNS lookup does not prove GitHub/HTTPS is usable, and Git may be configured through a proxy. Simply attempt the relevant Git operation and handle failure.

The repository update should happen before `.init.vim` is sourced so that newly downloaded `.init.vim` and configuration files can take effect in the same Vim invocation.

### Stable bootstrap concern

Git may replace `.bootstrap.vim` while Vim is executing it.

A safe pattern is to define the bootstrap work in a function before the Git update and then call that function. Once parsed, the current function body is already in memory, so the current invocation can finish even if the file on disk changes.

The general intention remains: `.bootstrap.vim` should change rarely.

---

## 8. Global process state: `g:mvs_is_setup`

The current preferred lifecycle flag is:

```vim
g:mvs_is_setup
```

This represents:

> the MVS setup phase has completed successfully in this Vim process.

This is preferred over multiple implementation-detail flags such as:

```vim
g:mvs_bootstrap_done
g:mvs_vimplug_checked
```

because both `.bootstrap.vim` and `.init.vim` are fundamentally asking the same lifecycle question:

```text
Has the initial MVS setup already completed?
```

The flag should be set **at the end of `.init.vim`**, not before.

That way, if setup aborts halfway through, a later re-source can retry instead of falsely believing setup succeeded.

Example semantics:

```vim
if !exists('g:mvs_is_setup')
    " perform first-pass-only work
endif

" perform work which is intentionally re-runnable

let g:mvs_is_setup = 1
```

---

## 9. `.init.vim`

`.init.vim` owns MVS setup mechanics.

One-time tasks should preferably be organized into small functions, with each one checking:

```vim
if exists('g:mvs_is_setup')
    return
endif
```

Top-level `.init.vim` should read like orchestration:

```text
call one-time setup functions
source MVS/internal config
prepare late VimEnter work
set g:mvs_is_setup at the end
```

Functions are preferred for distinct tasks because they keep the file readable as a sequence of named operations.

Do not wrap absolutely everything in functions; trivial orchestration and the final assignment of `g:mvs_is_setup` can remain at top level.

---

## 10. vim-plug bootstrap

MVS uses:

```text
junegunn/vim-plug
```

If missing, `.init.vim` should create:

```text
~/.vim/autoload
```

and download:

```text
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

into:

```text
~/.vim/autoload/plug.vim
```

Using `wget` is acceptable and preferred for simplicity in this sysadmin-oriented setup.

Example:

```vim
let s:autoload = expand('~/.vim/autoload')
let s:plugvim  = s:autoload . '/plug.vim'

if !isdirectory(s:autoload)
    call mkdir(s:autoload, 'p')
endif

if !filereadable(s:plugvim)
    call system(
                \ 'wget -qO ' . shellescape(s:plugvim) . ' ' .
                \ shellescape('https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
                \ )
endif
```

This vim-plug bootstrap should be first-pass-only and should not repeat merely because the configuration is re-sourced later.

---

## 11. Plugin declaration file

Plugin declarations should be kept separately in:

```text
~/.vim/plugins
```

The file contains only `Plug` declarations, for example:

```vim
Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sleuth'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'wellle/targets.vim'
Plug 'tpope/vim-eunuch'
Plug 'vimoxide/vim-tabline'
```

MVS itself provides:

```vim
call plug#begin(expand('~/.vim/plugged'))

execute 'source ' . fnameescape(expand('~/.vim/plugins'))

call plug#end()
```

Keep `plugins` as valid Vimscript rather than inventing a custom parser, so normal vim-plug syntax and options remain available.

---

## 12. Plugin set and philosophy

Current core/likely plugins:

```text
preservim/nerdtree
tpope/vim-surround
tpope/vim-repeat
tpope/vim-commentary
tpope/vim-fugitive
tpope/vim-sleuth
junegunn/fzf
junegunn/fzf.vim
vimoxide/vim-tabline
```

Likely/possible additions:

```text
tpope/vim-eunuch
wellle/targets.vim
moll/vim-bbye
```

Explicitly excluded for now:

```text
tpope/vim-unimpaired
editorconfig/editorconfig-vim
```

Also avoid making the base setup into an IDE: no large statusline framework, start screen, multiple-cursor framework, LSP/IDE stack, etc.

The intended Vim use case is sysadmin/general work.

---

## 13. Automatic plugin installation

Missing configured plugins should be detected using vim-plug's:

```vim
g:plugs
```

rather than checking whether `~/.vim/plugged` is empty.

Preferred logic:

```vim
for l:plugin in values(g:plugs)
    if !isdirectory(l:plugin.dir)
        PlugInstall --sync
        return
    endif
endfor
```

This means adding a new `Plug '...'` line automatically installs the missing plugin on the next Vim startup.

The update function should live under Vim's autoload mechanism, e.g.:

```text
autoload/mvs/plugins.vim
```

with:

```vim
function! mvs#plugins#update() abort
    ...
endfunction
```

---

## 14. Vim autoload naming rule

Vim maps `#` in autoload function names to runtime paths.

Examples:

```text
autoload/mvs.vim
```

defines:

```vim
mvs#reload()
```

while:

```text
autoload/mvs/plugins.vim
```

defines functions such as:

```vim
mvs#plugins#update()
```

and:

```text
autoload/mvs/config.vim
```

defines:

```vim
mvs#config#load()
```

Vim resolves this automatically from `runtimepath`; autoload files normally do not need to be sourced manually.

---

## 15. Reloading configuration after plugin installation

When missing plugins are installed with:

```vim
PlugInstall --sync
```

the Vim configuration should be re-sourced so the newly installed plugins can participate immediately.

The earlier reload concept was:

```vim
function! mvs#reload() abort
    if filereadable('/etc/vim/vimrc')
        source /etc/vim/vimrc
    endif

    if filereadable(expand('~/.vimrc'))
        execute 'source ' . fnameescape(expand('~/.vimrc'))
    elseif filereadable(expand('~/.vim/vimrc'))
        execute 'source ' . fnameescape(expand('~/.vim/vimrc'))
    endif
endfunction
```

The important lifecycle property is that this reload follows the same normal chain:

```text
/etc/vim/vimrc
    ↓
~/.vimrc
    ↓
vimrc
    ↓
.bootstrap.vim
    ↓
.init.vim
```

but `g:mvs_is_setup` causes first-pass-only work inside bootstrap/init to be skipped.

This preserves one obvious chain instead of inventing a separate reload path.

---

## 16. Setup autocommand group

Late setup currently uses one shared augroup:

```vim
augroup mvs_setup
    autocmd!
    autocmd VimEnter * call mvs#plugins#update()
    autocmd VimEnter * call mvs#config#load()
augroup END
```

The order is intentional.

Vim executes matching autocommands in definition order, so:

```text
mvs#plugins#update()
    ↓
possibly install plugins
    ↓
possibly reload configuration
    ↓
return
    ↓
mvs#config#load()
```

Thus user configuration is loaded only after plugin installation/reload has completed.

Using an augroup with `autocmd!` prevents duplicate hooks when configuration is re-sourced.

---

## 17. User configuration directory

The current decision is:

```text
~/.vim/vimrc.d/
```

is the **user configuration directory**.

This is the clean public customization area.

During MVS development, MVS-owned/internal RC files should live separately in:

```text
~/.vim/.vimrc.d/
```

The hidden directory makes it obvious that these are framework/project files rather than normal user customization.

The user-facing directory can contain files such as:

```text
~/.vim/vimrc.d/
├── 10-options.vim
├── 20-mappings.vim
├── 30-colors.vim
└── 90-local.vim
```

Files should be sourced in sorted filename order.

---

## 18. Why user configuration is loaded twice

A significant timing issue was discovered.

When user configuration was loaded only from `VimEnter`, the first file opened by Vim often had:

```vim
:set filetype?
```

showing an empty filetype.

The same configuration worked when called directly from `.init.vim`, and subsequent buffers behaved correctly.

Running:

```vim
filetype detect
```

after loading the config fixed the first-buffer symptom, but this was judged not bulletproof enough.

Reason: `VimEnter` is late. By then, the initial buffer may already have passed events such as:

```text
BufRead
BufReadPost
BufWinEnter
FileType-related detection stages
```

`filetype detect` repairs the specific filetype problem but does not replay every missed startup event.

Therefore the preferred design is to load user config twice.

### Early pass

During `.init.vim`:

```text
mvs#config#load()
```

This lets the user config register autocommands and participate in normal initial-buffer startup.

### Late pass

Again at `VimEnter`:

```text
mvs#plugins#update()
mvs#config#load()
```

This gives user configuration final precedence over plugins and plugin defaults.

This two-pass behavior is intentional, not merely a workaround.

User RC files therefore should be re-source-safe.

Typical expectations:

```vim
augroup user_group
    autocmd!
    ...
augroup END
```

Use `function!` for replaceable functions, mappings that overwrite themselves naturally, and generally idempotent configuration.

A useful guard during re-source after Vim has already entered is:

```vim
v:vim_did_enter
```

but the exact final orchestration may still evolve.

---

## 19. Configuration precedence goal

The precedence requirement is:

```text
MVS/internal config
    ↓
plugins/common config
    ↓
user config wins
```

This was one reason to keep a dedicated `vimrc.d` mechanism rather than move entirely to Vim's `after/` tree.

The native `after/` mechanism was considered, but preserving a clean and explicit:

```text
~/.vim/vimrc.d/
```

user customization model is currently preferred.

---

## 20. Possible move of personal/common config into a plugin

A future direction is to move most personal Vim customization out of MVS and into a separate plugin, e.g.:

```text
my-vim-config
```

That plugin could contain:

```text
plugin/
autoload/
ftplugin/
syntax/
after/
...
```

MVS would then remain primarily the deployment/update framework.

This is attractive because plugin packaging is Vim's native modular mechanism.

The unresolved requirement was preserving user overrides after plugin load. The current two-pass `vimrc.d` strategy provides that precedence cleanly:

```text
common config plugin
    ↓
plugins
    ↓
late user vimrc.d pass
```

So `my-vim-config` remains a likely future direction.

---

## 21. Internal vs user files: current conceptual layout

Current intended layout is roughly:

```text
~/.vim/
├── .git/
├── .mvs-repo
├── .install.sh
├── .bootstrap.vim
├── .init.vim
├── vimrc
├── plugins
│
├── autoload/
│   ├── plug.vim
│   └── mvs/
│       ├── plugins.vim
│       └── config.vim
│
├── .vimrc.d/          # MVS/internal config during development
├── vimrc.d/           # user config
├── plugged/           # installed plugins
│
├── plugin/
├── ftplugin/
├── syntax/
└── ...
```

The exact tracked/untracked status of some runtime directories may still evolve.

---

## 22. `.netrwhist`

Vim's built-in `netrw` creates:

```text
~/.vim/.netrwhist
```

This stores netrw directory/history information and is runtime state, not configuration.

It should not be tracked.

Either ignore it:

```gitignore
/.netrwhist
```

or disable netrw history with:

```vim
let g:netrw_dirhistmax = 0
```

Do not disable netrw entirely merely because NERDTree is installed; netrw also provides useful remote-file functionality.

---

## 23. Small Vim details already discovered

Avoid:

```vim
glob(expand('~/.vim/plugged/*'))
```

because `expand()` also expands the wildcard.

Prefer:

```vim
glob('~/.vim/plugged/*')
```

or:

```vim
glob(expand('~/.vim/plugged/') . '*')
```

Also, `$MYVIMRC` is not suitable as the architectural anchor because:

- it can be empty when no user vimrc exists;
- sourcing it would not reproduce the intended global `/etc/vim/vimrc` processing;
- MVS deliberately uses an explicit boot chain instead.

---

## 24. README philosophy

`README.md` is intentionally user-facing and minimal.

It should contain:

- installation command at the very top;
- short explanation of MVS;
- LOCAL vs GLOBAL installation;
- where user config belongs;
- where plugin declarations belong;
- only enough information for someone to try/use the project.

This handoff file is the opposite: detailed enough to resume development later without reconstructing design history.

---

## 25. Core invariants to preserve

1. `~/.vim` itself is the Git repository.
2. `~/.vimrc` is a symlink to `~/.vim/vimrc`.
3. LOCAL and GLOBAL differ only in how the per-user tree is initially created.
4. GLOBAL installation modifies `/etc/vim/vimrc.local`; it does not directly populate user homes.
5. `/etc/vim/vimrc.local` exists only to provision each user's `~/.vim` automatically.
6. Once `~/.vim` exists, it manages its own updates.
7. `vimrc` is tiny and stable.
8. `.bootstrap.vim` is tiny and stable.
9. Startup always follows `vimrc -> .bootstrap.vim -> .init.vim`.
10. `g:mvs_is_setup` expresses whether the initial MVS setup phase has completed in this Vim process.
11. `.init.vim` owns framework/setup mechanics.
12. `~/.vim/plugins` is declarative plugin configuration.
13. Missing plugins are installed automatically using `g:plugs`.
14. Plugin maintenance runs before final user config at `VimEnter`.
15. `~/.vim/vimrc.d` is the user customization directory.
16. User config is loaded early for startup participation and late for precedence.
17. User RC files are expected to be safely re-sourceable.
18. MVS should remain a deployment/update framework rather than absorb all personal Vim customization.
19. Heavy development tooling belongs outside this classic Vim setup, likely in Neovim.
20. Prefer native Vim mechanisms and simple shell/Git behavior over custom complexity where possible.

---

## 26. Current open areas

The following areas may still need refinement:

- exact contents and final structure of `.init.vim`;
- exact Git update error handling in `.bootstrap.vim`;
- whether Git checks should be throttled instead of occurring on every fresh Vim process;
- final implementation of `mvs#reload()`;
- exact handling of errors during `PlugInstall --sync`;
- whether `moll/vim-bbye` belongs in the default plugin set;
- eventual migration of personal/shared configuration into `my-vim-config`;
- exact tracked/untracked policy for `.vimrc.d`, `vimrc.d`, and runtime-generated files;
- cleanup of temporary/backup directories after successful installation;
- optional non-interactive installer arguments such as `--local` and `--global`.

---

## 27. Mental model

The shortest useful mental model for MVS is:

```text
SYSTEM/LOCAL INSTALLER
        ↓
create/provision ~/.vim
        ↓
~/.vimrc -> ~/.vim/vimrc
        ↓
vimrc
        ↓
.bootstrap.vim
        ↓
update MVS repo when needed
        ↓
.init.vim
        ↓
ensure vim-plug / register setup
        ↓
load internal config
        ↓
load user config early
        ↓
VimEnter
        ↓
install missing plugins if needed
        ↓
reload if needed
        ↓
load user config late
```

The project should remain understandable from that chain.
