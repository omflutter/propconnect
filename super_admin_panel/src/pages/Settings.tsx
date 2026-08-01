import { useState } from 'react';
import { Save, UserPlus, Shield, Key, Lock, CheckCircle, X, Users, AlertCircle, Edit, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';
import './Settings.css';

export function Settings() {
  const [activeTab, setActiveTab] = useState<'admins' | 'config' | 'profile'>('admins');
  const [showAddAdminModal, setShowAddAdminModal] = useState(false);
  const [editingAdmin, setEditingAdmin] = useState<any>(null);

  // Admin users list with granular permissions
  const [admins, setAdmins] = useState([
    {
      id: 'ADM-01',
      name: 'Om Shivam',
      email: 'om@propconnect.in',
      role: 'Super Admin (Full Access)',
      powers: ['All System Powers', 'Agencies & Onboarding', 'Financials & Commissions', 'Gateways & Tax', 'Role Management'],
      status: 'Active',
      lastLogin: '2026-08-01 13:10'
    },
    {
      id: 'ADM-02',
      name: 'Vikram Malhotra',
      email: 'vikram.m@propconnect.in',
      role: 'Operations & Onboarding Admin',
      powers: ['Agencies Matrix', 'Global Inventory', 'Broker Approvals', 'Support Tickets'],
      status: 'Active',
      lastLogin: '2026-08-01 10:45'
    },
    {
      id: 'ADM-03',
      name: 'Sneha Kapoor',
      email: 'sneha.k@propconnect.in',
      role: 'Finance & Payouts Lead',
      powers: ['Financials & Commissions', 'Settlements Ledger', 'GST Invoices', 'SaaS Subscriptions'],
      status: 'Active',
      lastLogin: '2026-07-31 18:20'
    },
    {
      id: 'ADM-04',
      name: 'Rohan Sharma',
      email: 'rohan.s@propconnect.in',
      role: 'Support & Moderation Specialist',
      powers: ['Support Tickets', 'Broker Chat Moderation', 'Push Notifications'],
      status: 'Active',
      lastLogin: '2026-07-30 14:15'
    }
  ]);

  // Form states for new admin
  const [newAdminName, setNewAdminName] = useState('');
  const [newAdminEmail, setNewAdminEmail] = useState('');
  const [newAdminRole, setNewAdminRole] = useState('Operations Admin');
  const [selectedPowers, setSelectedPowers] = useState<string[]>([
    'Agencies Matrix',
    'Global Inventory'
  ]);

  const powerOptions = [
    { key: 'agencies', label: 'Agencies Matrix & Onboarding' },
    { key: 'brokers', label: 'Platform Brokers & Roles' },
    { key: 'properties', label: 'Global Property Inventory' },
    { key: 'deals', label: 'Deal Pipelines & Collaborations' },
    { key: 'finance', label: 'Financials, Commissions & Settlements' },
    { key: 'whatsapp', label: 'WhatsApp API & Push Broadcasts' },
    { key: 'gateways', label: 'Payment Gateways & GST Invoices' },
    { key: 'settings', label: 'Platform Settings & Admin Creation' },
  ];

  const handleTogglePower = (label: string) => {
    if (selectedPowers.includes(label)) {
      setSelectedPowers(selectedPowers.filter(p => p !== label));
    } else {
      setSelectedPowers([...selectedPowers, label]);
    }
  };

  const handleCreateAdmin = () => {
    if (!newAdminName || !newAdminEmail) {
      toast.error('Please fill in admin name and email');
      return;
    }
    const newEntry = {
      id: `ADM-0${admins.length + 1}`,
      name: newAdminName,
      email: newAdminEmail,
      role: newAdminRole,
      powers: selectedPowers.length > 0 ? selectedPowers : ['Support Tickets'],
      status: 'Active',
      lastLogin: 'Never'
    };
    setAdmins([...admins, newEntry]);
    toast.success(`Admin user ${newAdminName} created with custom powers!`);
    setShowAddAdminModal(false);
    setNewAdminName('');
    setNewAdminEmail('');
  };

  const handleToggleStatus = (id: string) => {
    setAdmins(admins.map(a => a.id === id ? {
      ...a,
      status: a.status === 'Active' ? 'Suspended' : 'Active'
    } : a));
    toast.success(`Admin status updated.`);
  };

  return (
    <div className="settings-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Platform Config & Admin Role Management</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage system policies, add platform admin users, and assign granular feature access powers.</p>
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
          <Shield size={14} style={{ marginRight: 6 }} /> Admin Team & Powers
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
            <h3 style={{ fontSize: 15 }}>Authorized Platform Administrators</h3>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{admins.length} Total Platform Admins</span>
          </div>

          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                  <th>Admin ID & Name</th>
                  <th>Email Address</th>
                  <th>Assigned Role</th>
                  <th>Granular Access Powers</th>
                  <th>Last Active</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {admins.map((admin) => (
                  <tr key={admin.id}>
                    <td><input type="checkbox" className="table-checkbox" /></td>
                    <td>
                      <div className="entity-info">
                        <div>
                          <strong>{admin.name}</strong>
                          <span className="entity-sub">{admin.id}</span>
                        </div>
                      </div>
                    </td>
                    <td><span style={{ fontFamily: 'monospace', fontSize: 12 }}>{admin.email}</span></td>
                    <td><span className="agency-tag" style={{ borderColor: 'var(--primary-blue-light)' }}>{admin.role}</span></td>
                    <td style={{ maxWidth: 280 }}>
                      {admin.powers.map((p, i) => (
                        <span key={i} className="power-chip">{p}</span>
                      ))}
                    </td>
                    <td><span className="entity-sub">{admin.lastLogin}</span></td>
                    <td>
                      <span className={`status-badge ${admin.status === 'Active' ? 'closed' : 'dropped'}`}>
                        {admin.status}
                      </span>
                    </td>
                    <td>
                      <div className="action-buttons">
                        <ActionDropdown 
                          actions={[
                            { label: 'Edit Powers & Role', onClick: () => setEditingAdmin(admin) },
                            { label: admin.status === 'Active' ? 'Suspend Access' : 'Reactivate Admin', onClick: () => handleToggleStatus(admin.id), danger: admin.status === 'Active' },
                          ]}
                        />
                      </div>
                    </td>
                  </tr>
                ))}
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
              <input type="number" defaultValue={2.5} step={0.1} />
            </div>
            
            <div className="form-group">
              <label>Default Basic Tier Monthly Fee (₹)</label>
              <input type="number" defaultValue={2999} />
            </div>

            <button className="btn-primary" onClick={() => toast.success('Platform Policies Saved!')}>
              <Save size={16} /> Save Changes
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
                <input type="checkbox" />
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
              <input type="text" defaultValue="Om Shivam" />
            </div>
            
            <div className="form-group">
              <label>Email Address</label>
              <input type="email" defaultValue="om@propconnect.in" />
            </div>

            <div className="form-group">
              <label>New Security Password</label>
              <input type="password" placeholder="••••••••" />
            </div>

            <button className="btn-primary" onClick={() => toast.success('Super Admin Profile Updated!')}>
              <Save size={16} /> Update Credentials
            </button>
          </div>
        </div>
      )}

      {/* ADD NEW ADMIN MODAL */}
      {showAddAdminModal && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Add New Admin User & Assign Powers</h2>
              <button className="icon-btn" onClick={() => setShowAddAdminModal(false)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Full Name</label>
                  <input 
                    className="form-input" 
                    placeholder="e.g. Anish Gupta" 
                    value={newAdminName}
                    onChange={(e) => setNewAdminName(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label>Email Address</label>
                  <input 
                    className="form-input" 
                    type="email"
                    placeholder="anish@propconnect.in" 
                    value={newAdminEmail}
                    onChange={(e) => setNewAdminEmail(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Assigned Admin Role</label>
                <select 
                  className="form-select"
                  value={newAdminRole}
                  onChange={(e) => setNewAdminRole(e.target.value)}
                >
                  <option>Operations & Onboarding Admin</option>
                  <option>Finance & Payouts Lead</option>
                  <option>Support & Moderation Specialist</option>
                  <option>Super Admin (Full Access)</option>
                </select>
              </div>

              <div>
                <label style={{ fontSize: 13, fontWeight: 700, display: 'block', marginBottom: 8 }}>
                  Granular Access Powers & Option Checkboxes
                </label>
                <div className="permission-grid">
                  {powerOptions.map((opt) => (
                    <label key={opt.key} className="permission-item">
                      <input 
                        type="checkbox"
                        checked={selectedPowers.includes(opt.label)}
                        onChange={() => handleTogglePower(opt.label)}
                      />
                      <span>{opt.label}</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowAddAdminModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleCreateAdmin}>Register Admin & Assign Powers</button>
            </div>
          </div>
        </div>
      )}

      {/* EDIT ADMIN POWERS MODAL */}
      {editingAdmin && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Edit Admin Access Powers: {editingAdmin.name}</h2>
              <button className="icon-btn" onClick={() => setEditingAdmin(null)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="form-group">
                <label>Admin User</label>
                <input className="form-input" readOnly value={`${editingAdmin.name} (${editingAdmin.email})`} />
              </div>
              <div className="form-group">
                <label>Current Assigned Powers</label>
                <div className="permission-grid">
                  {powerOptions.map((opt) => (
                    <label key={opt.key} className="permission-item">
                      <input 
                        type="checkbox"
                        defaultChecked={editingAdmin.powers.includes(opt.label) || editingAdmin.powers.includes('All System Powers')}
                      />
                      <span>{opt.label}</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setEditingAdmin(null)}>Cancel</button>
              <button className="btn-primary" onClick={() => { toast.success(`Permissions updated for ${editingAdmin.name}`); setEditingAdmin(null); }}>Save Permissions</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
