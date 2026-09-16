import { useState, useEffect } from 'react';
import { Search, Filter, CheckCircle, XCircle, X, Loader2, Download, AlertCircle, RefreshCw, Copy, Key, MapPin } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { ConfirmModal } from '../components/ConfirmModal';
import { SearchableSelect, SelectOption } from '../components/SearchableSelect';
import { LiveLocationSelect } from '../components/LiveLocationSelect';
import { apiFetch } from '../services/api';
import './Agencies.css';

const CITY_OPTIONS: SelectOption[] = [
  { value: 'Mumbai', label: 'Mumbai (MMR)', subLabel: 'Bandra, BKC, Worli, Thane' },
  { value: 'Delhi NCR', label: 'Delhi NCR', subLabel: 'Delhi, Gurugram, Noida' },
  { value: 'Bangalore', label: 'Bangalore', subLabel: 'Indiranagar, HSR, Whitefield' },
  { value: 'Hyderabad', label: 'Hyderabad', subLabel: 'Gachibowli, HITECH City' },
  { value: 'Pune', label: 'Pune', subLabel: 'Koregaon Park, Baner, Hinjewadi' },
  { value: 'Chennai', label: 'Chennai', subLabel: 'OMR, Anna Nagar, Velachery' },
  { value: 'Kolkata', label: 'Kolkata', subLabel: 'Salt Lake, New Town' },
  { value: 'Ahmedabad', label: 'Ahmedabad', subLabel: 'SG Highway, Prahlad Nagar' },
  { value: 'Jaipur', label: 'Jaipur', subLabel: 'C Scheme, Vaishali Nagar' },
  { value: 'Surat', label: 'Surat', subLabel: 'Vesu, Adajan' },
  { value: 'Chandigarh', label: 'Chandigarh Tri-City', subLabel: 'Chandigarh, Mohali, Panchkula' },
  { value: 'Lucknow', label: 'Lucknow', subLabel: 'Gomti Nagar, Hazratganj' },
  { value: 'Indore', label: 'Indore', subLabel: 'Vijay Nagar, AB Road' },
  { value: 'Kochi', label: 'Kochi', subLabel: 'Kakkanad, Marine Drive' },
  { value: 'Goa', label: 'Goa', subLabel: 'North & South Goa' },
  { value: 'Pan India', label: 'Pan India / Multi-City', subLabel: 'Operates Nationally' },
];

export interface AgencyItem {
  id: number;
  agencyCode: string;
  name: string;
  reraNumber?: string;
  location: string;
  address?: string;
  adminName: string;
  adminEmail: string;
  adminPhone?: string;
  subscriptionTier: string;
  userQuota: number;
  propertiesCount: number;
  dealsCount: number;
  status: 'Active' | 'Pending' | 'Suspended';
  createdAt: string;
}

