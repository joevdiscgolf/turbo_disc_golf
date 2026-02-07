#!/usr/bin/env python3
"""
Convert YOLOv8n COCO to TFLite for Flutter.

This script downloads the pre-trained YOLOv8 nano model (trained on COCO)
and converts it to TFLite format for use in the Flutter app.

The COCO dataset includes "frisbee" as class 29, which we use for disc detection.

Usage:
    pip install ultralytics
    python scripts/convert_yolov8_to_tflite.py

Output:
    assets/ml/yolov8n_coco.tflite
"""
import os
import shutil
from pathlib import Path

try:
    from ultralytics import YOLO
except ImportError:
    print("Error: ultralytics package not found.")
    print("Please install it with: pip install ultralytics")
    exit(1)


def main():
    # Get the project root directory (parent of scripts/)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    assets_ml_dir = project_root / "assets" / "ml"

    print("=" * 60)
    print("YOLOv8n COCO to TFLite Converter")
    print("=" * 60)

    # Load YOLOv8 nano (smallest, fastest model)
    print("\n[1/4] Loading YOLOv8 nano model...")
    model = YOLO("yolov8n.pt")

    # Verify frisbee class exists in COCO
    print("\n[2/4] Verifying COCO classes...")
    frisbee_class = model.names.get(29)
    if frisbee_class == "frisbee":
        print(f"  Frisbee class found at index 29: '{frisbee_class}'")
    else:
        print(f"  Warning: Expected 'frisbee' at index 29, got '{frisbee_class}'")
        print("  Available classes:")
        for i, name in model.names.items():
            print(f"    {i}: {name}")

    # Export to TFLite at 320x320 (matches current inputWidth/inputHeight in Flutter)
    print("\n[3/4] Exporting to TFLite (320x320)...")
    print("  This may take a few minutes...")
    export_path = model.export(format="tflite", imgsz=320)
    print(f"  Exported to: {export_path}")

    # Find the generated TFLite file
    # ultralytics creates a folder like "yolov8n_saved_model" with the .tflite inside
    print("\n[4/4] Moving TFLite file to assets/ml/...")

    # The export returns the path to the exported model
    # For TFLite, it's typically in a _saved_model folder
    tflite_source = None
    if export_path:
        export_path = Path(export_path)
        if export_path.suffix == ".tflite":
            tflite_source = export_path
        elif export_path.is_dir():
            # Look for .tflite file in the directory
            for f in export_path.glob("*.tflite"):
                tflite_source = f
                break

    # Also check common locations
    if tflite_source is None:
        possible_paths = [
            Path("yolov8n_saved_model/yolov8n_float32.tflite"),
            Path("yolov8n_float32.tflite"),
            Path("yolov8n.tflite"),
        ]
        for p in possible_paths:
            if p.exists():
                tflite_source = p
                break

    if tflite_source and tflite_source.exists():
        # Ensure assets/ml directory exists
        assets_ml_dir.mkdir(parents=True, exist_ok=True)

        # Copy to assets/ml/
        dest_path = assets_ml_dir / "yolov8n_coco.tflite"
        shutil.copy2(tflite_source, dest_path)
        print(f"  Copied to: {dest_path}")
        print(f"  File size: {dest_path.stat().st_size / (1024 * 1024):.2f} MB")
    else:
        print("  Error: Could not find generated TFLite file.")
        print("  Please manually copy the .tflite file to assets/ml/yolov8n_coco.tflite")
        print(f"  Export path was: {export_path}")

    print("\n" + "=" * 60)
    print("Conversion complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Verify the model exists at: assets/ml/yolov8n_coco.tflite")
    print("2. Run 'flutter analyze' to check for errors")
    print("3. Test on device with putt practice screen")


if __name__ == "__main__":
    main()
