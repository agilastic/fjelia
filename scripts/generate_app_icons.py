"""Resize recovered Fjelia artwork for native launcher catalogs (requires Pillow).

The original 152px iPad icon is preserved in assets/branding. No artwork is
redrawn; larger catalog sizes are resampled from this recovered source.
"""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
source = Image.open(root / 'assets/branding/app-icon-original.png').convert('RGB')
ios = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((ios / 'Contents.json').read_text())['images']:
    pixels = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
    source.resize((pixels, pixels), Image.Resampling.LANCZOS).save(ios / entry['filename'])

android = root / 'android/app/src/main/res'
for density, pixels in {'mdpi':48, 'hdpi':72, 'xhdpi':96, 'xxhdpi':144, 'xxxhdpi':192}.items():
    source.resize((pixels, pixels), Image.Resampling.LANCZOS).save(
        android / f'mipmap-{density}/ic_launcher.png')
print('Generated iOS and Android icons from recovered Fjelia artwork.')
