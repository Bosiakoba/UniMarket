class Campus {
  final String name;
  final String town;
  final String region;
  final bool isMain;

  Campus({
    required this.name,
    required this.town,
    required this.region,
    this.isMain = false,
  });

  factory Campus.fromJson(Map<String, dynamic> json) {
    return Campus(
      name: json['name'] as String,
      town: json['town'] as String,
      region: json['region'] as String,
      isMain: json['isMain'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'town': town,
      'region': region,
      'isMain': isMain,
    };
  }
}

class University {
  final String id;
  final String name;
  final String shortName;
  final String type;
  final String region;
  final List<Campus> campuses;
  final bool verified;

  University({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
    required this.region,
    required this.campuses,
    this.verified = false,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    final campusesList = (json['campuses'] as List<dynamic>?)
            ?.map((e) => Campus.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return University(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      region: json['region'] as String? ?? '',
      campuses: campusesList,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'type': type,
      'region': region,
      'campuses': campuses.map((e) => e.toJson()).toList(),
      'verified': verified,
    };
  }
}
