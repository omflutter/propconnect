import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class CollaborationRequest extends Model {
  declare id: number;
  declare requestCode: string;
  declare propertyId: number;
  declare propertyName: string;
  declare propertyLocation: string;
  declare propertyPrice: string;

  // Listing Agency / Broker (Broker A)
  declare targetAgencyId: number;
  declare targetAgencyName: string;
  declare targetBrokerId: number;
  declare targetBrokerName: string;

  // Requesting Agency / Broker (Broker B)
  declare requestingAgencyId: number;
  declare requestingAgencyName: string;
  declare requestingBrokerId: number;
  declare requestingBrokerName: string;

  // Collaboration Details
  declare clientRequirement: string;
  declare expectedBudget: string;
  declare remarks: string;
  declare status: string; // 'Pending' | 'Approved' | 'Rejected' | 'Cancelled'
  declare dealId: number | null;

  declare readonly createdAt: Date;
  declare readonly updatedAt: Date;
}

CollaborationRequest.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    requestCode: {
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
    propertyLocation: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    propertyPrice: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    targetAgencyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    targetAgencyName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    targetBrokerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    targetBrokerName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    requestingAgencyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    requestingAgencyName: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    requestingBrokerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    requestingBrokerName: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    clientRequirement: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    expectedBudget: {
      type: DataTypes.STRING,
      defaultValue: '',
    },
    remarks: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
    status: {
      type: DataTypes.STRING,
      defaultValue: 'Pending',
    },
    dealId: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
  },
  {
    sequelize,
    tableName: 'collaboration_requests',
  }
);
