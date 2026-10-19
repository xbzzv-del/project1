class DataCard {
  String typeName;
  int width;
  int height;

  DataCard({
    required this.typeName,
    this.width = 100,
    this.height = 100,
  });

  Map<String, dynamic> toJson() => {
    'type_name': typeName,
    'width': width,
    'height': height,
  };

  factory DataCard.fromJson(Map<String, dynamic> json) => DataCard(
    typeName: json['type_name'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
  );

  DataCard copyWith({
    String? typeName,
    int? width,
    int? height,
  }) => DataCard(
    typeName: typeName ?? this.typeName,
    width: width ?? this.width,
    height: height ?? this.height,
  );
}
