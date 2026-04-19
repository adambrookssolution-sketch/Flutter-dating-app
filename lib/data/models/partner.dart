/// One half of a couple. Stored as a sub-object inside the `couples` document
/// (never as a separate Firestore document — couple-as-single-entity rule).
class Partner {
  final String name;
  final String birth; // "DD/MM/YYYY" — kept as string to match legacy schema
  final String height; // "175 cm" or "5'7\""

  const Partner({
    required this.name,
    required this.birth,
    required this.height,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'birth': birth,
        'height': height,
      };

  factory Partner.fromMap(Map<String, dynamic>? m) => Partner(
        name: (m?['name'] as String?) ?? '',
        birth: (m?['birth'] as String?) ?? '',
        height: (m?['height'] as String?) ?? '',
      );

  Partner copyWith({String? name, String? birth, String? height}) => Partner(
        name: name ?? this.name,
        birth: birth ?? this.birth,
        height: height ?? this.height,
      );
}
