class Voice {
  final String id; // we'll use name as id
  final String name;
  final String locale;

  Voice({
    required this.id,
    required this.name,
    required this.locale,
  });

  factory Voice.fromJson(Map<dynamic, dynamic> json) {
    return Voice(
      id: json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Voice',
      locale: json['locale']?.toString() ?? 'en-US',
    );
  }
}
