class MaterialClass {
  final int id;
  final String title;
  final String description;
  final String materialType;
  final String materialLink; // Thêm thuộc tính materialLink

  MaterialClass({
    required this.id,
    required this.title,
    required this.description,
    required this.materialType,
    required this.materialLink,
  });

  // Cập nhật phương thức fromJson để chuyển đổi JSON thành đối tượng Material, bao gồm cả materialLink
  factory MaterialClass.fromJson(Map<String, dynamic> json) {

    return MaterialClass(
      id: json['id'] != null ? int.parse(json['id'].toString()) : 0 ,
      title: json['material_name'] as String? ?? 'No Title',
      description: json['description'] as String? ?? 'No Description',
      materialType: json['material_type'] as String? ?? 'Unknown',
      materialLink: json['material_link'] as String? ?? 'No Link', // Lấy giá trị material_link từ JSON
    );
  }
}
