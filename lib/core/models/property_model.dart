class PropertyModel {
  final String id;
  final String title;
  final String location;
  final String price;
  final String bhk;
  final String type; // Sale / Rent
  final bool isPublic;
  final String agencyName;
  final String propertyType;
  final String status;
  final String brokerName;
  
  // New PRD Specifications
  final int bathrooms;
  final int balcony;
  final int parking;
  final String furnishedStatus;
  final int propertyAge;
  final double areaSqft;
  final String maintenanceCharges;
  final List<String> amenities;
  final List<String> images;

  PropertyModel({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.bhk,
    required this.type,
    required this.isPublic,
    required this.agencyName,
    required this.propertyType,
    required this.status,
    required this.brokerName,
    required this.bathrooms,
    required this.balcony,
    required this.parking,
    required this.furnishedStatus,
    required this.propertyAge,
    required this.areaSqft,
    required this.maintenanceCharges,
    required this.amenities,
    required this.images,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'],
      title: json['title'],
      price: json['price'],
      location: json['location'],
      bhk: json['bhk'],
      type: json['type'],
      brokerName: json['brokerName'],
      agencyName: json['agencyName'],
      isPublic: json['isPublic'] ?? false,
      propertyType: json['propertyType'] ?? 'Apartment',
      status: json['status'] ?? 'Available',
      bathrooms: json['bathrooms'] ?? 2,
      balcony: json['balcony'] ?? 1,
      parking: json['parking'] ?? 1,
      furnishedStatus: json['furnishedStatus'] ?? 'Unfurnished',
      propertyAge: json['propertyAge'] ?? 0,
      areaSqft: (json['areaSqft'] ?? 1000.0).toDouble(),
      maintenanceCharges: json['maintenanceCharges'] ?? '₹0',
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
    );
  }
}
