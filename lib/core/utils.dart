String formatDateTime(dynamic value) {
  if (value == null) return '-';
  final dt = DateTime.tryParse(value.toString())?.toLocal();
  if (dt == null) return value.toString();
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
