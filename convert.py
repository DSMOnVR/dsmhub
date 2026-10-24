from pathlib import Path
from html import escape

# Read original index.html
html = Path("index.html").read_text(encoding="utf-8")

# Escape HTML for SVG attribute wrapping
srcdoc = escape(html, quote=True)
srcdoc = srcdoc.replace("\n", "&#10;").replace("\t", "&#9;")

# Wrap inside SVG foreignObject
svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xhtml="http://www.w3.org/1999/xhtml"
     width="100%" height="100%">
  <foreignObject x="0" y="0" width="100%" height="100%">
    <body xmlns="http://www.w3.org/1999/xhtml"
          style="margin:0;width:100%;height:100%">
      <iframe
        style="width:100%;height:100%;border:0"
        srcdoc="{srcdoc}">
      </iframe>
    </body>
  </foreignObject>
</svg>
'''

Path("index.svg").write_text(svg, encoding="utf-8")
print("Converted index.html to index.svg")
