# Upstream material and notices

Omarchy Tablet Lockscreen Touch is MIT licensed, © 2026 Omid.Developer (see
[LICENSE](LICENSE)). Parts of it are derived from Omarchy, which is MIT
licensed under the notice below. That notice is kept here, as the licence
requires, for the material that was reused.

## Omarchy (https://github.com/omacom/omarchy)

Copyright (c) David Heinemeier Hansson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Reused material

- `Service.qml`, `LockView.qml`, `TouchKeyboard.qml` — cloned and adapted from
  Omarchy's stock `omarchy.lock` Quickshell plugin
  (`/usr/share/omarchy/shell/plugins/lock`). PAM stack names, wallpaper
  handling and the `lock` IPC target come from that plugin.
- `sddm-theme/` — adapted from Omarchy's stock SDDM greeter: the artwork
  (`logo.png`, `lock.png`, `lock-failed.png`, `entry.png`, `entry-failed.png`,
  `bullet.png`), the Tokyo Night colour palette and the `SddmGreeterTheme`
  structure.

## Astral wallpaper (preview and `assets/`)

`assets/astral-wallpaper.webp` is the wallpaper the preview screenshot was
captured over: Astral, © 2026 Manuel Burki, MIT licensed, from
[github.com/brmnl/omarchy-astral-theme](https://github.com/brmnl/omarchy-astral-theme).
See [assets/README.md](assets/README.md).
