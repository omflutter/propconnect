class PropertyModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String price;
  final String negotiablePrice;
  final String securityDeposit;
  final String bhk;
  final String type; // Sale / Rent
  final String purpose; // Sale / Rent / Lease
  final bool isPublic;
  final int? agencyId;
  final String agencyName;
  final String propertyType;
  final String status;
  final String brokerName;
  
  // PRD Address & Geo Specifications
  final String country;
  final String stateName;
  final String city;
  final String area;
  final String address;
  final String googleMapUrl;

  // PRD Area Specifications
  final double areaSqft; // Built-up
  final double carpetArea; // Carpet Area

  // PRD Features Specifications
  final int bathrooms;
  final int balcony;
  final int parking;
  final String furnishedStatus;
  final int propertyAge;
  final String maintenanceCharges;
  final List<String> amenities;
  final List<String> images;
  final List<String> floorPlans;
  final List<String> documents;

  // PRD Owner Info & KYC (Protected by Privacy Matrix)
  final String ownerName;
  final String ownerPhonePrimary;
  final String ownerPhoneSecondary;
  final String ownerEmail;
  final String ownerAddress;
  final List<String> ownerKycDocs;
  final String internalNotes;

  PropertyModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.location,
    required this.price,
    this.negotiablePrice = '',
    this.securityDeposit = '',
    required this.bhk,
    required this.type,
    this.purpose = 'Sale',
    required this.isPublic,
    this.agencyId,
    required this.agencyName,
    required this.propertyType,
    required this.status,
    required this.brokerName,
    this.country = 'India',
    this.stateName = '',
    this.city = '',
    this.area = '',
    this.address = '',
    this.googleMapUrl = '',
    required this.areaSqft,
    this.carpetArea = 0.0,
    required this.bathrooms,
    required this.balcony,
    required this.parking,
    required this.furnishedStatus,
    required this.propertyAge,
    required this.maintenanceCharges,
    required this.amenities,
    required this.images,
    this.floorPlans = const [],
    this.documents = const [],
    this.ownerName = '',
    this.ownerPhonePrimary = '',
    this.ownerPhoneSecondary = '',
    this.ownerEmail = '',
    this.ownerAddress = '',
    this.ownerKycDocs = const [],
    this.internalNotes = '',
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    int? parsedAgencyId;
    if (json['agencyId'] != null) {
      parsedAgencyId = int.tryParse(json['agencyId'].toString());
    } else if (json['agency'] is Map && json['agency']['id'] != null) {
      parsedAgencyId = int.tryParse(json['agency']['id'].toString());
    }

    String parsedAgencyName = '';
    if (json['agencyName'] != null && json['agencyName'].toString().trim().isNotEmpty) {
      parsedAgencyName = json['agencyName'].toString().trim();
    } else if (json['agency'] is Map && json['agency']['name'] != null) {
      parsedAgencyName = json['agency']['name'].toString().trim();
    }

    double parsedArea = 1000.0;
    if (json['areaSqft'] != null) {
      parsedArea = double.tryParse(json['areaSqft'].toString()) ?? 1000.0;
    } else if (json['builtUpArea'] != null) {
      parsedArea = double.tryParse(json['builtUpArea'].toString()) ?? 1000.0;
    }

    double parsedCarpet = 0.0;
    if (json['carpetArea'] != null) {
      parsedCarpet = double.tryParse(json['carpetArea'].toString()) ?? 0.0;
    } else {
      parsedCarpet = parsedArea * 0.8;
    }

    return PropertyModel(
      id: (json['id'] ?? json['propertyCode'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      price: json['price'] ?? '₹0',
      negotiablePrice: json['negotiablePrice'] ?? '',
      securityDeposit: json['securityDeposit'] ?? '',
      bhk: json['bhk'] ?? '2 BHK',
      type: json['type'] ?? 'Sale',
      purpose: json['purpose'] ?? json['type'] ?? 'Sale',
      brokerName: json['brokerName'] ?? '',
      agencyId: parsedAgencyId,
      agencyName: parsedAgencyName,
      isPublic: json['isPublic'] ?? false,
      propertyType: json['propertyType'] ?? 'Apartment',
      status: json['status'] ?? 'Available',
      country: json['country'] ?? 'India',
      stateName: json['state'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      googleMapUrl: json['googleMapUrl'] ?? '',
      areaSqft: parsedArea,
      carpetArea: parsedCarpet,
      bathrooms: json['bathrooms'] ?? 2,
      balcony: json['balcony'] ?? 1,
      parking: json['parking'] ?? 1,
      furnishedStatus: json['furnishedStatus'] ?? 'Unfurnished',
      propertyAge: json['propertyAge'] ?? 0,
      maintenanceCharges: json['maintenanceCharges'] ?? '₹0',
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      floorPlans: List<String>.from(json['floorPlans'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
      ownerName: json['ownerName'] ?? '',
      ownerPhonePrimary: json['ownerPhonePrimary'] ?? '',
      ownerPhoneSecondary: json['ownerPhoneSecondary'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      ownerAddress: json['ownerAddress'] ?? '',
      ownerKycDocs: List<String>.from(json['ownerKycDocs'] ?? []),
      internalNotes: json['internalNotes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'negotiablePrice': negotiablePrice,
      'securityDeposit': securityDeposit,
      'bhk': bhk,
      'type': type,
      'purpose': purpose,
      'isPublic': isPublic,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'propertyType': propertyType,
      'status': status,
      'brokerName': brokerName,
      'country': country,
      'state': stateName,
      'city': city,
      'area': area,
      'address': address,
      'googleMapUrl': googleMapUrl,
      'builtUpArea': areaSqft,
      'areaSqft': areaSqft,
      'carpetArea': carpetArea,
      'bathrooms': bathrooms,
      'balcony': balcony,
      'parking': parking,
      'furnishedStatus': furnishedStatus,
      'propertyAge': propertyAge,
      'maintenanceCharges': maintenanceCharges,
      'amenities': amenities,
      'images': images,
      'floorPlans': floorPlans,
      'documents': documents,
      'ownerName': ownerName,
      'ownerPhonePrimary': ownerPhonePrimary,
      'ownerPhoneSecondary': ownerPhoneSecondary,
      'ownerEmail': ownerEmail,
      'ownerAddress': ownerAddress,
      'ownerKycDocs': ownerKycDocs,
      'internalNotes': internalNotes,
    };
  }
}
