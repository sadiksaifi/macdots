jrun() {
  local script manager

  [[ -f package.json ]] || {
    echo "jrun: package.json not found"
    return 1
  }

  script=$(
    jq -r '.scripts // {} | keys[]' package.json |
      fzf \
        --prompt='jrun > ' \
        --preview="jq -r '.scripts[\"{}\"]' package.json | bat --language=sh --style=plain --color=always" \
        --preview-window='down:40%:wrap'
  )

  [[ -n "$script" ]] || return

  manager=$(jq -r '.packageManager // empty' package.json)
  manager="${manager%%@*}"

  if [[ -z "$manager" ]]; then
    if [[ -f bun.lock || -f bun.lockb ]]; then
      manager="bun"
    elif [[ -f pnpm-lock.yaml ]]; then
      manager="pnpm"
    elif [[ -f yarn.lock ]]; then
      manager="yarn"
    else
      manager="npm"
    fi
  fi

  case "$manager" in
    bun|pnpm|yarn|npm)
      "$manager" run "$script"
      ;;
    *)
      echo "jrun: unsupported package manager: $manager"
      return 1
      ;;
  esac
}
