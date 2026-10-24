# DSMHub

Open `index.html` (or host it with GitHub Pages).

## Icons
Icons are SVG files in two folders: `icons/dark/` and `icons/light/`. The OS picks the folder from the theme (Settings > Theme).

To add a built-in app icon:
1. Add `myapp.svg` to both `icons/dark/` and `icons/light/`.
2. Add `icon:'myapp'` to the app's entry in the `apps` list in `index.html`.

To add a shortcut without editing code: Settings > Add a shortcut (name, link, optional icon URL).

## jsDelivr
Push this repo to GitHub, then in `index.html` set:

    const ICON_BASE='https://cdn.jsdelivr.net/gh/YOUR_USER/YOUR_REPO@main/icons/';

Any icon is then available at `https://cdn.jsdelivr.net/gh/YOUR_USER/YOUR_REPO@main/icons/dark/files.svg` (swap `dark` for `light`).

## Games (encrypted)
Your games are encrypted before they go on GitHub, so the `games` folder only shows scrambled `.enc` files. There is no code to type.

1. Open `encrypt.html` on your computer (keep it and your original game files out of the repo).
2. Pick your single-file `.html` games. To get picture tiles, also pick thumbnail images named like the games (`snake.png` for `snake.html`). Press Encrypt, then Download all.
3. Upload the `.enc` files and `index.json` to a folder called `games` in your repo.
4. In DSMHub, open Games. Your games show as a grid of tiles; click one to open it in its own window.
   To add more later, run `encrypt.html` again and pick your existing `index.json`.

Notes:
- The key is stored in `GAMES_KEY` in `index.html` and in `encrypt.html` (they must match). This hides the games from people browsing your `games` folder, but anyone who reads your site's `index.html` can find the key. To change it, change both and re-encrypt.
- Games must be one self-contained HTML file. Separate images or scripts would be public.
- Open the site from GitHub Pages or a local server (for example `python -m http.server`), not by double-clicking the file.
