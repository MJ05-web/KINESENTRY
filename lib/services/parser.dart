Map<String, double> parseData(String raw) {

  final parts = raw.split(",");
  Map<String, double> result = {};

  for (var p in parts) {
    var kv = p.split(":");

    if (kv.length == 2) {
      result[kv[0].toLowerCase()] = double.parse(kv[1]);
    }
  }

  return result;
}