# Label Crosstalk

An Audacity 3.x Nyquist plugin that detects crosstalk (simultaneous speech) between two separate speaker tracks and marks the overlap regions with labels.

Built for podcast editors who record separate tracks per speaker and need to quickly find where people talked over each other.

## How It Works

1. Select exactly **2 mono tracks** (e.g., host and guest from a Zoom recording)
2. Select the time range you want to analyze (or Select All)
3. Run **Analyze → Label Crosstalk...**
4. The plugin adds a label track with markers at every overlap region

Under the hood, it computes an RMS energy profile for each track, finds frames where both speakers are active simultaneously, and merges nearby regions into labeled spans.

## Installation

1. Download [`label-crosstalk.ny`](label-crosstalk.ny)
2. Copy it to your Audacity plugins folder:
   - **macOS:** `~/Library/Application Support/audacity/Plug-Ins/`
   - **Windows:** `C:\Users\<you>\AppData\Roaming\audacity\Plug-Ins\`
   - **Linux:** `~/.audacity-data/Plug-Ins/`
3. Restart Audacity
4. The plugin appears under **Analyze → Label Crosstalk...**

## Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| Silence threshold | -40 dB | Audio below this level is considered silence |
| Analysis window | 50 ms | Size of each analysis frame |
| Minimum overlap | 100 ms | Ignore overlaps shorter than this |

The defaults work well for most podcast recordings. If you're getting too many false positives, raise the silence threshold (e.g., -35 dB) or increase the minimum overlap.

## Requirements

- Audacity 3.x
- Two mono audio tracks (separate speaker recordings)

## License

Public Domain
