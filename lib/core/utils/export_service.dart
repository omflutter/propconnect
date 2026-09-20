import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/owner_model.dart';

class ExportService {
  /// Generate an Excel-compliant CSV String with UTF-8 BOM for a list of properties.
  static String generatePropertiesCsv(List<PropertyModel> properties) {
    final List<List<dynamic>> rows = [];

    // 1. Excel CSV Header Row
    rows.add([
      'Property ID',
      'Title',
      'Type / Purpose',
      'Property Type',
      'Price',
      'Status',
      'BHK',
      'Bathrooms',
      'Balcony',
      'Carpet Area (sqft)',
      'Super Area (sqft)',
      'Furnishing',
      'Parking',
      'Location',
      'City',
      'State',
      'Owner ID',
      'Owner Name',
      'Owner Primary Phone',
      'Owner Secondary Phone',
      'Owner Email',
      'Confidential Min Price',
      'Amenities',
      'Public Listing',
    ]);

    // 2. Data Rows
    for (final p in properties) {
      rows.add([
        p.id,
        p.title,
        p.purpose.isNotEmpty ? p.purpose : p.type,
        p.propertyType,
        p.price,
        p.status,
        p.bhk,
        p.bathrooms,
        p.balcony,
        p.carpetArea,
        p.areaSqft,
        p.furnishedStatus,
        p.parking,
        p.location,
        p.city,
        p.stateName,
        p.ownerId?.toString() ?? '',
        p.ownerName,
        p.ownerPhonePrimary,
        p.ownerPhoneSecondary,
        p.ownerEmail,
        p.negotiablePrice,
        p.amenities.join('; '),
        p.isPublic ? 'Yes' : 'No',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return '\uFEFF$csvData';
  }

  /// Export a list of properties to an Excel-compliant CSV file and trigger the native Share/Open sheet.
  static Future<String?> exportPropertiesToExcel({
    required List<PropertyModel> properties,
    String title = 'Properties_Export',
  }) async {
    try {
      final excelFileContent = generatePropertiesCsv(properties);
      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${title}_$timeStamp.csv';

      if (kIsWeb) {
        return excelFileContent;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(excelFileContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv', name: fileName)],
          subject: 'PropConnect Export: $title',
          text: 'Exported ${properties.length} properties from PropConnect.',
        ),
      );

      return file.path;
    } catch (e) {
      debugPrint('Error exporting properties to Excel: $e');
      return null;
    }
  }

  /// Generate an Excel-compliant CSV String with UTF-8 BOM for an Owner portfolio.
  static String generateOwnerPortfolioCsv({
    required OwnerModel owner,
    required List<PropertyModel> ownerProperties,
  }) {
    final List<List<dynamic>> rows = [];

    // Owner Header
    rows.add(['PROPCONNECT - OWNER PORTFOLIO REPORT']);
    rows.add(['Generated At', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())]);
    rows.add([]);

    // Owner Details Section
    rows.add(['OWNER INFORMATION']);
    rows.add(['Owner ID', owner.id]);
    rows.add(['Full Name', owner.name]);
    rows.add(['Primary Phone', owner.phonePrimary]);
    rows.add(['Secondary Phone', owner.phoneSecondary]);
    rows.add(['Email Address', owner.email]);
    rows.add(['Address', owner.address]);
    rows.add(['KYC Document Type', owner.idType]);
    rows.add(['KYC Document Number', owner.idNumber]);
    rows.add(['Confidential Internal Notes', owner.notes]);
    rows.add(['Total Properties Listed', ownerProperties.length]);
    rows.add([]);

    // Properties Section
    rows.add(['PROPERTIES LISTED BY ${owner.name.toUpperCase()}']);
    rows.add([
      'Property ID',
      'Title',
      'Type',
      'Price',
      'Status',
      'BHK',
      'Super Area (sqft)',
      'Carpet Area (sqft)',
      'Location',
      'City',
      'Min Target Price (Confidential)',
      'Public Listing',
    ]);

    for (final p in ownerProperties) {
      rows.add([
        p.id,
        p.title,
        p.purpose.isNotEmpty ? p.purpose : p.type,
        p.price,
        p.status,
        p.bhk,
        p.areaSqft,
        p.carpetArea,
        p.location,
        p.city,
        p.negotiablePrice,
        p.isPublic ? 'Yes' : 'No',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return '\uFEFF$csvData';
  }

  /// Export an Owner profile along with all their linked properties to an Excel-compliant CSV.
  static Future<String?> exportOwnerPortfolioToExcel({
    required OwnerModel owner,
    required List<PropertyModel> ownerProperties,
  }) async {
    try {
      final excelFileContent = generateOwnerPortfolioCsv(
        owner: owner,
        ownerProperties: ownerProperties,
      );

      final safeOwnerName = owner.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final timeStamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'Owner_${safeOwnerName}_Portfolio_$timeStamp.csv';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(excelFileContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv', name: fileName)],
          subject: 'Owner Portfolio: ${owner.name}',
          text: 'Owner portfolio report with ${ownerProperties.length} properties for ${owner.name}.',
        ),
      );

      return file.path;
    } catch (e) {
      debugPrint('Error exporting owner portfolio to Excel: $e');
      return null;
    }
  }

  /// Generate an Excel-compliant CSV String with UTF-8 BOM for the full Owners Directory.
  static String generateOwnersDirectoryCsv({
    required List<OwnerModel> owners,
    required List<PropertyModel> allProperties,
  }) {
    final List<List<dynamic>> rows = [];

    rows.add([
      'Owner ID',
      'Full Name',
      'Primary Phone',
      'Secondary Phone',
      'Email Address',
      'Address',
      'KYC ID Type',
      'KYC ID Number',
      'Properties Count',
      'Confidential Notes',
      'Registered Date',
    ]);

    for (final o in owners) {
      final count = allProperties.where((p) => p.ownerId == o.id || (p.ownerPhonePrimary == o.phonePrimary && o.phonePrimary.isNotEmpty)).length;
      rows.add([
        o.id,
        o.name,
        o.phonePrimary,
        o.phoneSecondary,
        o.email,
        o.address,
        o.idType,
        o.idNumber,
        count > 0 ? count : o.propertyCount,
        o.notes,
        o.createdAt != null ? DateFormat('yyyy-MM-dd').format(o.createdAt!) : '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return '\uFEFF$csvData';
  }

  /// Export the full Owners Directory to an Excel-compliant CSV.
  static Future<String?> exportOwnersDirectoryToExcel({
    required List<OwnerModel> owners,
    required List<PropertyModel> allProperties,
  }) async {
    try {
      final excelFileContent = generateOwnersDirectoryCsv(
        owners: owners,
        allProperties: allProperties,
      );

      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Owners_Directory_$timeStamp.csv';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(excelFileContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv', name: fileName)],
          subject: 'PropConnect Owners Directory',
          text: 'Exported ${owners.length} registered property owners.',
        ),
      );

      return file.path;
    } catch (e) {
      debugPrint('Error exporting owners directory to Excel: $e');
      return null;
    }
  }
}
