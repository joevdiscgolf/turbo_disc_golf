/// Strips " Position" / " position" suffix from a checkpoint name for chip labels.
String formatCheckpointChipLabel(String name) {
  return name.replaceAll(' Position', '').replaceAll(' position', '').trim();
}
