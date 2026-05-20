# Teamchart

Teamchart visualizes each mons type weaknesses in one table gives you counts of total weak and total resist for every type. Paste in your team in [showdown export format](https://github.com/smogon/pokemon-showdown/blob/master/sim/TEAMS.md#export-format).

## Config

CSS is using [DaisyUI](https://daisyui.com). Download the .mjs source files and place into `src/vendor`

```sh
mkdir -p src/vendor
curl -sLo src/vendor/daisyui.mjs https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.mjs
curl -sLo src/vendor/daisyui-theme.mjs https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.mjs
```

## Development

```sh
gleam run -m lustre/dev start   # Local Development
gleam test  # Run the tests
```
