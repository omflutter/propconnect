import fs from 'fs';
import path from 'path';

export interface MemoryAgency {
  id: number;
  agencyCode: string;
  name: string;
  reraNumber: string;
  location: string;
  address: string;
  adminName: string;
  adminEmail: string;
  adminPhone: string;
  subscriptionTier: string;
  userQuota: number;
  propertiesCount: number;
  dealsCount: number;
  status: 'Active' | 'Pending' | 'Suspended';
  createdAt: string;
}

export interface MemoryUser {
  id: number;
  name: string;
  email: string;
  password?: string;
  phone: string;
  role: 'super_admin' | 'agency_admin' | 'broker';
  adminRoleTitle?: string;
  permissions?: any;
  agencyId: number | null;
  agency?: MemoryAgency | null;
  status: 'Active' | 'Suspended';
  createdAt: string;
}

export interface MemoryAuditLog {
  id: number;
  logCode: string;
  actorName: string;
  actorRole: string;
  action: string;
  target: string;
  ipAddress: string;
  status: 'Success' | 'Warning' | 'Error';
  details?: Record<string, any>;
  createdAt: string;
}

export interface MemoryProperty {
  id: number;
  propertyCode: string;
  title: string;
  location: string;
  price: string;
  bhk: string;
  type: string; // 'Sale' | 'Rent'
  propertyType: string; // 'Apartment' | 'Villa' | 'Office' | 'Plot'
  areaSqft: number;
  status: string; // 'Available' | 'Sold' | 'Rented'
  isPublic: boolean;
  agencyId: number;
  agencyName: string;
  brokerName: string;
  bathrooms: number;
  balcony: number;
  parking: number;
  furnishedStatus: string;
  maintenanceCharges: string;
  amenities: string[];
  images: string[];
  createdAt: string;
}

class MemoryStore {
  private filePath: string = path.join(process.env.NODE_ENV === 'production' ? '/tmp' : process.cwd(), 'propconnect_store.json');

  private agencies: MemoryAgency[] = [
    {
      id: 1,
      agencyCode: 'AG-001',
      name: 'Sunrise Properties',
      reraNumber: 'PRM/KA/RERA/1251/310/PR/171015/000456',
      location: 'Mumbai',
      address: 'Suite 402, Bandra Kurla Complex, Mumbai',
      adminName: 'Om Shivam',
      adminEmail: 'om@propconnect.in',
      adminPhone: '+91 98765 43210',
      subscriptionTier: 'Enterprise (₹14,999/mo)',
      userQuota: 25,
      propertiesCount: 45,
      dealsCount: 12,
      status: 'Active',
      createdAt: new Date().toISOString(),
    },
    {
      id: 2,
      agencyCode: 'AG-002',
      name: 'Metro Realty India',
      reraNumber: 'PRM/DL/RERA/2210/405/PR/180211/000789',
      location: 'Delhi NCR',
      address: 'Cyber City, Tower B, Gurugram',
      adminName: 'Rajesh Kumar',
      adminEmail: 'rajesh@metrorealty.in',
      adminPhone: '+91 98111 22233',
      subscriptionTier: 'Pro (₹5,999/mo)',
      userQuota: 15,
      propertiesCount: 128,
      dealsCount: 34,
      status: 'Active',
      createdAt: new Date().toISOString(),
    },
    {
      id: 3,
      agencyCode: 'AG-003',
      name: 'Bangalore Estates',
      reraNumber: 'PRM/KA/RERA/3340/512/PR/190504/000999',
      location: 'Bangalore',
      address: '100 Feet Road, Indiranagar, Bangalore',
      adminName: 'Priya Sharma',
      adminEmail: 'priya@bangaloreestates.in',
      adminPhone: '+91 98450 12345',
      subscriptionTier: 'Basic (₹2,999/mo)',
      userQuota: 5,
      propertiesCount: 12,
      dealsCount: 3,
      status: 'Pending',
      createdAt: new Date().toISOString(),
    },
  ];

