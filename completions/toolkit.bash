# shellcheck disable=SC2207 # COMPREPLY=($(compgen ...)) is the usual way to write a completion
# bash completion for toolkit: source it, or let install.sh put it in your bash-completion folder.

_toolkit() {
  local cur="${COMP_WORDS[COMP_CWORD]}" prev="${COMP_WORDS[COMP_CWORD - 1]}" root sheets
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=($(compgen -W "ssh status ftp backup certs docs test version help" -- "$cur"))
    return 0
  fi
  case "${COMP_WORDS[1]}" in
    ftp)
      [ "$COMP_CWORD" -eq 2 ] && COMPREPLY=($(compgen -W "create list password quota delete help" -- "$cur"))
      ;;
    backup)
      [ "$COMP_CWORD" -eq 2 ] && COMPREPLY=($(compgen -W "list" -- "$cur") $(compgen -f -- "$cur"))
      ;;
    certs)
      COMPREPLY=($(compgen -f -- "$cur"))
      ;;
    docs)
      root="$(cd "$(dirname "$(readlink "$(command -v toolkit)" 2> /dev/null || command -v toolkit)")" 2> /dev/null && pwd)"
      sheets=$(ls "$root"/_Documentation/cheatsheet_*.md 2> /dev/null | sed 's|.*/cheatsheet_||;s|\.md$||')
      [ "$COMP_CWORD" -eq 2 ] && COMPREPLY=($(compgen -W "$sheets" -- "$cur"))
      ;;
  esac
  return 0
}
complete -F _toolkit toolkit
