# Native media orientation fixture

The 32×48 MP4 contains two thirds red at the top and one third blue at the bottom.
All frames are identical. Tests must decode row zero as red and the last row as
blue; grayscale red is brighter than blue. No source recording or personal data
is included.

Regenerate with ffmpeg:

```sh
ffmpeg -y -f lavfi -i 'color=c=red:s=32x48:r=6:d=1' \
  -vf 'drawbox=x=0:y=32:w=iw:h=16:color=blue:t=fill' \
  -c:v libx264 -pix_fmt yuv420p fixtures/media-orientation/red-top-blue-bottom.mp4
```
