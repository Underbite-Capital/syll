#!/usr/bin/env python3
"""List locally marked Syll failures without copying private audio into the repo."""

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--corpus", type=Path,
        default=Path.home() / "Library/Application Support/Syll/FailureEvidence/marked",
    )
    args = parser.parse_args()
    if not args.corpus.exists():
        return 0
    for metadata_path in sorted(args.corpus.glob("*/failure.json")):
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        audio_name = metadata.get("audioFile")
        if not isinstance(audio_name, str) or Path(audio_name).name != audio_name:
            raise ValueError(f"invalid audio filename in {metadata_path}")
        audio_path = metadata_path.parent / audio_name
        if not audio_path.is_file():
            raise FileNotFoundError(audio_path)
        print(json.dumps({
            "transcriptionID": metadata["transcriptionID"],
            "timestamp": metadata["timestamp"],
            "audioPath": str(audio_path),
            "metadataPath": str(metadata_path),
        }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
