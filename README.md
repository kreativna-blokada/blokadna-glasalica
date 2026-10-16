# Build scripts

The project has two separate scripts — one for dialogues, one for exporting:

| Script                  | Location               | Purpose                                                 |
| ----------------------- | ---------------------- | ------------------------------------------------------- |
| `scramble_dialogues.py` | `code/!project/build/` | packs the voter dialogues into scrambled `.bin` content |
| `export.sh`             | `code/prod/`           | headless Godot export for Android, iOS and web          |

## Running the build scripts

Scramble dialogues, from `code/`:

```bash
cd '!project/build'
./scramble_dialogues.py
```

Export, from `code/` — **important: close the Godot editor first**:

```bash
cd prod
./export.sh            # release: Android AAB + iOS Xcode project + web
./export.sh android    # release Android AAB only
./export.sh ios        # release iOS Xcode project only
./export.sh web        # release web build only
./export.sh debug      # debug Android AAB (no release keystore needed)
```

```bash
cd ../../../release/build/web
zip -r -FS ../blokadna-glasalica-web.zip .   
# -> !project/release/build/blokadna-glasalica-web.zip
```

---

## 1. Dialogue scrambling — `scramble_dialogues.py`

### Usage

```bash
cd '!project/build'
./scramble_dialogues.py
```

Needs Python 3. Can be run from any directory.

Output:

```
Scrambled 26 dialogues, version 1759262400 -> …/dialogues_content.bin
Hosted copy -> …/glasalica/dialogues.bin (commit and push it to publish)
```

The script exits with an error and writes nothing if the scrambling key is missing or
any dialogue file is invalid.

### Input and output

All under `!project/build/design/dialogues/`:

| File                    | Role                                        |
| ----------------------- | ------------------------------------------- |
| `content/voter_*.json`  | **input** — one dialogue per file           |
| `dialogues_content.bin` | **output** — scrambled content for the game |

### Configuration

`code/runtime_credentials.cfg` (gitignored; copy `runtime_credentials.example.cfg`):

```ini
[dialogues]
scrambler_key="<scramble-key>"
```

Changing the scrambling key means rescrambling **and** re-exporting.

### Publishing new dialogues without a new build

Every existing build reads its dialogues from `https://raw.githubusercontent.com/zeljko-vulovic/glasalica/main/dialogues.bin`, so revised dialogues reach players as soon as the `content/voter_*.json` files are updated, the script is run, and the regenerated `dialogues.bin` is committed and pushed to the `glasalica` repository.

---

## 2. Exporting — `export.sh`

### Usage

**Important: close the Godot editor first** — the script refuses to run while
the editor has the project open.

```bash
cd prod
./export.sh            # release: Android AAB + iOS Xcode project + web
./export.sh android    # release Android AAB only
./export.sh ios        # release iOS Xcode project only
./export.sh web        # release web build only
./export.sh debug      # debug Android AAB (no release keystore needed)
```

Output, in `!project/release/build/` (next to `blokadna-glasalica`):

| Target  | File                                                                     |
| ------- | ------------------------------------------------------------------------ |
| Android | `android/blokadna-glasalica.aab` (debug: `blokadna-glasalica-debug.aab`) |
| iOS     | `ios/blokadna-glasalica.xcodeproj` — archive and upload with Xcode       |
| Web     | `web/index.html` + files — must be served over HTTP                      |

Each target prints its output path, or the errors and `FAILED: <preset>` with
a non-zero exit.

### Packaging the build

After a web export, zip the build for upload, from `prod/`:

```bash
cd ../../../release/build/web
zip -r -FS ../blokadna-glasalica-web.zip .
# -> !project/release/build/blokadna-glasalica-web.zip
```

### Requirements

- Godot at `/Applications/Godot.app` with 4.6 export templates
- Android Gradle template unpacked in `code/android/build/`
- The configuration files below

### Configuration

All in `code/` unless noted.

| File                                      | In git | What it holds                                       |
| ----------------------------------------- | ------ | --------------------------------------------------- |
| `export_presets.cfg`                      | no     | the `Android`, `iOS` and `Web` presets              |
| `export_credentials.cfg`                  | no     | keystore and provisioning secrets                   |
| `runtime_credentials.cfg`                 | no     | database and dialogue settings packed into the game |
| `project.godot`                           | yes    | `config/version`                                    |
| `!project/release/export_credentials.cfg` | —      | backup copy of `export_credentials.cfg`             |

#### `export_presets.cfg`

Preset names must stay `Android`, `iOS` and `Web`. Each preset:

- exports all resources and additionally includes
  `!project/build/design/dialogues/dialogues_content.bin, runtime_credentials.cfg`
  (`include_filter`)
- Android: Gradle build, AAB, arm64 only, `package/unique_name`,
  `version/code`, `version/name`
- iOS: `application/bundle_identifier`, `application/version`,
  `application/short_version`
- Web: no threads, no extensions

**Every release** bump the versions together:

| Where           | Key                         | Rule                     |
| --------------- | --------------------------- | ------------------------ |
| Android preset  | `version/code`              | +1, must always increase |
| Android preset  | `version/name`              | e.g. `0.8.0`             |
| iOS preset      | `application/version`       | +1                       |
| iOS preset      | `application/short_version` | same as `version/name`   |
| `project.godot` | `config/version`            | same as `version/name`   |

#### `export_credentials.cfg`

```ini
[preset.0.options]
keystore/release="<path to release keystore>"
keystore/release_user="<alias>"
keystore/release_password="<password>"
```

The `[preset.1.options]` section holds the iOS provisioning profiles.

#### `runtime_credentials.cfg`

```ini
[database]
debug_release=true          ; true = release builds still use the development database
database_endpoint="https://<production-project-id>-default-rtdb.firebaseio.com"

[dialogues]
scrambler_key="<scramble-key>"
```

`export.sh` reports which database the build will use:

- `debug_release=false` → `== database: PRODUCTION` plus a reminder to lock
  the development database rules
- otherwise → `== database: development`
