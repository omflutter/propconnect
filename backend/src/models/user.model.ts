import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/database';
import { Agency } from './agency.model';

export class User extends Model {
  declare public id: number;
  declare public name: string;
  declare public email: string;
  declare public password: string;
  declare public phone: string;
  declare public role: 'super_admin' | 'agency_admin' | 'broker';
  declare public adminRoleTitle: string;
  declare public permissions: Record<string, string[]>;
  declare public agencyId: number | null;
  declare public agency?: Agency;
  declare public status: 'Active' | 'Suspended';
  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

User.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    name: {
      type: DataTypes.STRING(128),
      allowNull: false,
    },
    email: {
      type: DataTypes.STRING(128),
      allowNull: false,
      unique: true,
    },
    password: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    phone: {
      type: DataTypes.STRING(32),
      allowNull: true,
    },
    role: {
      type: DataTypes.STRING(32),
      allowNull: false,
      defaultValue: 'broker',
    },
    adminRoleTitle: {
      type: DataTypes.STRING(128),
      allowNull: true,
      defaultValue: 'Super Admin (Full Access)',
    },
    permissions: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    agencyId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: Agency,
        key: 'id',
      },
    },
    status: {
      type: DataTypes.STRING(32),
      defaultValue: 'Active',
    },
  },
  {
    tableName: 'users',
    sequelize,
  }
);

User.belongsTo(Agency, { foreignKey: 'agencyId', as: 'agency' });
Agency.hasMany(User, { foreignKey: 'agencyId', as: 'users' });
