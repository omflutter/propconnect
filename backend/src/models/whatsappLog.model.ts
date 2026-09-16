import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class WhatsAppLog extends Model {
  declare public id: number;
  declare public messageCode: string;
  declare public interaktId: string | null;
  declare public recipient: string;
  declare public countryCode: string;
  declare public event: string;
  declare public templateName: string | null;
  declare public status: 'Sent' | 'Delivered' | 'Read' | 'Failed';
  declare public payload: Record<string, any>;
  declare public errorMessage: string | null;
  declare public sentAt: Date;
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

WhatsAppLog.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    messageCode: {
      type: DataTypes.STRING(32),
      allowNull: false,
    },
    interaktId: {
      type: DataTypes.STRING(128),
      allowNull: true,
    },
    recipient: {
      type: DataTypes.STRING(64),
      allowNull: false,
    },
    countryCode: {
      type: DataTypes.STRING(8),
      defaultValue: '+91',
    },
    event: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    templateName: {
      type: DataTypes.STRING(128),
      allowNull: true,
    },
    status: {
      type: DataTypes.ENUM('Sent', 'Delivered', 'Read', 'Failed'),
      defaultValue: 'Sent',
    },
    payload: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    errorMessage: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    sentAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: 'whatsapp_logs',
    sequelize,
  }
);
