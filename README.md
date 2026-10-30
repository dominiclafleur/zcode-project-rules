# zcode-project-rules

A standalone ZCode plugin marketplace with one plugin, [`project-rules`](./external_plugins/project-rules/README.md). It loads `CLAUDE.md` and path-scoped `.zcode/rules/*.md` files into ZCode sessions.

```shell
zcode plugins marketplace add https://github.com/dominiclafleur/zcode-project-rules
zcode plugins install project-rules@project-rules-marketplace
zcode plugins enable project-rules@project-rules-marketplace
```

## Layout

The directory follows the [zai-org/zcode-plugins](https://github.com/zai-org/zcode-plugins) layout, so the plugin can be dropped into that repository unchanged.

```text
marketplace.json                 standalone marketplace (lists project-rules)
marketplace-entry.json           entry to append to zcode-plugins/marketplace.json
external_plugins/project-rules/  the plugin (manifest, hooks, READMEs, test)
scripts/check-marketplace.sh     runs the upstream checks against this layout
```

## Checks

```shell
sh scripts/check-marketplace.sh ../zcode-plugins
```

This runs the plugin self-test and then the unmodified upstream `validate.py` and `build_dist.py` against this layout. It then validates a scratch copy of `zcode-plugins` with the plugin and `marketplace-entry.json` merged in. The scratch copy and `dist/` are removed afterwards.

## Submitting upstream

1. Copy `external_plugins/project-rules/` into `zcode-plugins/external_plugins/`.
2. Append the object in `marketplace-entry.json` to `plugins` in `zcode-plugins/marketplace.json`.
3. Run `python3 scripts/validate.py` and `python3 scripts/build_dist.py` there, and declare the PR as a **Standard plugin**.