  private users: MemoryUser[] = [
    {
      id: 1,
      name: 'Platform Super Admin',
      email: 'admin@propconnect.in',
      password: 'admin123',
      phone: '+91 99999 00000',
      role: 'super_admin',
      adminRoleTitle: 'Super Admin (Full Access)',
      permissions: {
        agencies: ['view', 'edit', 'delete'],
        brokers: ['view', 'edit', 'delete'],
        properties: ['view', 'edit', 'delete'],
        deals: ['view', 'edit', 'delete'],
        finance: ['view', 'edit', 'delete'],
        gateways: ['view', 'edit', 'delete'],
        whatsapp: ['view', 'edit', 'delete'],
        settings: ['view', 'edit', 'delete'],
      },
      agencyId: null,
      status: 'Active',
      createdAt: new Date().toISOString(),
    },
    {
      id: 2,
      name: 'Vikram Malhotra',
      email: 'vikram.m@propconnect.in',
      password: 'admin123',
      phone: '+91 98765 11111',
      role: 'super_admin',
      adminRoleTitle: 'Operations & Onboarding Manager',
      permissions: {
        agencies: ['view', 'edit', 'delete'],
        brokers: ['view', 'edit'],
        properties: ['view', 'edit'],
        deals: ['view'],
      },
      agencyId: null,
      status: 'Active',
      createdAt: new Date().toISOString(),
    },
    {
      id: 3,
      name: 'Sneha Kapoor',
      email: 'sneha.k@propconnect.in',
      password: 'admin123',
      phone: '+91 98765 22222',
      role: 'super_admin',
      adminRoleTitle: 'Finance & Payouts Lead',
      permissions: {
        finance: ['view', 'edit', 'delete'],
        gateways: ['view', 'edit'],
        agencies: ['view'],
      },
      agencyId: null,
      status: 'Active',
      createdAt: new Date().toISOString(),
    },
    {
      id: 4,
      name: 'Om Shivam',
      email: 'om@propconnect.in',
      password: 'agency123',
      phone: '+91 98765 43210',
      role: 'agency_admin',
      adminRoleTitle: 'Agency Tenant Admin',
      agencyId: 1,
      status: 'Active',
      createdAt: new Date().toISOString(),
    },
    {
      id: 5,
      name: 'Broker User',
      email: 'broker@propconnect.in',
      password: 'broker123',
      phone: '+91 98222 33344',
      role: 'broker',
      adminRoleTitle: 'Registered Broker',
      agencyId: 1,
      status: 'Active',
      createdAt: new Date().toISOString(),
    },
  ];

  private auditLogs: MemoryAuditLog[] = [
    {
      id: 1,
      logCode: 'LOG-7001',
      actorName: 'Om Shivam',
      actorRole: 'Super Admin',
      action: 'Property Inventory Created',
      target: 'Sea Face Villa (PR-104)',
      ipAddress: '103.22.180.4',
      status: 'Success',
      details: { propertyId: 'PR-104', location: 'Bandra West, Mumbai', price: '₹4.5 Cr' },
      createdAt: new Date().toISOString(),
    },
  ];

  private properties: MemoryProperty[] = [
    {
      id: 101,
      propertyCode: 'PR-101',
      title: 'Sea Face 3BHK Luxury Villa',
      location: 'Bandra West, Mumbai',
      price: '₹4.5 Cr',
      bhk: '3 BHK',
      type: 'Sale',
      propertyType: 'Villa',
      areaSqft: 2200,
      status: 'Available',
      isPublic: true,
      agencyId: 1,
      agencyName: 'Sunrise Properties',
      brokerName: 'Om Shivam',
      bathrooms: 3,
      balcony: 2,
      parking: 2,
      furnishedStatus: 'Fully Furnished',
      maintenanceCharges: '₹8,500/mo',
      amenities: ['Sea View', 'Gym', 'Swimming Pool', '24/7 Security', 'Lift'],
      images: [],
      createdAt: new Date().toISOString(),
    },
    {
      id: 102,
      propertyCode: 'PR-102',
      title: 'Modern 2BHK Apartment in BKC',
      location: 'BKC, Mumbai',
      price: '₹2.8 Cr',
      bhk: '2 BHK',
      type: 'Sale',
      propertyType: 'Apartment',
      areaSqft: 1250,
      status: 'Available',
      isPublic: false,
      agencyId: 1,
      agencyName: 'Sunrise Properties',
      brokerName: 'Om Shivam',
      bathrooms: 2,
      balcony: 1,
      parking: 1,
      furnishedStatus: 'Semi-Furnished',
      maintenanceCharges: '₹5,000/mo',
      amenities: ['Power Backup', 'Gym', 'Lift', 'Parking'],
      images: [],
      createdAt: new Date().toISOString(),
    },
  ];

  private config = {
    platformFeePercent: 2.5,
    basicTierFee: 2999,
    proTierFee: 5999,
    enterpriseTierFee: 14999,
    maintenanceMode: false,
  };

  constructor() {
    this.loadFromDisk();
  }

