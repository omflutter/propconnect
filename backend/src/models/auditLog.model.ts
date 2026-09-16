import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class AuditLog extends Model {
  declare public id: number;
  declare public logCode: string;
  declare public actorName: string;
  declare public actorRole: string;
  declare public action: string;
  declare public target: string;
  declare public ipAddress: string;
  declare public status: 'Success' | 'Warning' | 'Error';
  declare public details: Record<string, any>;
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

AuditLog.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    logCode: {
      type: DataTypes.STRING(32),
      allowNull: false,
    },
    actorName: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    actorRole: {
      type: DataTypes.STRING(64),
      allowNull: false,
    },
    action: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    target: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    ipAddress: {
      type: DataTypes.STRING(64),
      defaultValue: '127.0.0.1',
    },
    status: {
      type: DataTypes.ENUM('Success', 'Warning', 'Error'),
      defaultValue: 'Success',
    },
    details: {
      type: DataTypes.JSON,
      allowNull: true,
    },
  },
  {
    tableName: 'audit_logs',
    sequelize,
  }
);
