import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';

export class PlatformConfig extends Model {
  declare public id: number;
  declare public platformFeePercent: number;
  declare public basicTierFee: number;
  declare public proTierFee: number;
  declare public enterpriseTierFee: number;
  declare public maintenanceMode: boolean;
  
  // Payment Gateway Credentials
  declare public razorpayKeyId: string;
  declare public razorpayKeySecret: string;
  declare public razorpayWebhookSecret: string;
  declare public stripePublishableKey: string;
  declare public stripeSecretKey: string;
  declare public stripeWebhookSecret: string;

  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

PlatformConfig.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    platformFeePercent: {
      type: DataTypes.FLOAT,
      defaultValue: 2.5,
    },
    basicTierFee: {
      type: DataTypes.INTEGER,
      defaultValue: 2999,
    },
    proTierFee: {
      type: DataTypes.INTEGER,
      defaultValue: 5999,
    },
    enterpriseTierFee: {
      type: DataTypes.INTEGER,
      defaultValue: 14999,
    },
    maintenanceMode: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    razorpayKeyId: {
      type: DataTypes.STRING,
      defaultValue: 'rzp_live_89123849102934',
    },
    razorpayKeySecret: {
      type: DataTypes.STRING,
      defaultValue: 'rzp_sec_99182391028349',
    },
    razorpayWebhookSecret: {
      type: DataTypes.STRING,
      defaultValue: 'whsec_rzp_live_109283',
    },
    stripePublishableKey: {
      type: DataTypes.STRING,
      defaultValue: 'pk_live_51M091823981023984',
    },
    stripeSecretKey: {
      type: DataTypes.STRING,
      defaultValue: 'sk_live_51M091823981023984_sec_99182',
    },
    stripeWebhookSecret: {
      type: DataTypes.STRING,
      defaultValue: 'whsec_stripe_live_991823',
    },
  },
  {
    tableName: 'platform_configs',
    sequelize,
  }
);
