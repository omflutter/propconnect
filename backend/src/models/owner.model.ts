import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class Owner extends Model {
  declare public id: number;
  declare public agencyId: number;
  declare public name: string;
  declare public phonePrimary: string;
  declare public phoneSecondary: string;
  declare public email: string;
  declare public address: string;
  declare public idType: string;
  declare public idNumber: string;
  declare public notes: string;
  declare public kycDocs: string[];
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

Owner.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    agencyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    name: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    phonePrimary: {
      type: DataTypes.STRING(32),
      allowNull: false,
    },
    phoneSecondary: {
      type: DataTypes.STRING(32),
      allowNull: true,
      defaultValue: '',
    },
    email: {
      type: DataTypes.STRING(128),
      allowNull: true,
      defaultValue: '',
    },
    address: {
      type: DataTypes.TEXT,
      allowNull: true,
      defaultValue: '',
    },
    idType: {
      type: DataTypes.STRING(64),
      allowNull: true,
      defaultValue: 'Aadhaar',
    },
    idNumber: {
      type: DataTypes.STRING(64),
      allowNull: true,
      defaultValue: '',
    },
    notes: {
      type: DataTypes.TEXT,
      allowNull: true,
      defaultValue: '',
    },
    kycDocs: {
      type: DataTypes.JSON,
      allowNull: true,
      defaultValue: [],
    },
  },
  {
    sequelize,
    tableName: 'owners',
    timestamps: true,
  }
);
