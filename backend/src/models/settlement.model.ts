import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class Settlement extends Model {
  declare id: number;
  declare settlementCode: string;
  declare commissionId: number;
  declare dealId: number;
  declare propertyName: string;

  declare agencyId: number;
  declare agencyName: string;
  declare brokerId: number;
  declare brokerName: string;

  // PRD Section 13 Settlement Tracking Fields
  declare dueDate: string;
  declare amountReceived: string;
  declare amountPending: string;
  declare paymentMethod: string; // 'NEFT / Bank Transfer' | 'UPI' | 'Cheque' | 'Cash'
  declare referenceNumber: string;
  declare settlementDate: string;
  declare status: string; // 'Settled' | 'Partially Settled' | 'Pending'
  declare remarks: string;

  declare readonly createdAt: Date;
  declare readonly updatedAt: Date;
}

Settlement.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    settlementCode: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    commissionId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    dealId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    propertyName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    agencyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    agencyName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    brokerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    brokerName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    dueDate: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    amountReceived: {
      type: DataTypes.STRING,
      defaultValue: '₹0',
    },
    amountPending: {
      type: DataTypes.STRING,
      defaultValue: '₹0',
    },
    paymentMethod: {
      type: DataTypes.STRING,
      defaultValue: 'NEFT / Bank Transfer',
    },
    referenceNumber: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    settlementDate: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    status: {
      type: DataTypes.STRING,
      defaultValue: 'Pending',
    },
    remarks: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
  },
  {
    sequelize,
    tableName: 'settlements',
  }
);
