# AGENTS.md

This is a **user configuration directory** for the Yazi terminal file manager (`~/.config/yazi/`).

## What is this

- User config for Yazi FM (not a development project)
- Contains plugins, themes, keybindings, and settings
- Managed via `package.toml` - plugins are external dependencies fetched from GitHub

## Key files

- `yazi.toml` - main config (manager ratio, preview, plugins, tasks)
- `keymap.toml` - key bindings
- `theme.toml` - color theme
- `init.lua` - plugin initialization and setup
- `package.toml` - plugin/flavor dependencies

## No development workflow

- No build, test, lint, or typecheck commands
- Just edit config files directly
- Run `yazi` to test changes