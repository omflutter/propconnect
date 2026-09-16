import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class Deal extends Model {
  declare id: number;
  declare dealCode: string;
  declare propertyId: number;
  declare propertyName: string;

  // Property Owner (Broker A)
  declare agencyAId: number;
  declare agencyAName: string;
  declare brokerAId: number;
  declare brokerAName: string;

  // Client Owner (Broker B)
  declare agencyBId: number;
  declare agencyBName: string;
  declare brokerBId: number;
  declare brokerBName: string;

  // Client Details (Lead Ownership: Broker B controls, Broker A cannot access phone/email)
  declare clientName: string;
  declare clientPhone: string;
  declare clientEmail: string;
  declare clientRequirement: string;
  declare expectedBudget: string;

  // Deal Lifecycle & Financials
  declare status: string; // 12 Stages per PRD Section 9
  declare dealValue: string;
  declare commissionId: number;
  declare remarks: string;
  declare auditHistory: Array<{
    status: string;
    timestamp: string;
    updatedBy?: string;
    remarks?: string;
  }>;

  declare readonly createdAt: Date;
  declare readonly updatedAt: Date;
}

Deal.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    dealCode: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    propertyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    propertyName: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    agencyAId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    agencyAName: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'Sunrise Properties',
    },
    brokerAId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    brokerAName: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'Om Shivam',
    },
    agencyBId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    agencyBName: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'Partner Realty',
    },
    brokerBId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 2,
    },
    brokerBName: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'Rahul Singh',
    },
    clientName: {
      type: DataTypes.STRING,
      defaultValue: 'Confidential Client',
    },
    clientPhone: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    clientEmail: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    clientRequirement: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
    expectedBudget: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    status: {
      type: DataTypes.STRING,
      defaultValue: 'Lead Assigned',
    },
    dealValue: {
      type: DataTypes.STRING,
      defaultValue: '₹1.0 Cr',
    },
    commissionId: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    remarks: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
    auditHistory: {
      type: DataTypes.JSON,
      defaultValue: [],
    },
  },
  {
    sequelize,
    tableName: 'deals',
  }
);
