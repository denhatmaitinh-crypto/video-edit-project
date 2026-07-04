#!/usr/bin/env python3
"""CLI wrapper around VieNeu-TTS v3 Turbo for generating Vietnamese speech."""

import argparse
import sys


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--text", help="Text to synthesize.")
    parser.add_argument("--text-file", help="Path to a file containing the text to synthesize.")
    parser.add_argument("--output", help="Path to write the generated .wav file to.")
    parser.add_argument("--voice", help="Name of a built-in preset voice.")
    parser.add_argument("--ref-audio", help="Path to a 3-5s reference audio clip for voice cloning.")
    parser.add_argument(
        "--mode",
        default="v3turbo",
        help="VieNeu-TTS mode (default: v3turbo). See vieneu.Vieneu docstring for other modes.",
    )
    parser.add_argument(
        "--list-voices",
        action="store_true",
        help="List available built-in preset voices and exit.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    from vieneu import Vieneu

    tts = Vieneu(mode=args.mode)

    if args.list_voices:
        for label, voice_id in tts.list_preset_voices():
            print(f"{label}\t{voice_id}")
        return

    if not args.output:
        sys.exit("--output is required unless --list-voices is passed")

    text = args.text
    if args.text_file:
        with open(args.text_file, encoding="utf-8") as f:
            text = f.read()
    if not text:
        sys.exit("Provide --text or --text-file")

    infer_kwargs = {}
    if args.voice:
        infer_kwargs["voice"] = args.voice
    if args.ref_audio:
        infer_kwargs["ref_audio"] = args.ref_audio

    audio = tts.infer(text, **infer_kwargs)
    tts.save(audio, args.output)
    print(f"Saved: {args.output}")


if __name__ == "__main__":
    main()
