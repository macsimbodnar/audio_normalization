#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./normalize_music_recursive.sh <input_folder> <output_folder>
#
# Example:
#   ./normalize_music_recursive.sh assets/music normalized/music

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

# ---- Music loudness strategy for video games (recommended defaults) ----
# Target integrated loudness:
#   -16 LUFS is a common and safe baseline for game BGM (gives headroom for SFX/dialog).
target_lufs="-16"

# True peak limit:
#   -1.5 dBTP helps avoid inter-sample clipping, especially after engine mixing / device DAC.
true_peak="-1.5"

# Loudness range target:
#   11 LU is a good compromise: keeps some dynamics without being wildly inconsistent.
lra_target="11"

# Godot-safe WAV output (match your project settings)
sample_rate="48000"     # set to 44100 if your project uses that
channels="2"
pcm_codec="pcm_s16le"
# ----------------------------------------------------------------------

# Ensure required tools exist
if ! command -v ffmpeg-normalize >/dev/null 2>&1; then
  echo "Error: ffmpeg-normalize not found in PATH." >&2
  exit 1
fi

echo "Input : $input_dir"
echo "Output: $output_dir"
echo "Settings: EBU R128 | I=$target_lufs LUFS | TP=$true_peak dBTP | LRA=$lra_target LU | SR=$sample_rate | CH=$channels | CODEC=$pcm_codec"
echo

found_any=0

# -print0 to safely handle all filenames
while IFS= read -r -d '' in_file; do
  found_any=1

  # Compute relative path from input_dir to file (preserve folder structure)
  rel_path="${in_file#"$input_dir"/}"
  out_file="$output_dir/$rel_path"

  # Create output subfolder
  out_subdir="$(dirname "$out_file")"
  mkdir -p "$out_subdir"

  echo "Normalizing:"
  echo "  IN : $in_file"
  echo "  OUT: $out_file"

  ffmpeg-normalize "$in_file" \
    --normalization-type ebu \
    --target-level "$target_lufs" \
    --true-peak "$true_peak" \
    --loudness-range-target "$lra_target" \
    --sample-rate "$sample_rate" \
    --audio-channels "$channels" \
    --audio-codec "$pcm_codec" \
    --output "$out_file" \
    --force \
    --progress

  echo
done < <(find "$input_dir" -type f \( -iname '*.wav' \) -print0)

if [[ "$found_any" -eq 0 ]]; then
  echo "No .wav files found under: $input_dir" >&2
  exit 2
fi

echo "Done. Normalized music written under: $output_dir"