  private loadFromDisk() {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf-8');
        const data = JSON.parse(raw);
        if (data.agencies) this.agencies = data.agencies;
        if (data.users) this.users = data.users;
        if (data.auditLogs) this.auditLogs = data.auditLogs;
        if (data.properties) this.properties = data.properties;
        if (data.config) this.config = data.config;
      }
    } catch (err) {
      console.warn('[Store File Load Notice]', err);
    }
  }

  private persist() {
    try {
      const data = {
        agencies: this.agencies,
        users: this.users,
        auditLogs: this.auditLogs,
        properties: this.properties,
        config: this.config,
      };
      fs.writeFileSync(this.filePath, JSON.stringify(data, null, 2), 'utf-8');
    } catch (err) {
      console.warn('[Store File Save Notice]', err);
    }
  }

  // Agency Methods
  public getAgencies(status?: string, search?: string): MemoryAgency[] {
    let list = [...this.agencies];
    if (status && status !== 'All') {
      list = list.filter((a) => a.status === status);
    }
    if (search) {
      const q = search.toLowerCase();
      list = list.filter(
        (a) =>
          a.name.toLowerCase().includes(q) ||
          a.location.toLowerCase().includes(q) ||
          a.adminName.toLowerCase().includes(q) ||
          a.agencyCode.toLowerCase().includes(q)
      );
    }
    return list;
  }

  public getAgencyById(id: number): MemoryAgency | undefined {
    return this.agencies.find((a) => a.id === id);
  }

  public createAgency(data: any): MemoryAgency {
    const nextId = this.agencies.length > 0 ? Math.max(...this.agencies.map((a) => a.id)) + 1 : 1;
    const agencyCode = `AG-${String(nextId).padStart(3, '0')}`;

    const newAgency: MemoryAgency = {
      id: nextId,
      agencyCode,
      name: data.name,
      reraNumber: data.reraNumber || '',
      location: data.location || 'Pan India',
      address: data.address || '',
      adminName: data.adminName,
      adminEmail: data.adminEmail,
      adminPhone: data.adminPhone || '',
      subscriptionTier: data.subscriptionTier || 'Pro (₹5,999/mo)',
      userQuota: data.userQuota ? parseInt(data.userQuota, 10) : 10,
      propertiesCount: 0,
      dealsCount: 0,
      status: 'Active',
      createdAt: new Date().toISOString(),
    };

    this.agencies.unshift(newAgency);

    const newUser: MemoryUser = {
      id: this.users.length + 1,
      name: data.adminName,
      email: data.adminEmail,
      password: data.password || 'agency123',
      phone: data.adminPhone || '',
      role: 'agency_admin',
      adminRoleTitle: 'Agency Tenant Admin',
      agencyId: newAgency.id,
      agency: newAgency,
      status: 'Active',
      createdAt: new Date().toISOString(),
    };
    this.users.unshift(newUser);

    this.recordAuditLog('Super Admin', 'Super Admin', 'Agency Onboarded', `${newAgency.name} (${newAgency.agencyCode})`);
    this.persist();

    return newAgency;
  }

  public updateAgency(id: number, data: any): MemoryAgency | undefined {
    const agency = this.getAgencyById(id);
    if (!agency) return undefined;

    if (data.name) agency.name = data.name;
    if (data.reraNumber !== undefined) agency.reraNumber = data.reraNumber;
    if (data.location) agency.location = data.location;
    if (data.address !== undefined) agency.address = data.address;
    if (data.adminName) agency.adminName = data.adminName;
    if (data.adminEmail) agency.adminEmail = data.adminEmail;
    if (data.adminPhone !== undefined) agency.adminPhone = data.adminPhone;
    if (data.subscriptionTier) agency.subscriptionTier = data.subscriptionTier;
    if (data.userQuota !== undefined) agency.userQuota = parseInt(data.userQuota, 10);
    if (data.status) agency.status = data.status;

    this.persist();
    return agency;
  }

  public deleteAgency(id: number): boolean {
    const idx = this.agencies.findIndex((a) => a.id === id);
    if (idx !== -1) {
      this.agencies.splice(idx, 1);
      this.persist();
      return true;
    }
    return false;
  }

  public findUserByEmail(email: string): MemoryUser | undefined {
    if (!email) return undefined;
    const cleanEmail = email.trim().toLowerCase();
    return this.users.find((u) => u.email.trim().toLowerCase() === cleanEmail);
  }

  // Broker Methods (STRICTLY role === 'broker')
  public getBrokers(agencyId?: number, search?: string): MemoryUser[] {
    let list = this.users.filter((u) => u.role === 'broker');
    if (agencyId) {
      list = list.filter((u) => u.agencyId === Number(agencyId));
    }
    if (search) {
      const q = search.toLowerCase();
      list = list.filter((u) => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q));
    }
    return list;
  }

  public createBroker(data: any): MemoryUser {
    const nextId = this.users.length > 0 ? Math.max(...this.users.map((u) => u.id)) + 1 : 1;
    const agency = data.agencyId ? this.getAgencyById(Number(data.agencyId)) : null;

    const newBroker: MemoryUser = {
      id: nextId,
      name: data.name,
      email: data.email,
      password: data.password || 'broker123',
      phone: data.phone || '',
      role: 'broker',
      adminRoleTitle: 'Registered Broker',
      agencyId: data.agencyId ? Number(data.agencyId) : 1,
      agency: agency || null,
      status: 'Active',
      createdAt: new Date().toISOString(),
    };

    this.users.unshift(newBroker);
    this.recordAuditLog('Agency Admin', 'Agency Admin', 'Broker Onboarded', `${newBroker.name} (${newBroker.email})`);
    this.persist();

    return newBroker;
  }

  public updateBrokerStatus(id: number, status: 'Active' | 'Suspended'): MemoryUser | undefined {
    const user = this.users.find((u) => u.id === id);
    if (user) {
      user.status = status;
      this.recordAuditLog('Super Admin', 'Super Admin', `Broker Status ${status}`, `${user.name}`);
      this.persist();
    }
    return user;
  }

  public deleteBroker(id: number): boolean {
    const idx = this.users.findIndex((u) => u.id === id);
    if (idx !== -1) {
      this.users.splice(idx, 1);
      this.persist();
      return true;
    }
    return false;
  }

  // Admin Team Methods (STRICTLY role === 'super_admin')
  public getAdmins(): MemoryUser[] {
    return this.users.filter((u) => u.role === 'super_admin');
  }

  public createAdminMember(data: any): MemoryUser {
    const existing = this.users.find((u) => u.email.trim().toLowerCase() === data.email.trim().toLowerCase());
    if (existing) return existing;

    const nextId = data.id || (this.users.length > 0 ? Math.max(...this.users.map((u) => u.id)) + 1 : 1);
    const newAdmin: MemoryUser = {
      id: nextId,
      name: data.name,
      email: data.email,
      password: data.password || 'admin123',
      phone: data.phone || '',
      role: 'super_admin',
      adminRoleTitle: data.adminRoleTitle || 'Super Admin (Custom Role)',
      permissions: data.permissions || {},
      agencyId: null,
      status: data.status || 'Active',
      createdAt: new Date().toISOString(),
    };

    this.users.unshift(newAdmin);
    this.recordAuditLog('Super Admin', 'Super Admin', 'Admin Team Member Added', `${newAdmin.name} (${newAdmin.email})`);
    this.persist();

    return newAdmin;
  }

  // Audit Logs
  public getAuditLogs(status?: string, date?: string, search?: string): MemoryAuditLog[] {
    let list = [...this.auditLogs];
    if (status && status !== 'All') {
      list = list.filter((l) => l.status === status);
    }
    if (date && date !== 'All') {
      list = list.filter((l) => l.createdAt.startsWith(date));
    }
    if (search) {
      const q = search.toLowerCase();
      list = list.filter(
        (l) =>
          l.logCode.toLowerCase().includes(q) ||
          l.actorName.toLowerCase().includes(q) ||
          l.action.toLowerCase().includes(q) ||
          l.target.toLowerCase().includes(q)
      );
    }
    return list;
  }

  public recordAuditLog(
    actorName: string,
    actorRole: string,
    action: string,
    target: string,
    ipAddress: string = '103.22.180.4',
    status: 'Success' | 'Warning' | 'Error' = 'Success',
    details: Record<string, any> = {}
  ): MemoryAuditLog {
    const nextId = this.auditLogs.length + 1;
    const log: MemoryAuditLog = {
      id: nextId,
      logCode: `LOG-${7000 + nextId}`,
      actorName,
      actorRole,
      action,
      target,
      ipAddress,
      status,
      details,
      createdAt: new Date().toISOString(),
    };
    this.auditLogs.unshift(log);
    this.persist();
    return log;
  }

  // Config Methods
  public getConfig() {
    return this.config;
  }

  public updateConfig(data: any) {
    if (data.platformFeePercent !== undefined) this.config.platformFeePercent = parseFloat(data.platformFeePercent);
    if (data.basicTierFee !== undefined) this.config.basicTierFee = parseInt(data.basicTierFee, 10);
    if (data.proTierFee !== undefined) this.config.proTierFee = parseInt(data.proTierFee, 10);
    if (data.enterpriseTierFee !== undefined) this.config.enterpriseTierFee = parseInt(data.enterpriseTierFee, 10);
    if (data.maintenanceMode !== undefined) this.config.maintenanceMode = Boolean(data.maintenanceMode);
    this.persist();
    return this.config;
  }

  // Property Methods
  public getProperties(agencyId?: number, search?: string, type?: string, propertyType?: string, status?: string): MemoryProperty[] {
    let list = [...this.properties];
    if (agencyId) {
      list = list.filter((p) => p.agencyId === Number(agencyId));
    }
    if (type && type !== 'All') {
      list = list.filter((p) => p.type === type);
    }
    if (propertyType && propertyType !== 'All') {
      list = list.filter((p) => p.propertyType === propertyType);
    }
    if (status && status !== 'All') {
      list = list.filter((p) => p.status === status);
    }
    if (search) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) =>
          p.title.toLowerCase().includes(q) ||
          p.location.toLowerCase().includes(q) ||
          p.propertyCode.toLowerCase().includes(q) ||
          p.agencyName.toLowerCase().includes(q)
      );
    }
    return list;
  }

  public getPropertyById(id: number | string): MemoryProperty | undefined {
    return this.properties.find((p) => p.id === Number(id) || p.propertyCode === String(id));
  }

  public createProperty(data: any): MemoryProperty {
    const nextId = this.properties.length > 0 ? Math.max(...this.properties.map((p) => p.id)) + 1 : 101;
    const propertyCode = `PR-${nextId}`;

    const newProp: MemoryProperty = {
      id: nextId,
      propertyCode,
      title: data.title,
      location: data.location,
      price: data.price,
      bhk: data.bhk || '2 BHK',
      type: data.type || 'Sale',
      propertyType: data.propertyType || 'Apartment',
      areaSqft: data.areaSqft ? parseFloat(data.areaSqft) : 1000.0,
      status: data.status || 'Available',
      isPublic: data.isPublic !== undefined ? Boolean(data.isPublic) : false,
      agencyId: data.agencyId ? Number(data.agencyId) : 1,
      agencyName: data.agencyName || 'Sunrise Properties',
      brokerName: data.brokerName || 'Om Shivam',
      bathrooms: data.bathrooms ? parseInt(data.bathrooms, 10) : 2,
      balcony: data.balcony ? parseInt(data.balcony, 10) : 1,
      parking: data.parking ? parseInt(data.parking, 10) : 1,
      furnishedStatus: data.furnishedStatus || 'Unfurnished',
      maintenanceCharges: data.maintenanceCharges || '₹0',
      amenities: data.amenities || [],
      images: data.images || [],
      createdAt: new Date().toISOString(),
    };

    this.properties.unshift(newProp);
    this.recordAuditLog('Broker', 'Broker', 'Property Onboarded', `${newProp.title} (${newProp.propertyCode})`);
    this.persist();

    return newProp;
  }

  public updateProperty(id: number | string, data: any): MemoryProperty | undefined {
    const prop = this.getPropertyById(id);
    if (!prop) return undefined;

    if (data.title) prop.title = data.title;
    if (data.location) prop.location = data.location;
    if (data.price) prop.price = data.price;
    if (data.bhk) prop.bhk = data.bhk;
    if (data.type) prop.type = data.type;
    if (data.propertyType) prop.propertyType = data.propertyType;
    if (data.areaSqft !== undefined) prop.areaSqft = parseFloat(data.areaSqft);
    if (data.status) prop.status = data.status;
    if (data.isPublic !== undefined) prop.isPublic = Boolean(data.isPublic);
    if (data.bathrooms !== undefined) prop.bathrooms = parseInt(data.bathrooms, 10);
    if (data.balcony !== undefined) prop.balcony = parseInt(data.balcony, 10);
    if (data.parking !== undefined) prop.parking = parseInt(data.parking, 10);
    if (data.furnishedStatus) prop.furnishedStatus = data.furnishedStatus;
    if (data.maintenanceCharges !== undefined) prop.maintenanceCharges = data.maintenanceCharges;
    if (data.amenities) prop.amenities = data.amenities;

    this.persist();
    return prop;
  }

  public deleteProperty(id: number | string): boolean {
    const idx = this.properties.findIndex((p) => p.id === Number(id) || p.propertyCode === String(id));
    if (idx !== -1) {
      this.properties.splice(idx, 1);
      this.persist();
      return true;
    }
    return false;
  }
}

export const memoryStore = new MemoryStore();
