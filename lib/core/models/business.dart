class Business {
  const Business({
    required this.id,
    required this.name,
    required this.timezone,
    required this.currency,
  });

  final String id;
  final String name;
  final String timezone;
  final String currency;

  factory Business.fromMap(Map<String, dynamic> m) => Business(
    id: m['id'] as String,
    name: m['name'] as String,
    timezone: m['timezone'] as String,
    currency: m['currency'] as String,
  );
}
