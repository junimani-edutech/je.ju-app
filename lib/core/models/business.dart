class Business {
  const Business({
    required this.id,
    required this.name,
    required this.timezone,
    required this.currency,
    this.legalName,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.logoUrl,
    this.receiptFooter,
  });

  final String id;
  final String name;
  final String timezone;
  final String currency;
  final String? legalName;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String? logoUrl;
  final String? receiptFooter;

  factory Business.fromMap(Map<String, dynamic> m) => Business(
    id: m['id'] as String,
    name: m['name'] as String,
    timezone: m['timezone'] as String,
    currency: m['currency'] as String,
    legalName: m['legal_name'] as String?,
    contactEmail: m['contact_email'] as String?,
    contactPhone: m['contact_phone'] as String?,
    address: m['address'] as String?,
    logoUrl: m['logo_url'] as String?,
    receiptFooter: m['receipt_footer'] as String?,
  );
}
