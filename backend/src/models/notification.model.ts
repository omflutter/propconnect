import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';
import { User } from './user.model';
import { Agency } from './agency.model';

export class Notification extends Model {
  declare public id: number;
  declare public notificationCode: string;
  declare public userId: number;
  declare public agencyId: number | null;
  declare public title: string;
  declare public message: string;
  declare public type: 'collaboration' | 'deal' | 'commission' | 'subscription' | 'system';
  declare public actionRoute: string | null;
  declare public metadata: Record<string, any> | null;
  declare public isRead: boolean;
  declare public readAt: Date | null;
  declare public channels: string;
  declare public fcmMessageId: string | null;
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

Notification.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    notificationCode: {
      type: DataTypes.STRING(32),
      allowNull: false,
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: User,
        key: 'id',
      },
    },
    agencyId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: Agency,
        key: 'id',
      },
    },
    title: {
      type: DataTypes.STRING(160),
      allowNull: false,
    },
    message: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    type: {
      type: DataTypes.ENUM('collaboration', 'deal', 'commission', 'subscription', 'system'),
      defaultValue: 'system',
    },
    actionRoute: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    metadata: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    isRead: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    readAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    channels: {
      type: DataTypes.STRING(64),
      defaultValue: 'in_app',
    },
    fcmMessageId: {
      type: DataTypes.STRING(128),
      allowNull: true,
    },
  },
  {
    tableName: 'notifications',
    sequelize,
  }
);

Notification.belongsTo(User, { foreignKey: 'userId', as: 'recipient' });
Notification.belongsTo(Agency, { foreignKey: 'agencyId', as: 'agency' });
User.hasMany(Notification, { foreignKey: 'userId', as: 'notifications' });
