# Asus Profiles

Minimum noctalia version: `3.8.2`

Brings G-Helper to your noctalia shell.  

Made possible by [asusctl](https://gitlab.com/asus-linux/asusctl) and [cardwire](https://github.com/luytan/cardwire).
Thanks to [G-Helper](https://g-helper.com/), [noctalia-supergfxctl](https://github.com/cod3ddot/noctalia-supergfxctl) for code inspiration.
Check out [noctalia](https://github.com/noctalia-dev/noctalia-shell) for a great shell.

## Development Setup

Follow [noctalia documentation](https://docs.noctalia.dev/development/plugins/overview/)


## Project Structure

```
├── LICENCES/               # REUSE licenses (See README)
├── i18n/					# Translations
│── Bar.qml				    # Bar widget UI
│── Main.qml			    # Entrypoint, common logic
│── Panel.qml			    # Panel UI
│── Settings.qml            # Settings UI
├── CHANGES.md              # Changelog
├── COPYING                 # MIT (See README)
├── manifest.json           # https://docs.noctalia.dev/plugins/manifest/
└── README.md               # This file
```

## License

This project strives to be [REUSE](https://reuse.software/) compliant.

Generally:
- Documentation is under CC-BY-NC-SA-4.0
- Code is under MIT
- Config and translation files are under CC0-1.0

```
Copyright (c) 2026 jroyzen07@gmail.com
	
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
	
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
	
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
```
