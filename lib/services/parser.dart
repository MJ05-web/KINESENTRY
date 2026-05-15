Map<String, double> parseData(String raw) {
  final parts = raw.split(",");
  Map<String, double> result = {};

  for (var p in parts) {
    final kv = p.split(":");

    if (kv.length == 2) {
      final key = kv[0].trim().toLowerCase();
      final value = double.tryParse(kv[1].trim());
      if (value != null) {
        result[key] = value;
      }
    }
  }

  return result;
}
