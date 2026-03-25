String filesize(int size, [int round = 2]) {
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
  const divider = 1024;

  if (size < divider) {
    return '$size B';
  }

  double result = size.toDouble();
  int unitIndex = 0;
  while (result >= divider && unitIndex < units.length - 1) {
    result /= divider;
    unitIndex++;
  }

  return result == result.roundToDouble()
      ? '${result.toStringAsFixed(0)} ${units[unitIndex]}'
      : '${result.toStringAsFixed(round)} ${units[unitIndex]}';
}
