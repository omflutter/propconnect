import { useState, useEffect } from 'react';
import { Save, UserPlus, Shield, Key, X, Loader2, Edit2, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { ConfirmModal } from '../components/ConfirmModal';
import { apiFetch } from '../services/api';
import './GlobalData.css';
import './Settings.css';

export interface AdminUser {
  id: number;
  name: string;
  email: string;
  phone?: string;
  role: string;
  adminRoleTitle?: string;
  permissions?: Record<string, string[]>;
  status: 'Active' | 'Suspended';
  createdAt: string;
}

export interface SectionDefinition {
  key: string;
  name: string;
  description: string;
}

const PLATFORM_SECTIONS: SectionDefinition[] = [
  { key: 'agencies', name: 'Agencies Matrix & Onboarding', description: 'Multi-tenant real estate agency accounts' },
  { key: 'brokers', name: 'Brokers & User Roles', description: 'Broker profiles and app access' },
  { key: 'properties', name: 'Global Property Inventory', description: 'Real estate property listings' },
  { key: 'deals', name: 'Deal Pipelines & Collaborations', description: 'Joint broker deals & lead matching' },
  { key: 'finance', name: 'Financials, Commissions & Settlements', description: 'Payouts, revenue ledgers & GST' },
  { key: 'gateways', name: 'Payment Gateways & Invoices', description: 'Razorpay, Stripe & tax settings' },
  { key: 'whatsapp', name: 'WhatsApp API & Broadcasts', description: 'Push notifications & messaging' },
  { key: 'settings', name: 'Platform Settings & Admin Powers', description: 'System configuration & admin team' },
];

const PREDEFINED_ROLES: { title: string; powers: Record<string, string[]> }[] = [
  {
    title: 'Super Admin (Full Access)',
    powers: {
      agencies: ['view', 'edit', 'delete'],
      brokers: ['view', 'edit', 'delete'],
      properties: ['view', 'edit', 'delete'],
      deals: ['view', 'edit', 'delete'],
      finance: ['view', 'edit', 'delete'],
      gateways: ['view', 'edit', 'delete'],
      whatsapp: ['view', 'edit', 'delete'],
      settings: ['view', 'edit', 'delete'],
    },
  },
  {
    title: 'Operations & Onboarding Manager',
    powers: {
      agencies: ['view', 'edit', 'delete'],
      brokers: ['view', 'edit'],
      properties: ['view', 'edit'],
      deals: ['view'],
      finance: [],
      gateways: [],
      whatsapp: ['view'],
      settings: [],
    },
  },
  {
    title: 'Finance & Payouts Lead',
    powers: {
      agencies: ['view'],
      brokers: ['view'],
      properties: [],
      deals: ['view'],
      finance: ['view', 'edit', 'delete'],
      gateways: ['view', 'edit'],
      whatsapp: [],
      settings: [],
    },
  },
  {
    title: 'Support & Moderation Specialist',
    powers: {
      agencies: ['view'],
      brokers: ['view', 'edit'],
      properties: ['view'],
      deals: ['view'],
      finance: [],
      gateways: [],
      whatsapp: ['view', 'edit'],
      settings: [],
    },
  },
  {
    title: 'Custom Admin Role',
    powers: {},
  },
];

export function Settings() {
  const [activeTab, setActiveTab] = useState<'admins' | 'config' | 'profile'>('admins');
  const [showAddAdminModal, setShowAddAdminModal] = useState(false);
  const [editingAdmin, setEditingAdmin] = useState<AdminUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Live Admin Users list from MySQL
  const [admins, setAdmins] = useState<AdminUser[]>([]);

  // Config & Policy state
  const [config, setConfig] = useState({
    platformFeePercent: 2.5,
    basicTierFee: 2999,
    proTierFee: 5999,
    enterpriseTierFee: 14999,
    maintenanceMode: false,
  });

  // Profile Form state
  const [profileForm, setProfileForm] = useState({
    name: 'Platform Super Admin',
    email: 'admin@propconnect.in',
    password: '',
  });

  // Form states for new admin
  const [newAdminName, setNewAdminName] = useState('');
  const [newAdminEmail, setNewAdminEmail] = useState('');
  const [newAdminPhone, setNewAdminPhone] = useState('');
  const [newAdminPassword, setNewAdminPassword] = useState('admin123');
  const [selectedRoleTitle, setSelectedRoleTitle] = useState('Operations & Onboarding Manager');
  const [permissionMatrix, setPermissionMatrix] = useState<Record<string, string[]>>({
    agencies: ['view', 'edit', 'delete'],
    brokers: ['view', 'edit'],
    properties: ['view', 'edit'],
    deals: ['view'],
  });

  // Global ConfirmModal State
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    type: 'danger' | 'warning' | 'success';
    confirmText: string;
    onConfirm: () => Promise<void>;
  }>({
    isOpen: false,
    title: '',
    message: '',
    type: 'warning',
    confirmText: 'Confirm',
    onConfirm: async () => {},
  });

  const fetchConfigAndAdmins = async () => {
    setIsLoading(true);
    const [configRes, adminsRes] = await Promise.all([
      apiFetch('/config'),
      apiFetch<AdminUser[]>('/config/admins'),
    ]);
    setIsLoading(false);

    if (configRes.success && configRes.data) {
      setConfig(configRes.data);
    }
    if (adminsRes.success && adminsRes.data) {
      setAdmins(adminsRes.data);
    }
  };

  useEffect(() => {
    fetchConfigAndAdmins();
  }, []);

  const handleRoleChange = (roleTitle: string) => {
    setSelectedRoleTitle(roleTitle);
    const foundRole = PREDEFINED_ROLES.find((r) => r.title === roleTitle);
    if (foundRole && roleTitle !== 'Custom Admin Role') {
      setPermissionMatrix(foundRole.powers);
    }
  };

  const handleTogglePermission = (sectionKey: string, power: 'view' | 'edit' | 'delete') => {
    const currentPowers = permissionMatrix[sectionKey] || [];
    let updatedPowers: string[];

    if (currentPowers.includes(power)) {
      updatedPowers = currentPowers.filter((p) => p !== power);
    } else {
      updatedPowers = [...currentPowers, power];
    }

    setPermissionMatrix({
      ...permissionMatrix,
      [sectionKey]: updatedPowers,
    });
  };

  const handleCreateAdmin = async () => {
    if (!newAdminName || !newAdminEmail) {
      toast.error('Please fill in admin name and email');
      return;
    }

    setIsSaving(true);
    const res = await apiFetch('/config/admins', {
      method: 'POST',
      body: JSON.stringify({
        name: newAdminName,
        email: newAdminEmail,
        phone: newAdminPhone,
        password: newAdminPassword,
        adminRoleTitle: selectedRoleTitle,
        permissions: permissionMatrix,
      }),
    });
    setIsSaving(false);

    if (res.success) {
      toast.success(`Admin user "${newAdminName}" created with custom permission matrix!`);
      setShowAddAdminModal(false);
      setNewAdminName('');
      setNewAdminEmail('');
      setNewAdminPhone('');
      fetchConfigAndAdmins();
    } else {
      toast.error(res.message || 'Failed to create admin user');
    }
  };

  const handleSaveEditAdmin = async () => {
    if (!editingAdmin) return;

    setIsSaving(true);
    const res = await apiFetch(`/config/admins/${editingAdmin.id}`, {
      method: 'PUT',
      body: JSON.stringify({
        adminRoleTitle: editingAdmin.adminRoleTitle,
        permissions: editingAdmin.permissions,
        status: editingAdmin.status,
      }),
    });
    setIsSaving(false);

    if (res.success) {
      toast.success(`Permissions updated for ${editingAdmin.name}.`);
      setEditingAdmin(null);
      fetchConfigAndAdmins();
    } else {
      toast.error(res.message || 'Failed to update admin permissions');
    }
  };

  const openDeleteAdminConfirmModal = (id: number, name: string) => {
    setConfirmModal({
      isOpen: true,
      title: 'Remove Platform Administrator',
      message: `Are you sure you want to remove "${name}" from the Platform Admin Team? They will lose access to the Super Admin Panel.`,
      type: 'danger',
      confirmText: 'Remove Admin',
      onConfirm: async () => {
        setIsSaving(true);
        const res = await apiFetch(`/config/admins/${id}`, {
          method: 'DELETE',
        });
        setIsSaving(false);

        if (res.success) {
          toast.success(`Admin user "${name}" removed.`);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          fetchConfigAndAdmins();
        } else {
          toast.error(res.message || 'Failed to remove admin user');
        }
      },
    });
  };

  const openMaintenanceConfirmModal = (enable: boolean) => {
    setConfirmModal({
      isOpen: true,
      title: enable ? 'Enable Platform Maintenance Mode' : 'Disable Maintenance Mode',
      message: enable
        ? 'Enabling maintenance mode will place a system banner across all mobile apps and broker portals. Are you sure?'
        : 'Disabling maintenance mode will restore active access for all users immediately.',
      type: enable ? 'warning' : 'success',
      confirmText: enable ? 'Enable Maintenance' : 'Disable Maintenance',
      onConfirm: async () => {
        setIsSaving(true);
        const res = await apiFetch('/config/policies', {
          method: 'PUT',
          body: JSON.stringify({ maintenanceMode: enable }),
        });
        setIsSaving(false);

        if (res.success) {
          setConfig((prev) => ({ ...prev, maintenanceMode: enable }));
          toast.success(`Maintenance mode ${enable ? 'enabled' : 'disabled'}.`);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
        } else {
          toast.error(res.message || 'Failed to update maintenance mode');
        }
      },
    });
  };

  const handleSavePolicies = async () => {
    setIsSaving(true);
    const res = await apiFetch('/config/policies', {
      method: 'PUT',
      body: JSON.stringify(config),
    });
    setIsSaving(false);

    if (res.success) {
      toast.success('Platform commission & fee policies saved to MySQL database!');
    } else {
      toast.error(res.message || 'Failed to save policies');
    }
  };

  const handleSaveProfile = async () => {
    setIsSaving(true);
    const res = await apiFetch('/config/profile', {
      method: 'PUT',
      body: JSON.stringify(profileForm),
    });
    setIsSaving(false);

    if (res.success) {
      toast.success('Super Admin profile updated successfully.');
      setProfileForm((prev) => ({ ...prev, password: '' }));
    } else {
      toast.error(res.message || 'Failed to update profile');
    }
  };

  return (
    <div className="settings-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Platform Config & Admin Role Management</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage system policies, add platform admin users, and assign granular section powers (View, Edit, Delete).</p>
        </div>
        <div className="header-actions">
          {activeTab === 'admins' && (
            <button className="btn-primary" onClick={() => setShowAddAdminModal(true)}>
              <UserPlus size={14} style={{ marginRight: 6 }} /> + Add New Admin User
            </button>
          )}
        </div>
      </div>

      {/* Navigation Segmented Tabs */}
      <div className="segmented-tabs" style={{ marginBottom: 16 }}>
        <button 
          className={activeTab === 'admins' ? 'active' : ''} 
          onClick={() => setActiveTab('admins')}
        >
          <Shield size={14} style={{ marginRight: 6 }} /> Admin Team & Granular Powers
        </button>
        <button 
          className={activeTab === 'config' ? 'active' : ''} 
          onClick={() => setActiveTab('config')}
        >
          <Save size={14} style={{ marginRight: 6 }} /> Platform Policies & Fees
        </button>
        <button 
          className={activeTab === 'profile' ? 'active' : ''} 
          onClick={() => setActiveTab('profile')}
        >
          <Key size={14} style={{ marginRight: 6 }} /> My Super Admin Profile
        </button>
      </div>

      {/* TAB 1: ADMIN TEAM & ROLES */}
      {activeTab === 'admins' && (
        <div className="card table-container">
          <div style={{ padding: '16px 24px', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: 15 }}>Authorized Platform Administrators & Permission Matrix</h3>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{admins.length} Total Platform Admins</span>
          </div>

          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                  <th>Admin ID & Name</th>
                  <th>Email Address</th>
                  <th>Permanent System Role</th>
                  <th>Granular Section Powers (View / Edit / Delete)</th>
                  <th>Joined Date</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  [1, 2, 3].map((idx) => (
                    <tr key={idx}>
                      <td><input type="checkbox" className="table-checkbox" disabled /></td>
                      <td>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                          <span className="skeleton-box" style={{ width: 130 }} />
                          <span className="skeleton-box" style={{ width: 60 }} />
                        </div>
                      </td>
                      <td><span className="skeleton-box" style={{ width: 160 }} /></td>
                      <td><span className="skeleton-box" style={{ width: 180, height: 22, borderRadius: 16 }} /></td>
                      <td><span className="skeleton-box" style={{ width: 240 }} /></td>
                      <td><span className="skeleton-box" style={{ width: 80 }} /></td>
                      <td><span className="skeleton-box" style={{ width: 60, height: 22, borderRadius: 16 }} /></td>
                      <td><span className="skeleton-box" style={{ width: 60 }} /></td>
                    </tr>
                  ))
                ) : (
                  admins.map((admin) => {
                    const perms = admin.permissions || {
                      agencies: ['view', 'edit', 'delete'],
                      brokers: ['view', 'edit', 'delete'],
                      properties: ['view', 'edit', 'delete'],
                      finance: ['view', 'edit', 'delete'],
                    };

                    return (
                      <tr key={admin.id}>
                        <td><input type="checkbox" className="table-checkbox" /></td>
                        <td>
                          <div className="entity-info">
                            <div>
                              <strong>{admin.name}</strong>
                              <span className="entity-sub">ADM-{String(admin.id).padStart(2, '0')}</span>
                            </div>
                          </div>
                        </td>
                        <td><span style={{ fontFamily: 'monospace', fontSize: 12 }}>{admin.email}</span></td>
                        <td>
                          <span className="agency-tag" style={{ borderColor: 'var(--primary-blue-light)', fontWeight: 600 }}>
                            {admin.adminRoleTitle || 'Super Admin (Full Access)'}
                          </span>
                        </td>
                        <td style={{ maxWidth: 360, padding: '12px 16px' }}>
                          <div className="section-powers-group">
                            {Object.entries(perms).map(([secKey, powers]) => {
                              if (!powers || powers.length === 0) return null;
                              const secDef = PLATFORM_SECTIONS.find((s) => s.key === secKey);
                              const secName = secDef ? secDef.name.split(' ')[0] : secKey;

                              return (
                                <div key={secKey} style={{ display: 'inline-flex', alignItems: 'center', marginRight: 8, marginBottom: 4 }}>
                                  <span className="power-chip">
                                    <strong>{secName}:</strong>
                                    {powers.includes('view') && <span className="perm-badge view">View</span>}
                                    {powers.includes('edit') && <span className="perm-badge edit">Edit</span>}
                                    {powers.includes('delete') && <span className="perm-badge delete">Delete</span>}
                                  </span>
                                </div>
                              );
                            })}
                          </div>
                        </td>
                        <td><span className="entity-sub">{new Date(admin.createdAt).toLocaleDateString()}</span></td>
                        <td>
                          <span className={`status-badge ${admin.status === 'Active' ? 'closed' : 'dropped'}`}>
                            {admin.status}
                          </span>
                        </td>
                        <td>
                          <div className="action-buttons">
                            <ActionDropdown 
                              actions={[
                                { label: 'Edit Role & Powers Matrix', onClick: () => setEditingAdmin(admin) },
                                { label: 'Delete Admin User', onClick: () => openDeleteAdminConfirmModal(admin.id, admin.name), danger: true },
                              ]}
                            />
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: PLATFORM CONFIG */}
      {activeTab === 'config' && (
        <div className="settings-grid">
          <div className="card settings-section">
            <h3>Commission & Fee Policies</h3>
            <p className="settings-desc">Set default platform percentage and subscription pricing.</p>
            
            <div className="form-group">
              <label>Default Platform Fee (%)</label>
              <input 
                type="number" 
                step={0.1} 
                value={config.platformFeePercent}
                onChange={(e) => setConfig({ ...config, platformFeePercent: parseFloat(e.target.value) || 0 })}
              />
            </div>
            
            <div className="form-group">
              <label>Default Basic Tier Monthly Fee (₹)</label>
              <input 
                type="number" 
                value={config.basicTierFee}
                onChange={(e) => setConfig({ ...config, basicTierFee: parseInt(e.target.value, 10) || 0 })}
              />
            </div>

            <div className="form-group">
              <label>Default Pro Tier Monthly Fee (₹)</label>
              <input 
                type="number" 
                value={config.proTierFee}
                onChange={(e) => setConfig({ ...config, proTierFee: parseInt(e.target.value, 10) || 0 })}
              />
            </div>

            <div className="form-group">
              <label>Default Enterprise Tier Monthly Fee (₹)</label>
              <input 
                type="number" 
                value={config.enterpriseTierFee}
                onChange={(e) => setConfig({ ...config, enterpriseTierFee: parseInt(e.target.value, 10) || 0 })}
              />
            </div>

            <button className="btn-primary" onClick={handleSavePolicies} disabled={isSaving}>
              {isSaving ? (
                <span className="spinner-btn-content">
                  <Loader2 size={16} className="animate-spin" />
                  <span>Saving Policies...</span>
                </span>
              ) : (
                <><Save size={16} /> Save Policies to Database</>
              )}
            </button>
          </div>

          <div className="card settings-section">
            <h3>Maintenance Mode & Security</h3>
            <p className="settings-desc">Temporarily lock down the platform for database maintenance.</p>
            
            <div className="toggle-group">
              <div className="toggle-info">
                <strong>Enable Platform Maintenance Mode</strong>
                <span>Mobile app and broker portals will show a maintenance banner.</span>
              </div>
              <label className="switch">
                <input 
                  type="checkbox" 
                  checked={config.maintenanceMode}
                  onChange={(e) => openMaintenanceConfirmModal(e.target.checked)}
                />
                <span className="slider round"></span>
              </label>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: MY PROFILE */}
      {activeTab === 'profile' && (
        <div className="settings-grid">
          <div className="card settings-section">
            <h3>Super Admin Credentials</h3>
            <p className="settings-desc">Update primary super admin account information.</p>
            
            <div className="form-group">
              <label>Full Name</label>
              <input 
                type="text" 
                value={profileForm.name}
                onChange={(e) => setProfileForm({ ...profileForm, name: e.target.value })}
              />
            </div>
            
            <div className="form-group">
              <label>Email Address</label>
              <input 
                type="email" 
                value={profileForm.email}
                onChange={(e) => setProfileForm({ ...profileForm, email: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>New Security Password (leave blank to keep current)</label>
              <input 
                type="password" 
                placeholder="••••••••" 
                value={profileForm.password}
                onChange={(e) => setProfileForm({ ...profileForm, password: e.target.value })}
              />
            </div>

            <button className="btn-primary" onClick={handleSaveProfile} disabled={isSaving}>
              {isSaving ? (
                <span className="spinner-btn-content">
                  <Loader2 size={16} className="animate-spin" />
                  <span>Updating Credentials...</span>
                </span>
              ) : (
                <><Save size={16} /> Update Credentials</>
              )}
            </button>
          </div>
        </div>
      )}

      {/* ADD NEW ADMIN MODAL WITH PERMISSION MATRIX */}
      {showAddAdminModal && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Add New Admin User & Assign Powers</h2>
              <button className="icon-btn" onClick={() => setShowAddAdminModal(false)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div className="form-group">
                  <label>Full Name *</label>
                  <input 
                    className="form-input" 
                    placeholder="e.g. Anish Gupta" 
                    value={newAdminName}
                    onChange={(e) => setNewAdminName(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label>Email Address *</label>
                  <input 
                    className="form-input" 
                    type="email"
                    placeholder="anish@propconnect.in" 
                    value={newAdminEmail}
                    onChange={(e) => setNewAdminEmail(e.target.value)}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div className="form-group">
                  <label>Phone Number</label>
                  <input 
                    className="form-input" 
                    type="tel"
                    placeholder="+91 99887 76655" 
                    value={newAdminPhone}
                    onChange={(e) => setNewAdminPhone(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label>Default Initial Password</label>
                  <input 
                    className="form-input" 
                    type="password"
                    value={newAdminPassword}
                    onChange={(e) => setNewAdminPassword(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Preset Permanent System Role</label>
                <select 
                  className="form-select"
                  value={selectedRoleTitle}
                  onChange={(e) => handleRoleChange(e.target.value)}
                >
                  {PREDEFINED_ROLES.map((r) => (
                    <option key={r.title} value={r.title}>{r.title}</option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ fontSize: 13, fontWeight: 700, display: 'block', marginBottom: 10 }}>
                  Granular Section Powers (View, Edit, Delete Matrix)
                </label>

                <div className="matrix-container">
                  <table className="matrix-table">
                    <thead>
                      <tr>
                        <th>Platform Section</th>
                        <th>View Power</th>
                        <th>Edit Power</th>
                        <th>Delete Power</th>
                      </tr>
                    </thead>
                    <tbody>
                      {PLATFORM_SECTIONS.map((section) => {
                        const powers = permissionMatrix[section.key] || [];
                        const hasView = powers.includes('view');
                        const hasEdit = powers.includes('edit');
                        const hasDelete = powers.includes('delete');

                        return (
                          <tr key={section.key}>
                            <td>
                              <div>{section.name}</div>
                              <small style={{ color: 'var(--text-secondary)', fontSize: 11 }}>{section.description}</small>
                            </td>
                            <td>
                              <input 
                                type="checkbox" 
                                className="perm-checkbox"
                                checked={hasView} 
                                onChange={() => handleTogglePermission(section.key, 'view')} 
                              />
                            </td>
                            <td>
                              <input 
                                type="checkbox" 
                                className="perm-checkbox"
                                checked={hasEdit} 
                                onChange={() => handleTogglePermission(section.key, 'edit')} 
                              />
                            </td>
                            <td>
                              <input 
                                type="checkbox" 
                                className="perm-checkbox"
                                checked={hasDelete} 
                                onChange={() => handleTogglePermission(section.key, 'delete')} 
                              />
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowAddAdminModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleCreateAdmin} disabled={isSaving}>
                {isSaving ? (
                  <span className="spinner-btn-content">
                    <Loader2 size={16} className="animate-spin" />
                    <span>Registering Admin...</span>
                  </span>
                ) : (
                  'Register Admin & Save Matrix'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* EDIT ADMIN POWERS MATRIX MODAL */}
      {editingAdmin && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Edit Admin Powers: {editingAdmin.name} ({editingAdmin.email})</h2>
              <button className="icon-btn" onClick={() => setEditingAdmin(null)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              <div className="form-group">
                <label>Permanent Role Title</label>
                <select 
                  className="form-select"
                  value={editingAdmin.adminRoleTitle || 'Operations & Onboarding Manager'}
                  onChange={(e) => {
                    const title = e.target.value;
                    const foundRole = PREDEFINED_ROLES.find((r) => r.title === title);
                    setEditingAdmin({
                      ...editingAdmin,
                      adminRoleTitle: title,
                      permissions: foundRole && title !== 'Custom Admin Role' ? foundRole.powers : editingAdmin.permissions,
                    });
                  }}
                >
                  {PREDEFINED_ROLES.map((r) => (
                    <option key={r.title} value={r.title}>{r.title}</option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ fontSize: 13, fontWeight: 700, display: 'block', marginBottom: 10 }}>
                  Granular Section Powers (View, Edit, Delete Matrix)
                </label>

                <div className="matrix-container">
                  <table className="matrix-table">
                    <thead>
                      <tr>
                        <th>Platform Section</th>
                        <th>View Power</th>
                        <th>Edit Power</th>
                        <th>Delete Power</th>
                      </tr>
                    </thead>
                    <tbody>
                      {PLATFORM_SECTIONS.map((section) => {
                        const currentPerms = editingAdmin.permissions || {};
                        const powers = currentPerms[section.key] || [];
                        const hasView = powers.includes('view');
                        const hasEdit = powers.includes('edit');
                        const hasDelete = powers.includes('delete');

                        const toggleMatrix = (power: 'view' | 'edit' | 'delete') => {
                          let updatedPowers: string[];
                          if (powers.includes(power)) {
                            updatedPowers = powers.filter((p: string) => p !== power);
                          } else {
                            updatedPowers = [...powers, power];
                          }
                          setEditingAdmin({
                            ...editingAdmin,
                            permissions: {
                              ...currentPerms,
                              [section.key]: updatedPowers,
                            },
                          });
                        };

                        return (
                          <tr key={section.key}>
                            <td>
                              <div>{section.name}</div>
                              <small style={{ color: 'var(--text-secondary)', fontSize: 11 }}>{section.description}</small>
                            </td>
                            <td>
                              <input 
                                type="checkbox" 
                                className="perm-checkbox"
                                checked={hasView} 
                                onChange={() => toggleMatrix('view')} 
                              />
                            </td>
                            <td>
                              <input 
                                type="checkbox" 
                                className="perm-checkbox"
                                checked={hasEdit} 
                                onChange={() => toggleMatrix('edit')} 
                              />
                            </td>
                            <td>
                              <input 
                                type="checkbox" 
                                className="perm-checkbox"
                                checked={hasDelete} 
                                onChange={() => toggleMatrix('delete')} 
                              />
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setEditingAdmin(null)}>Cancel</button>
              <button className="btn-primary" onClick={handleSaveEditAdmin} disabled={isSaving}>
                {isSaving ? <Loader2 size={16} className="animate-spin" /> : 'Save Permission Matrix'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Global ConfirmModal Component */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        type={confirmModal.type}
        confirmText={confirmModal.confirmText}
        isLoading={isSaving}
        onConfirm={confirmModal.onConfirm}
        onCancel={() => setConfirmModal((prev) => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
}
