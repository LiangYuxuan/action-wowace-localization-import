# action-wowace-localization-import
GitHub action to find and import localization strings to WoWAce.

## Usage

```yml
name: import

on: push

jobs:
  import:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1

    - uses: LiangYuxuan/action-wowace-localization-import@master
      env:
        CF_API_KEY: ${{ secrets.CF_API_KEY }}
```

## Arguments

* args
  (optional) Arguments to `upload.lua`, defaults to ''

### Arguments to `upload.lua`

Now support `-p` only, override the project id found in TOC file.

`-p curse-id      Set the project id used on CurseForge for importing localization.`

## Environment Variables

* `CF_API_KEY`  - a [CurseForge API token](https://wow.curseforge.com/account/api-tokens),
  required for the CurseForge API to upload localization.

## License
The Unlicense
