class Character {
  final String id;
  final String charId;
  final String nameEn;
  final String aka;
  final String nameAr;
  final String nameJp;
  final String gender;
  final String age;
  final String height;
  final String weight;
  final String bloodType;
  final String relationId;
  final String photo;
  final String cover;
  final String likersCount;
  final String views;

  Character({
    required this.id,
    required this.charId,
    required this.nameEn,
    required this.aka,
    required this.nameAr,
    required this.nameJp,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.bloodType,
    required this.relationId,
    required this.photo,
    required this.cover,
    required this.likersCount,
    required this.views,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['Id']?.toString() ?? json['ID']?.toString() ?? '',
      charId: json['CharId']?.toString() ?? '',
      nameEn: json['NameEN']?.toString() ?? '',
      aka: json['Aka']?.toString() ?? '',
      nameAr: json['NameAR']?.toString() ?? '',
      nameJp: json['NameJP']?.toString() ?? '',
      gender: json['Gender']?.toString() ?? '',
      age: json['Age']?.toString() ?? '',
      height: json['Height']?.toString() ?? '',
      weight: json['Weight']?.toString() ?? '',
      bloodType: json['BloodType']?.toString() ?? '',
      relationId: json['RelationId']?.toString() ?? '',
      photo: json['Photo']?.toString() ?? '',
      cover: json['Cover']?.toString() ?? '',
      likersCount: json['LikersCount']?.toString() ?? '0',
      views: json['Views']?.toString() ?? '0',
    );
  }
}
