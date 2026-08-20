String formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String formatBirthdate(int? value) {
  if (value == null || value <= 0) return '';
  final s = value.toString();
  if (s.length != 8) return s;
  final year = int.tryParse(s.substring(0, 4));
  final month = int.tryParse(s.substring(4, 6));
  final day = int.tryParse(s.substring(6, 8));
  if (year == null ||
      month == null ||
      day == null ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31) {
    return s;
  }
  return '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}';
}
