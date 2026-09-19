import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';
import { Owner } from './owner.model';

export class Property extends Model {
  declare id: number;
  declare propertyCode: string;
  declare title: string;
  declare description: string;
  declare location: string;
  declare price: string;
  declare bhk: string;
  declare type: string; // 'Sale' | 'Rent' | 'Lease'
  declare purpose: string; // 'Sale' | 'Rent' | 'Lease'
  declare propertyType: string; // 'Apartment' | 'Villa' | 'Plot' | 'Commercial' | 'Office' | 'Shop' | 'Warehouse'
  declare areaSqft: number;
  declare builtUpArea: number;
  declare carpetArea: number;
  declare status: string; // 'Available' | 'Reserved' | 'Under Negotiation' | 'Token Done' | 'Sold' | 'Rented'
  declare isPublic: boolean;
  declare agencyId: number;
  declare agencyName: string;
  declare brokerName: string;
  declare bathrooms: number;
  declare balcony: number;
  declare parking: number;
  declare furnishedStatus: string; // 'Unfurnished' | 'Semi-Furnished' | 'Fully Furnished'
  declare propertyAge: string;
  declare maintenanceCharges: string;
  declare securityDeposit: string;
  declare negotiablePrice: string;

  // Location Hierarchy
  declare country: string;
  declare state: string;
  declare city: string;
  declare area: string;
  declare address: string;
  declare googleMapUrl: string;
  declare latitude: number;
  declare longitude: number;

  // Owner Information & Privacy
  declare ownerId: number | null;
  declare ownerName: string;
  declare ownerPhonePrimary: string;
  declare ownerPhoneSecondary: string;
  declare ownerEmail: string;
  declare ownerAddress: string;
  declare ownerKycDocs: string[];
  declare internalNotes: string;

  // Media & Documents
  declare amenities: string[];
  declare images: string[];
  declare floorPlans: string[];
  declare videos: string[];
  declare documents: string[];

  declare readonly createdAt: Date;
  declare readonly updatedAt: Date;
}

Property.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    propertyCode: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
    location: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    price: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    bhk: {
      type: DataTypes.STRING,
      defaultValue: '2 BHK',
    },
    type: {
      type: DataTypes.STRING,
      defaultValue: 'Sale',
    },
    purpose: {
      type: DataTypes.STRING,
      defaultValue: 'Sale',
    },
    propertyType: {
      type: DataTypes.STRING,
      defaultValue: 'Apartment',
    },
    areaSqft: {
      type: DataTypes.FLOAT,
      defaultValue: 1000.0,
    },
    builtUpArea: {
      type: DataTypes.FLOAT,
      defaultValue: 1000.0,
    },
    carpetArea: {
      type: DataTypes.FLOAT,
      defaultValue: 850.0,
    },
    status: {
      type: DataTypes.STRING,
      defaultValue: 'Available',
    },
    isPublic: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    agencyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    agencyName: {
      type: DataTypes.STRING,
      defaultValue: 'Sunrise Properties',
    },
    brokerName: {
      type: DataTypes.STRING,
      defaultValue: 'Om Shivam',
    },
    bathrooms: {
      type: DataTypes.INTEGER,
      defaultValue: 2,
    },
    balcony: {
      type: DataTypes.INTEGER,
      defaultValue: 1,
    },
    parking: {
      type: DataTypes.INTEGER,
      defaultValue: 1,
    },
    furnishedStatus: {
      type: DataTypes.STRING,
      defaultValue: 'Unfurnished',
    },
    propertyAge: {
      type: DataTypes.STRING,
      defaultValue: '1-5 Years',
    },
    maintenanceCharges: {
      type: DataTypes.STRING,
      defaultValue: '₹0',
    },
    securityDeposit: {
      type: DataTypes.STRING,
      defaultValue: '₹0',
    },
    negotiablePrice: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    country: {
      type: DataTypes.STRING,
      defaultValue: 'India',
    },
    state: {
      type: DataTypes.STRING,
      defaultValue: 'Maharashtra',
    },
    city: {
      type: DataTypes.STRING,
      defaultValue: 'Mumbai',
    },
    area: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    address: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    googleMapUrl: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    latitude: {
      type: DataTypes.FLOAT,
      defaultValue: 19.076,
    },
    longitude: {
      type: DataTypes.FLOAT,
      defaultValue: 72.8777,
    },
    ownerId: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    ownerName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    ownerPhonePrimary: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    ownerPhoneSecondary: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    ownerEmail: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    ownerAddress: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    ownerKycDocs: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
    internalNotes: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
    amenities: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
    images: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
    floorPlans: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
    videos: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
    documents: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
  },
  {
    sequelize,
    tableName: 'properties',
  }
);

Owner.hasMany(Property, { foreignKey: 'ownerId', as: 'properties' });
Property.belongsTo(Owner, { foreignKey: 'ownerId', as: 'owner' });

