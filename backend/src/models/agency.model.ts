import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class Agency extends Model {
  declare public id: number;
  declare public agencyCode: string;
  declare public name: string;
  declare public reraNumber: string;
  declare public location: string;
  declare public address: string;
  declare public adminName: string;
  declare public adminEmail: string;
  declare public adminPhone: string;
  declare public subscriptionTier: string;
  declare public userQuota: number;
  declare public propertiesCount: number;
  declare public dealsCount: number;
  declare public status: 'Active' | 'Pending' | 'Suspended';
  declare public referralCode: string | null;
  declare public coinsBalance: number;
  declare public referredByAgencyId: number | null;
  declare public referralCount: number;
  declare public pincode: string | null;
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

Agency.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    agencyCode: {
      type: DataTypes.STRING(32),
      allowNull: false,
      unique: true,
    },
    name: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    reraNumber: {
      type: DataTypes.STRING(64),
      allowNull: true,
    },
    location: {
      type: DataTypes.STRING(128),
      allowNull: false,
      defaultValue: 'Mumbai',
    },
    address: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    adminName: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    adminEmail: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    adminPhone: {
      type: DataTypes.STRING(32),
      allowNull: true,
    },
    subscriptionTier: {
      type: DataTypes.STRING(64),
      defaultValue: 'Pro (₹5,999/mo)',
    },
    userQuota: {
      type: DataTypes.INTEGER,
      defaultValue: 10,
    },
    propertiesCount: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    dealsCount: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    status: {
      type: DataTypes.STRING(32),
      defaultValue: 'Active',
    },
    referralCode: {
      type: DataTypes.STRING(64),
      allowNull: true,
      unique: true,
    },
    coinsBalance: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    referredByAgencyId: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    referralCount: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    pincode: {
      type: DataTypes.STRING(16),
      allowNull: true,
    },
  },
  {
    tableName: 'agencies',
    sequelize,
  }
);
