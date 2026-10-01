#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/ksk0/mvs.git"
MARKER=".mvs-repo"

die()
{
    printf 'mvs: %s\n' "$*" >&2
    exit 1
}

backup_name()
{
    local path=$1
    local backup="${path}.ORG"
    local n=1

    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${path}.ORG.${n}"
        ((n++))
    done

    printf '%s\n' "$backup"
}

install_repo()
{
    local target="$HOME/.vim"
    local marker="$target/$MARKER"
    local tmp="$HOME/.vim.MVS.NEW"
    local backup

    # Already ours.
    if [[ -f "$marker" ]]; then
        return
    fi

    rm -rf -- "$tmp"

    printf 'Cloning mvs...\n'

    git clone --quiet "$REPO_URL" "$tmp" ||
        die "git clone failed"

    if [[ ! -f "$tmp/$MARKER" ]]; then
        rm -rf -- "$tmp"
        die "downloaded repository does not contain $MARKER"
    fi

    # Preserve an existing foreign ~/.vim.
    if [[ -e "$target" || -L "$target" ]]; then
        backup=$(backup_name "$target")

        printf 'Preserving existing %s as %s\n' "$target" "$backup"

        mv -- "$target" "$backup"
    fi

    mv -- "$tmp" "$target"
}

install_vimrc_link()
{
    local vimrc="$HOME/.vimrc"
    local target="$HOME/.vim/vimrc"
    local backup

    # Correct link already exists.
    if [[ -L "$vimrc" ]] &&
       [[ "$(readlink -f "$vimrc")" == "$(readlink -f "$target")" ]]; then
        return
    fi

    # Preserve anything unrelated.
    if [[ -e "$vimrc" || -L "$vimrc" ]]; then
        backup=$(backup_name "$vimrc")

        printf 'Preserving existing %s as %s\n' "$vimrc" "$backup"

        mv -- "$vimrc" "$backup"
    fi

    ln -s "$target" "$vimrc"
}

install_local()
{
    install_repo
    install_vimrc_link

    printf 'mvs installed locally.\n'
}

install_global()
{
    [[ $EUID -eq 0 ]] ||
        die "global installation must be run as root"

    command -v git >/dev/null ||
        die "git is required"

    {
        cat <<EOF
" Installed by mvs.
" Its only purpose is per-user first-run installation.

let s:mvs_repo_url = '${REPO_URL}'
EOF

        cat <<'EOF'

function! s:mvs_backup_name(path) abort
    let l:backup = a:path . '.ORG'
    let l:n = 1

    while getftype(l:backup) !=# ''
        let l:backup = a:path . '.ORG.' . l:n
        let l:n += 1
    endwhile

    return l:backup
endfunction


function! s:mvs_install() abort
    let l:vimdir = expand('~/.vim')
    let l:marker = l:vimdir . '/.mvs-repo'
    let l:tmp = expand('~/.vim.MVS.NEW')
    let l:vimrc = expand('~/.vimrc')
    let l:vimrc_target = l:vimdir . '/vimrc'

    "
    " Install ~/.vim if it is not already ours.
    "
    if !filereadable(l:marker)

        if getftype(l:tmp) !=# ''
            if getftype(l:tmp) ==# 'dir'
                call delete(l:tmp, 'rf')
            else
                call delete(l:tmp)
            endif
        endif

        call system(
                    \ 'git clone --quiet ' .
                    \ shellescape(s:mvs_repo_url) . ' ' .
                    \ shellescape(l:tmp)
                    \ )

        if v:shell_error
            echohl ErrorMsg
            echom 'mvs: git clone failed'
            echohl None
            return
        endif

        if !filereadable(l:tmp . '/.mvs-repo')
            call delete(l:tmp, 'rf')

            echohl ErrorMsg
            echom 'mvs: downloaded repository is not an mvs repository'
            echohl None
            return
        endif

        "
        " Clone succeeded. Only now preserve the old ~/.vim.
        "
        if getftype(l:vimdir) !=# ''
            let l:backup = s:mvs_backup_name(l:vimdir)

            if rename(l:vimdir, l:backup) != 0
                call delete(l:tmp, 'rf')

                echohl ErrorMsg
                echom 'mvs: cannot preserve existing ~/.vim'
                echohl None
                return
            endif
        endif

        if rename(l:tmp, l:vimdir) != 0
            echohl ErrorMsg
            echom 'mvs: cannot install ~/.vim'
            echohl None
            return
        endif

    endif

    "
    " Ensure ~/.vimrc points to our immutable entry point.
    "
    if getftype(l:vimrc) ==# 'link' &&
                \ resolve(l:vimrc) ==# resolve(l:vimrc_target)
        return
    endif

    if getftype(l:vimrc) !=# ''
        let l:backup = s:mvs_backup_name(l:vimrc)

        if rename(l:vimrc, l:backup) != 0
            echohl ErrorMsg
            echom 'mvs: cannot preserve existing ~/.vimrc'
            echohl None
            return
        endif
    endif

    call system(
                \ 'ln -s ' .
                \ shellescape(l:vimrc_target) . ' ' .
                \ shellescape(l:vimrc)
                \ )

    if v:shell_error
        echohl ErrorMsg
        echom 'mvs: cannot create ~/.vimrc link'
        echohl None
    endif
endfunction


call s:mvs_install()
EOF
    } >/etc/vim/vimrc.local

    printf 'mvs global bootstrap installed in /etc/vim/vimrc.local\n'
}

command -v git >/dev/null ||
    die "git is required"

cat >/dev/tty <<'EOF'

mvs installation type:

  1) LOCAL
     Install mvs for the current user.

  2) GLOBAL
     Install /etc/vim/vimrc.local.
     Each user will get mvs automatically on first Vim start.

EOF

printf 'Choose [1/2]: ' >/dev/tty
IFS= read -r choice </dev/tty

case "$choice" in
    1|local|LOCAL)
        install_local
        ;;

    2|global|GLOBAL)
        install_global
        ;;

    *)
        die "invalid selection"
        ;;
esac
