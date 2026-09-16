import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class Commission extends Model {
  declare id: number;
  declare commissionCode: string;
  declare dealId: number;
  declare propertyId: number;
  declare propertyName: string;

  declare dealValue: string;
  declare commissionType: string; // 'Percentage' | 'Flat'
  declare commissionRate: number;
  declare totalCommission: string;

  // Split Breakdown (PRD Section 12 Example)
  declare brokerASharePct: number;
  declare brokerBSharePct: number;
  declare brokerAAmount: string;
  declare brokerBAmount: string;

  declare brokerAId: number;
  declare brokerAName: string;
  declare brokerBId: number;
  declare brokerBName: string;

  declare agencyAId: number;
  declare agencyAName: string;
  declare agencyBId: number;
  declare agencyBName: string;

  declare status: string; // 'Pending' | 'Partially Paid' | 'Paid' | 'Cancelled'

  declare readonly createdAt: Date;
  declare readonly updatedAt: Date;
}

Commission.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    commissionCode: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    dealId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    propertyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    propertyName: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    dealValue: {
      type: DataTypes.STRING,
      defaultValue: '₹1,00,00,000',
    },
    commissionType: {
      type: DataTypes.STRING,
      defaultValue: 'Percentage',
    },
    commissionRate: {
      type: DataTypes.FLOAT,
      defaultValue: 2.0,
    },
    totalCommission: {
      type: DataTypes.STRING,
      defaultValue: '₹2,00,000',
    },
    brokerASharePct: {
      type: DataTypes.FLOAT,
      defaultValue: 50.0,
    },
    brokerBSharePct: {
      type: DataTypes.FLOAT,
      defaultValue: 50.0,
    },
    brokerAAmount: {
      type: DataTypes.STRING,
      defaultValue: '₹1,00,000',
    },
    brokerBAmount: {
      type: DataTypes.STRING,
      defaultValue: '₹1,00,000',
    },
    brokerAId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    brokerAName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    brokerBId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    brokerBName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    agencyAId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    agencyAName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    agencyBId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    agencyBName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    status: {
      type: DataTypes.STRING,
      defaultValue: 'Pending',
    },
  },
  {
    sequelize,
    tableName: 'commissions',
  }
);
