class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl; // Store local or network image path
 

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
   
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(), // Ensure id is always a String
      name: json['name'],
      price: (json['price'] as num).toDouble(), // Safely cast to double
      imageUrl: json['imageUrl'],
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      
    };
  }
}
