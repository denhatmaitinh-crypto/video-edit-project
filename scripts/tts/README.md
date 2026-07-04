# VieNeu-TTS v3 Turbo

Vietnamese text-to-speech (48 kHz, instant voice cloning, built-in preset
voices, emotion cues, English–Vietnamese code-switching), for generating
narration/voiceover audio to use in `output/` video edits.

Project: https://github.com/pnnbao97/VieNeu-TTS
Model: https://huggingface.co/pnnbao-ump/VieNeu-TTS-v3-Turbo

## Setup

```zsh
scripts/tts/setup.sh          # CPU (torch-free, via ONNX Runtime)
scripts/tts/setup.sh --gpu    # GPU (CUDA) or Apple Silicon MPS
```

Creates a venv at `scripts/tts/.venv` and installs the `vieneu` package.
On first synthesis, model weights are downloaded from Hugging Face — an
internet connection is required at that point.

## Usage

List built-in preset voices:

```zsh
scripts/tts/generate.sh --list-voices
```

Generate speech with the default voice:

```zsh
scripts/tts/generate.sh \
  --text "Xin chào, đây là VieNeu-TTS phiên bản ba Turbo." \
  --output output/narration.wav
```

Use a preset voice, read text from a file, or clone a voice from a
reference clip:

```zsh
scripts/tts/generate.sh --text-file input/script.txt --voice "Xuân Vĩnh" --output output/narration.wav

scripts/tts/generate.sh --text "Chào bạn, đây là giọng của tôi." \
  --ref-audio input/my_voice.wav --output output/cloned.wav
```

Emotion cues (experimental) can be inlined in the text: `[cười]` (laughter),
`[thở dài]` (sigh), `[hắng giọng]` (throat clear).

## Notes

- `scripts/tts/.venv` is git-ignored; re-run `setup.sh` after a fresh clone.
- Combine generated narration with a video track via `ffmpeg`, e.g.:
  `ffmpeg -i input/video.mp4 -i output/narration.wav -c:v copy -map 0:v:0 -map 1:a:0 output/final.mp4`
