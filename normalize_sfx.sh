#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./normalize_sfx_recursive.sh <input_folder> <output_folder>

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input_folder> <output_folder>" >&2
  exit 1
fi

input_dir="$(realpath "$1")"
output_dir="$(realpath -m "$2")"

if [[ ! -d "$input_dir" ]]; then
  echo "Error: input folder does not exist: $input_dir" >&2
  exit 1
fi

mkdir -p "$output_dir"

if ! command -v ffmpeg-normalize >/dev/null 2>&1; then
  echo "Error: ffmpeg-normalize not found in PATH." >&2
  exit 1
fi

# ---- SFX leveling targets (tuned to sit with music at -16 LUFS) ----
rms_target_db="-20"     # tweak: -22..-18 depending on how punchy you want SFX
peak_ceiling_db="-1"    # safety headroom

# Godot-safe WAV output (match your project settings)
sample_rate="48000"     # set to 44100 if your project uses that
channels="2"
pcm_codec="pcm_s16le"

# Limiter: use 'limit' (dB) rather than 'level' (boolean on some builds)
post_limiter="alimiter=limit=${peak_ceiling_db}dB:attack=5:release=50"
# If your ffmpeg doesn't support alimiter at all, use this instead:
# post_limiter="alimit=limit=${peak_ceiling_db}dB"
# -------------------------------------------------------------------

echo "Input : $input_dir"
echo "Output: $output_dir"
echo "Settings: RMS=$rms_target_db dBFS | Peak ceiling=${peak_ceiling_db} dB | SR=$sample_rate | CH=$channels | CODEC=$pcm_codec"
echo

found_any=0

while IFS= read -r -d '' in_file; do
  found_any=1

  rel_path="${in_file#"$input_dir"/}"
  out_file="$output_dir/$rel_path"
  mkdir -p "$(dirname "$out_file")"

  echo "Leveling SFX:"
  echo "  IN : $in_file"
  echo "  OUT: $out_file"

  ffmpeg-normalize "$in_file" \
    --normalization-type rms \
    --target-level "$rms_target_db" \
    --post-filter "$post_limiter" \
    --sample-rate "$sample_rate" \
    --audio-channels "$channels" \
    --audio-codec "$pcm_codec" \
    --output "$out_file" \
    --force \
    --progress

  echo
done < <(find "$input_dir" -type f -iname '*.wav' -print0)

if [[ "$found_any" -eq 0 ]]; then
  echo "No .wav files found under: $input_dir" >&2
  exit 2
fi

echo "Done. Leveled SFX written under: $output_dir"
