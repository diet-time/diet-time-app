class TakeawayBranch {
  const TakeawayBranch({required this.id, required this.name, this.address});
  factory TakeawayBranch.fromJson(Map<String, dynamic> json) => TakeawayBranch(
    id: json['id']?.toString().trim() ?? '',
    name: json['name']?.toString().trim() ?? '',
    address: json['address'] as String?,
  );
  final String id;
  final String name;
  final String? address;
}
