import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class Message extends Model {
  declare public id: number;
  declare public conversationId: string;
  declare public senderId: string;
  declare public senderName: string;
  declare public receiverId: string;
  declare public receiverName: string;
  declare public messageText: string;
  declare public attachmentType: string; // 'text' | 'property' | 'image' | 'location' | 'document'
  declare public attachmentData: object | null;
  declare public isRead: boolean;
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

Message.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    conversationId: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    senderId: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    senderName: {
      type: DataTypes.STRING,
      defaultValue: 'Broker',
    },
    receiverId: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    receiverName: {
      type: DataTypes.STRING,
      defaultValue: 'Partner Broker',
    },
    messageText: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    attachmentType: {
      type: DataTypes.STRING,
      defaultValue: 'text',
    },
    attachmentData: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    isRead: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    sequelize,
    tableName: 'messages',
  }
);
