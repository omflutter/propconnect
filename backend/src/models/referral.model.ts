import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class Referral extends Model {
  declare public id: number;
  declare public referrerAgencyId: number;
  declare public referredAgencyId: number;
  declare public referralCode: string;
  declare public coinsEarned: number;
  declare public status: 'Completed' | 'Pending';
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

Referral.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    referrerAgencyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    referredAgencyId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    referralCode: {
      type: DataTypes.STRING(64),
      allowNull: false,
    },
    coinsEarned: {
      type: DataTypes.INTEGER,
      defaultValue: 1000,
    },
    status: {
      type: DataTypes.STRING(32),
      defaultValue: 'Completed',
    },
  },
  {
    tableName: 'referrals',
    sequelize,
  }
);