export function Agencies() {
  const navigate = useNavigate();
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isActionLoading, setIsActionLoading] = useState(false);
  const [agencies, setAgencies] = useState<AgencyItem[]>([]);
  const [editingAgency, setEditingAgency] = useState<AgencyItem | null>(null);
  const [apiError, setApiError] = useState<string | null>(null);

  const [onboardedCredentials, setOnboardedCredentials] = useState<{
    agencyName: string;
    agencyCode: string;
    adminEmail: string;
    adminName: string;
    password: string;
  } | null>(null);

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
    type: 'danger',
    confirmText: 'Confirm',
    onConfirm: async () => {},
  });

  const [newAgency, setNewAgency] = useState({
    name: '',
    adminName: '',
    adminEmail: '',
    adminPhone: '',
    location: '',
    address: '',
    reraNumber: '',
    subscriptionTier: 'Pro (₹5,999/mo)',
    userQuota: 10,
    password: 'agency123',
  });

  const fetchAgencies = async () => {
    setIsLoading(true);
    setApiError(null);
    let url = '/agencies';
    const queryParams: string[] = [];
    if (statusFilter !== 'All') queryParams.push(`status=${statusFilter}`);
    if (searchQuery) queryParams.push(`search=${encodeURIComponent(searchQuery)}`);

    if (queryParams.length > 0) {
      url += `?${queryParams.join('&')}`;
    }

    const res = await apiFetch<AgencyItem[]>(url);
    setIsLoading(false);

    if (res.success && res.data) {
      setAgencies(res.data);
      setApiError(null);
    } else {
      console.error('[Fetch Agencies Error]', res);
      setApiError(res.message);
      toast.error(res.message || 'Failed to fetch agencies', { duration: 6000 });
    }
  };

  useEffect(() => {
    fetchAgencies();
  }, [statusFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchAgencies();
  };

  const openStatusConfirmModal = (id: number, name: string, newStatus: 'Active' | 'Pending' | 'Suspended') => {
    const isSuspending = newStatus === 'Suspended';

    setConfirmModal({
      isOpen: true,
      title: isSuspending ? 'Suspend Agency Account' : 'Approve & Activate Agency',
      message: isSuspending
        ? `Are you sure you want to suspend "${name}"? Their agency admin and brokers will not be able to access platform features while suspended.`
        : `Approve "${name}" and activate their SaaS platform tenant access?`,
      type: isSuspending ? 'warning' : 'success',
      confirmText: isSuspending ? 'Suspend Account' : 'Activate Agency',
      onConfirm: async () => {
        setIsActionLoading(true);
        const res = await apiFetch(`/agencies/${id}/status`, {
          method: 'PATCH',
          body: JSON.stringify({ status: newStatus }),
        });
        setIsActionLoading(false);

        if (res.success) {
          toast.success(`Agency "${name}" status updated to ${newStatus}`);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          fetchAgencies();
        } else {
          toast.error(res.message || 'Status update failed');
        }
      },
    });
  };

  const openDeleteConfirmModal = (id: number, name: string) => {
    setConfirmModal({
      isOpen: true,
      title: 'Delete Agency Account',
      message: `Are you sure you want to permanently delete "${name}"? All associated agency data and user records will be deleted from MySQL. This action cannot be undone.`,
      type: 'danger',
      confirmText: 'Delete Agency',
      onConfirm: async () => {
        setIsActionLoading(true);
        const res = await apiFetch(`/agencies/${id}`, {
          method: 'DELETE',
        });
        setIsActionLoading(false);

        if (res.success) {
          toast.success(`Agency "${name}" deleted permanently.`);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          fetchAgencies();
        } else {
          toast.error(res.message || 'Failed to delete agency');
        }
      },
    });
  };

  const handleAddAgency = async () => {
    if (!newAgency.name || !newAgency.adminName || !newAgency.adminEmail) {
      toast.error('Agency Name, Admin Name, and Admin Email are required.');
      return;
    }

    setIsActionLoading(true);
    const res = await apiFetch('/agencies', {
      method: 'POST',
      body: JSON.stringify(newAgency),
    });
    setIsActionLoading(false);

    if (res.success) {
      const creds = res.data?.credentials || {
        agencyCode: res.data?.agency?.agencyCode || 'AG-00X',
        adminEmail: newAgency.adminEmail,
        adminName: newAgency.adminName,
        password: newAgency.password || 'agency123',
      };

      setOnboardedCredentials({
        agencyName: newAgency.name,
        agencyCode: creds.agencyCode,
        adminEmail: creds.adminEmail,
        adminName: creds.adminName,
        password: creds.password,
      });

      setShowAddModal(false);
      setNewAgency({
        name: '',
        adminName: '',
        adminEmail: '',
        adminPhone: '',
        location: '',
        address: '',
        reraNumber: '',
        subscriptionTier: 'Pro (₹5,999/mo)',
        userQuota: 10,
        password: 'agency123',
      });
      fetchAgencies();
    } else {
      toast.error(res.message || 'Failed to add agency');
    }
  };

  const copyWhatsAppCredentials = () => {
    if (!onboardedCredentials) return;
    const text = `🎉 Welcome to PropConnect India!\n\nYour agency account *${onboardedCredentials.agencyName}* (${onboardedCredentials.agencyCode}) is ready!\n\n📱 *App / Portal Login Credentials:*\n• *Email:* ${onboardedCredentials.adminEmail}\n• *Password:* ${onboardedCredentials.password}\n• *Login Link:* https://propconnect-b89bd.web.app/login\n\nPlease log in and change your password.`;
    navigator.clipboard.writeText(text);
    toast.success('Credentials message copied to clipboard!');
  };

  const handleEditClick = (agency: AgencyItem) => {
    setEditingAgency(agency);
    setShowEditModal(true);
  };

  const handleSaveEditAgency = async () => {
    if (!editingAgency) return;

    setIsActionLoading(true);
    const res = await apiFetch(`/agencies/${editingAgency.id}`, {
      method: 'PUT',
      body: JSON.stringify(editingAgency),
    });
    setIsActionLoading(false);

    if (res.success) {
      toast.success(`Agency "${editingAgency.name}" updated successfully.`);
      setShowEditModal(false);
      setEditingAgency(null);
      fetchAgencies();
    } else {
      toast.error(res.message || 'Failed to update agency');
    }
  };

  const handleExportCSV = () => {
    if (!agencies || agencies.length === 0) {
      toast.error('No agency records available to export.');
      return;
    }

    const headers = [
      'Agency ID',
      'Agency Code',
      'Agency Name',
      'RERA Registration No',
      'Location',
      'Corporate Address',
      'Admin Name',
      'Admin Email',
      'Admin Phone',
      'Subscription Tier',
      'User Quota',
      'Active Properties',
      'Closed Deals',
      'Status',
      'Joined Date',
    ];

    const escapeCSV = (value: any) => {
      if (value === null || value === undefined) return '""';
      const str = String(value).replace(/"/g, '""');
      return `"${str}"`;
    };

    const csvRows = [
      headers.join(','),
      ...agencies.map((agency) =>
        [
          escapeCSV(agency.id),
          escapeCSV(agency.agencyCode),
          escapeCSV(agency.name),
          escapeCSV(agency.reraNumber || 'N/A'),
          escapeCSV(agency.location),
          escapeCSV(agency.address || 'N/A'),
          escapeCSV(agency.adminName),
          escapeCSV(agency.adminEmail),
          escapeCSV(agency.adminPhone || 'N/A'),
          escapeCSV(agency.subscriptionTier),
          escapeCSV(agency.userQuota),
          escapeCSV(agency.propertiesCount),
          escapeCSV(agency.dealsCount),
          escapeCSV(agency.status),
          escapeCSV(new Date(agency.createdAt).toLocaleDateString()),
        ].join(',')
      ),
    ];

    const csvContent = '\uFEFF' + csvRows.join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    const dateStr = new Date().toISOString().split('T')[0];
    link.setAttribute('href', url);
    link.setAttribute('download', `PropConnect_Agencies_Export_${dateStr}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success(`Exported ${agencies.length} agencies to CSV successfully!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Agencies Matrix</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage and monitor all multi-tenant SaaS agencies on the PropConnect platform.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={handleExportCSV}>
            <Download size={14} style={{ marginRight: 6 }} /> Export CSV
          </button>
          <button className="btn-primary" onClick={() => setShowAddModal(true)}>+ Onboard Agency</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Agencies</button>
            <button className={statusFilter === 'Active' ? 'active' : ''} onClick={() => setStatusFilter('Active')}>Active</button>
            <button className={statusFilter === 'Pending' ? 'active' : ''} onClick={() => setStatusFilter('Pending')}>Pending Onboarding</button>
            <button className={statusFilter === 'Suspended' ? 'active' : ''} onClick={() => setStatusFilter('Suspended')}>Suspended</button>
          </div>

          <form onSubmit={handleSearchSubmit} style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search agencies..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <button type="button" className="btn-secondary filter-btn" onClick={() => setShowFilterModal(true)}>
              <Filter size={16} /> Filters
            </button>
          </form>
        </div>

        {apiError && (
          <div style={{ backgroundColor: '#fef2f2', borderBottom: '1px solid #fca5a5', color: '#991b1b', padding: '12px 24px', fontSize: '13px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <AlertCircle size={18} style={{ flexShrink: 0 }} />
              <div>
                <strong>API Request Exception:</strong> <code style={{ fontFamily: 'monospace', background: '#fee2e2', padding: '2px 6px', borderRadius: 4 }}>{apiError}</code>
              </div>
            </div>
            <button className="btn-secondary" style={{ padding: '4px 10px', fontSize: 12 }} onClick={() => fetchAgencies()}>
              <RefreshCw size={12} style={{ marginRight: 4 }} /> Retry Request
            </button>
          </div>
        )}

        <div className="table-wrapper">
          <table className="agencies-table">
            <thead>
              <tr>
                <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                <th>Agency Info</th>
                <th>Admin Name</th>
                <th>Location</th>
                <th>Listings</th>
                <th>Deals</th>
                <th>Status</th>
                <th>Joined Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                [1, 2, 3, 4, 5].map((idx) => (
                  <tr key={idx}>
                    <td><input type="checkbox" className="table-checkbox" disabled /></td>
                    <td>
                      <div className="agency-info">
                        <span className="skeleton-box" style={{ width: 36, height: 36, borderRadius: 8 }} />
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                          <span className="skeleton-box" style={{ width: 140 }} />
                          <span className="skeleton-box" style={{ width: 70 }} />
                        </div>
                      </div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                        <span className="skeleton-box" style={{ width: 110 }} />
                        <span className="skeleton-box" style={{ width: 150 }} />
                      </div>
                    </td>
                    <td><span className="skeleton-box" style={{ width: 90 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 30 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 30 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 70, height: 22, borderRadius: 16 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 80 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 60 }} /></td>
                  </tr>
                ))
              ) : agencies.length === 0 ? (
                <tr>
                  <td colSpan={9} style={{ textAlign: 'center', padding: 30, color: 'var(--text-secondary)' }}>
                    No agencies found matching criteria.
                  </td>
                </tr>
              ) : (
                  agencies.map((agency) => (
                    <tr key={agency.id}>
                      <td><input type="checkbox" className="table-checkbox" /></td>
                      <td>
                        <div className="agency-info">
                          <div className="agency-avatar">{agency.name.charAt(0)}</div>
                          <div>
                            <strong>{agency.name}</strong>
                            <span className="agency-id">{agency.agencyCode}</span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div>
                          <div>{agency.adminName}</div>
                          <small style={{ color: 'var(--text-secondary)' }}>{agency.adminEmail}</small>
                        </div>
                      </td>
                      <td>{agency.location}</td>
                      <td>{agency.propertiesCount}</td>
                      <td>{agency.dealsCount}</td>
                      <td>
                        <span className={`status-badge ${agency.status.toLowerCase()}`}>
                          {agency.status}
                        </span>
                      </td>
                      <td>{new Date(agency.createdAt).toLocaleDateString()}</td>
                      <td>
                        <div className="action-buttons">
                          {agency.status === 'Pending' && (
                            <>
                              <button className="icon-btn success" title="Approve Agency" onClick={() => openStatusConfirmModal(agency.id, agency.name, 'Active')}>
                                <CheckCircle size={18} />
                              </button>
                              <button className="icon-btn danger" title="Suspend Agency" onClick={() => openStatusConfirmModal(agency.id, agency.name, 'Suspended')}>
                                <XCircle size={18} />
                              </button>
                            </>
                          )}
                          <ActionDropdown 
                            actions={[
                              { label: 'View Full Profile', onClick: () => navigate(`/agencies/${agency.id}`) },
                              { label: 'Edit Agency Data', onClick: () => handleEditClick(agency) },
                              { label: agency.status === 'Active' ? 'Suspend Account' : 'Reactivate Account', onClick: () => openStatusConfirmModal(agency.id, agency.name, agency.status === 'Active' ? 'Suspended' : 'Active') },
                              { label: 'Delete Agency', onClick: () => openDeleteConfirmModal(agency.id, agency.name), danger: true },
                            ]} 
                          />
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
        </div>
        
        <div className="pagination">
          <span className="page-info">Total Agencies: {agencies.length}</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>

      {/* Filter Modal */}
      {showFilterModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Filter Agencies</h2>
              <button className="icon-btn" onClick={() => setShowFilterModal(false)}><X size={20} /></button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <label>Filter by Status</label>
                <select 
                  className="form-select" 
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <option value="All">All Statuses</option>
                  <option value="Active">Active</option>
                  <option value="Pending">Pending</option>
                  <option value="Suspended">Suspended</option>
                </select>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-primary" onClick={() => { setShowFilterModal(false); fetchAgencies(); }}>Apply Filters</button>
            </div>
          </div>
        </div>
      )}

      {/* Add / Onboard Agency Modal */}
      {showAddModal && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Register New Agency (India)</h2>
              <button className="icon-btn" onClick={() => setShowAddModal(false)}><X size={20} /></button>
            </div>
            
            <div className="modal-body">
              <div className="form-section">
                <h3>Agency Details</h3>
                <div className="form-grid">
                  <div className="form-group">
                    <label>Agency Name *</label>
                    <input 
                      type="text" 
                      placeholder="e.g. Skyline Realty" 
                      value={newAgency.name}
                      onChange={(e) => setNewAgency({...newAgency, name: e.target.value})}
                    />
                  </div>
                  <div className="form-group">
                    <label>RERA Registration Number</label>
                    <input 
                      type="text" 
                      placeholder="e.g. PRM/KA/RERA/..." 
                      value={newAgency.reraNumber}
                      onChange={(e) => setNewAgency({...newAgency, reraNumber: e.target.value})}
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Operating Cities / Location *</label>
                    <LiveLocationSelect
                      value={newAgency.location}
                      onChange={(val) => setNewAgency({ ...newAgency, location: val })}
                      placeholder="Search live real-world city or locality..."
                      searchPlaceholder="Type city, locality, district or PIN code..."
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Corporate Address</label>
                    <LiveLocationSelect
                      value={newAgency.address}
                      onChange={(val) => setNewAgency({ ...newAgency, address: val })}
                      placeholder="Search live street, area, building or PIN code..."
                      searchPlaceholder="Search street address, area, landmark or PIN..."
                    />
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3>Admin Details</h3>
                <div className="form-grid">
                  <div className="form-group">
                    <label>Admin Full Name *</label>
                    <input 
                      type="text" 
                      placeholder="First Last" 
                      value={newAgency.adminName}
                      onChange={(e) => setNewAgency({...newAgency, adminName: e.target.value})}
                    />
                  </div>
                  <div className="form-group">
                    <label>Phone Number</label>
                    <input 
                      type="tel" 
                      placeholder="+91 98765 43210" 
                      value={newAgency.adminPhone}
                      onChange={(e) => setNewAgency({...newAgency, adminPhone: e.target.value})}
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Admin Email Address *</label>
                    <input 
                      type="email" 
                      placeholder="admin@agency.in" 
                      value={newAgency.adminEmail}
                      onChange={(e) => setNewAgency({...newAgency, adminEmail: e.target.value})}
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Initial Admin Password (Default: agency123)</label>
                    <input 
                      type="text" 
                      placeholder="agency123" 
                      value={newAgency.password}
                      onChange={(e) => setNewAgency({...newAgency, password: e.target.value})}
                    />
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3>Platform Configuration</h3>
                <div className="form-grid">
                  <div className="form-group">
                    <label>Subscription Tier</label>
                    <select 
                      className="form-select"
                      value={newAgency.subscriptionTier}
                      onChange={(e) => setNewAgency({...newAgency, subscriptionTier: e.target.value})}
                    >
                      <option>Basic (₹2,999/mo)</option>
                      <option>Pro (₹5,999/mo)</option>
                      <option>Enterprise (₹14,999/mo)</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Initial User Quota</label>
                    <input 
                      type="number" 
                      value={newAgency.userQuota}
                      onChange={(e) => setNewAgency({...newAgency, userQuota: parseInt(e.target.value, 10) || 5})}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowAddModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleAddAgency} disabled={isActionLoading}>
                {isActionLoading ? (
                  <span className="spinner-btn-content">
                    <Loader2 size={16} className="animate-spin" />
                    <span>Onboarding Agency...</span>
                  </span>
                ) : (
                  'Register Agency'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Agency Modal */}
      {showEditModal && editingAgency && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Edit Agency Details ({editingAgency.agencyCode})</h2>
              <button className="icon-btn" onClick={() => setShowEditModal(false)}><X size={20} /></button>
            </div>
            
            <div className="modal-body">
              <div className="form-section">
                <h3>Agency Details</h3>
                <div className="form-grid">
                  <div className="form-group">
                    <label>Agency Name</label>
                    <input 
                      type="text" 
                      value={editingAgency.name}
                      onChange={(e) => setEditingAgency({...editingAgency, name: e.target.value})}
                    />
                  </div>
                  <div className="form-group">
                    <label>RERA Registration Number</label>
                    <input 
                      type="text" 
                      value={editingAgency.reraNumber || ''}
                      onChange={(e) => setEditingAgency({...editingAgency, reraNumber: e.target.value})}
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Operating Cities / Location</label>
                    <LiveLocationSelect
                      value={editingAgency.location}
                      onChange={(val) => setEditingAgency({ ...editingAgency, location: val })}
                      placeholder="Search live real-world city or locality..."
                      searchPlaceholder="Type city, locality, district or PIN code..."
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Corporate Address</label>
                    <LiveLocationSelect
                      value={editingAgency.address || ''}
                      onChange={(val) => setEditingAgency({ ...editingAgency, address: val })}
                      placeholder="Search live street, area, building or PIN code..."
                      searchPlaceholder="Search street address, area, landmark or PIN..."
                    />
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3>Admin Details</h3>
                <div className="form-grid">
                  <div className="form-group">
                    <label>Admin Full Name</label>
                    <input 
                      type="text" 
                      value={editingAgency.adminName}
                      onChange={(e) => setEditingAgency({...editingAgency, adminName: e.target.value})}
                    />
                  </div>
                  <div className="form-group">
                    <label>Phone Number</label>
                    <input 
                      type="tel" 
                      value={editingAgency.adminPhone || ''}
                      onChange={(e) => setEditingAgency({...editingAgency, adminPhone: e.target.value})}
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Admin Email Address</label>
                    <input 
                      type="email" 
                      value={editingAgency.adminEmail}
                      onChange={(e) => setEditingAgency({...editingAgency, adminEmail: e.target.value})}
                    />
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3>Platform Configuration</h3>
                <div className="form-grid">
                  <div className="form-group">
                    <label>Subscription Tier</label>
                    <select 
                      className="form-select"
                      value={editingAgency.subscriptionTier}
                      onChange={(e) => setEditingAgency({...editingAgency, subscriptionTier: e.target.value})}
                    >
                      <option>Basic (₹2,999/mo)</option>
                      <option>Pro (₹5,999/mo)</option>
                      <option>Enterprise (₹14,999/mo)</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>User Quota</label>
                    <input 
                      type="number" 
                      value={editingAgency.userQuota}
                      onChange={(e) => setEditingAgency({...editingAgency, userQuota: parseInt(e.target.value, 10) || 5})}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowEditModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleSaveEditAgency} disabled={isActionLoading}>
                {isActionLoading ? (
                  <span className="spinner-btn-content">
                    <Loader2 size={16} className="animate-spin" />
                    <span>Saving Changes...</span>
                  </span>
                ) : (
                  'Save Changes'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Onboarded Credentials Success Modal */}
      {onboardedCredentials && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <CheckCircle size={24} color="#16a34a" />
                <h2>Agency Onboarded Successfully!</h2>
              </div>
              <button className="icon-btn" onClick={() => setOnboardedCredentials(null)}><X size={20} /></button>
            </div>
            
            <div className="modal-body" style={{ padding: '20px 24px' }}>
              <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 16 }}>
                Share these initial credentials with the agency owner to log into the PropConnect App and Web Admin Panel.
              </p>

              <div style={{ backgroundColor: '#f8fafc', border: '1px solid var(--border)', borderRadius: 8, padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Agency Name & Code:</span>
                  <strong style={{ fontSize: 13 }}>{onboardedCredentials.agencyName} ({onboardedCredentials.agencyCode})</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Admin Owner Name:</span>
                  <strong style={{ fontSize: 13 }}>{onboardedCredentials.adminName}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Login Email:</span>
                  <code style={{ fontSize: 13, fontFamily: 'monospace', color: 'var(--primary-blue)', background: '#e0f2fe', padding: '2px 8px', borderRadius: 4 }}>{onboardedCredentials.adminEmail}</code>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Initial Security Password:</span>
                  <code style={{ fontSize: 13, fontFamily: 'monospace', color: '#16a34a', background: '#dcfce7', padding: '2px 8px', borderRadius: 4 }}>{onboardedCredentials.password}</code>
                </div>
              </div>
            </div>

            <div className="modal-footer" style={{ justifyContent: 'space-between' }}>
              <button className="btn-secondary" onClick={() => setOnboardedCredentials(null)}>Close</button>
              <button className="btn-primary" onClick={copyWhatsAppCredentials} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <Copy size={16} /> Copy WhatsApp Message
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
        isLoading={isActionLoading}
        onConfirm={confirmModal.onConfirm}
        onCancel={() => setConfirmModal((prev) => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
}
