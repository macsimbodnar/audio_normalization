# Audio Normalization

```text
  ________  ________  ________  ________  ________
 /        \/        \/        \/        \/        \
|    __    |    ____|    __    |    __    |    ____|
|   |  |   |   |    |   |  |   |   |  |   |   |
|   |__|   |   |____|   |__|   |   |__|   |   |____
|          |          |        |          |          |
|__/||/|___|__________|\____/__|__________|\________|
      ||
     ====   A U D I O   N O R M A L I Z A T I O N
```

Batch audio normalization scripts for game development. Uses different loudness
strategies for **SFX** (RMS-based) and **Music** (EBU R128 / LUFS-based).

---

## Dependencies

- [`ffmpeg`](https://ffmpeg.org/)
- [`ffmpeg-normalize`](https://github.com/slhck/ffmpeg-normalize) (Python package)

```bash
pip install ffmpeg-normalize
```

---

## Scripts

### `normalize_sfx.sh` — Sound Effects

Uses **RMS normalization** to give SFX a consistent punchy level that sits well
alongside music normalized to -16 LUFS.

| Setting      | Value       | Notes                                  |
|--------------|-------------|----------------------------------------|
| Strategy     | RMS         | Consistent perceived punch             |
| Target RMS   | -20 dBFS    | Tune to -22..-18 for more/less hit     |
| Peak ceiling | -1 dBFS     | Safety headroom via `alimiter`         |
| Sample rate  | 48000 Hz    | Godot-safe (change to 44100 if needed) |
| Channels     | Stereo (2)  |                                        |
| Codec        | `pcm_s16le` | Uncompressed WAV                       |

```bash
./normalize_sfx.sh <input_folder> <output_folder>

# Example:
./normalize_sfx.sh .in/sfx .out/sfx
```

---

### `normalize_music.sh` — Music / BGM

Uses **EBU R128** loudness normalization — the broadcast/streaming standard —
targeting integrated loudness (LUFS) and controlling true peak and dynamic range.

| Setting           | Value       | Notes                                     |
|-------------------|-------------|-------------------------------------------|
| Strategy          | EBU R128    | Perceptually accurate integrated loudness |
| Target integrated | -16 LUFS    | Common baseline for game BGM              |
| True peak         | -1.5 dBTP   | Prevents inter-sample clipping            |
| Loudness range    | 11 LU       | Preserves dynamics without inconsistency  |
| Sample rate       | 48000 Hz    |                                           |
| Channels          | Stereo (2)  |                                           |
| Codec             | `pcm_s16le` | Uncompressed WAV                          |

```bash
./normalize_music.sh <input_folder> <output_folder>

# Example:
./normalize_music.sh .in/music .out/music
```

---

## Why different strategies?

| Aspect        | SFX (RMS)                            | Music (EBU R128 / LUFS)                 |
|---------------|--------------------------------------|-----------------------------------------|
| Goal          | Consistent punch per hit             | Consistent perceived loudness over time |
| Standard      | RMS energy                           | Broadcast/streaming standard            |
| Dynamic range | Preserved (short transients matter)  | Controlled via LRA target               |
| Limiter       | Hard peak limiter post-process       | True peak ceiling during normalization  |

SFX are short, transient sounds — RMS keeps them impactful. Music plays for
extended periods — LUFS measures perceptual loudness across the whole track,
which is what matters for a consistent listening experience.

---

## Folder structure

```text
.in/
  sfx/     ← put raw SFX here
  music/   ← put raw music here
.out/
  sfx/     ← normalized SFX output
  music/   ← normalized music output
```

Both scripts preserve subdirectory structure from input to output.
