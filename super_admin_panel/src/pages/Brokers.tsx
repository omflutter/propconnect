import { useState, useEffect } from 'react';
import { Search, Filter, User, Mail, Phone, X, Loader2, Download, Building2, UserPlus } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { ConfirmModal } from '../components/ConfirmModal';
import { SearchableSelect, SelectOption } from '../components/SearchableSelect';
import { apiFetch } from '../services/api';
import './GlobalData.css';

export interface BrokerUser {
  id: number;
  name: string;
  email: string;
  phone?: string;
  role: 'broker' | 'agency_admin' | 'super_admin';
  adminRoleTitle?: string;
  status: 'Active' | 'Suspended';
  createdAt: string;
  agency?: {
    id: number;
    agencyCode: string;
    name: string;
    location: string;
  };
}

export interface AgencySimple {
  id: number;
  agencyCode: string;
  name: string;
}

export function Brokers() {
  const [showAddModal, setShowAddModal] = useState(false);
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [agencyFilter, setAgencyFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isActionLoading, setIsActionLoading] = useState(false);

  // Data lists
  const [brokers, setBrokers] = useState<BrokerUser[]>([]);
  const [agencies, setAgencies] = useState<AgencySimple[]>([]);

  // New Broker Form
  const [newBroker, setNewBroker] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'broker',
    agencyId: '',
    password: 'broker123',
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

  const fetchAgenciesList = async () => {
    const res = await apiFetch<AgencySimple[]>('/agencies');
    if (res.success && res.data && res.data.length > 0) {
      setAgencies(res.data);
      if (!newBroker.agencyId) {
        setNewBroker((prev) => ({ ...prev, agencyId: String(res.data![0].id) }));
      }
    }
  };

  const fetchBrokers = async () => {
    setIsLoading(true);
    const queryParams: string[] = [];
    if (statusFilter !== 'All') queryParams.push(`status=${statusFilter}`);
    if (agencyFilter !== 'All') queryParams.push(`agencyId=${agencyFilter}`);
    if (searchQuery) queryParams.push(`search=${encodeURIComponent(searchQuery)}`);

    let url = '/brokers';
    if (queryParams.length > 0) {
      url += `?${queryParams.join('&')}`;
    }

    const res = await apiFetch<BrokerUser[]>(url);
    setIsLoading(false);

    if (res.success && res.data) {
      setBrokers(res.data);
    } else {
      toast.error(res.message || 'Failed to fetch brokers');
    }
  };

  useEffect(() => {
    fetchAgenciesList();
  }, []);

  useEffect(() => {
    fetchBrokers();
  }, [statusFilter, agencyFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchBrokers();
  };

  const openStatusConfirmModal = (id: number, name: string, currentStatus: 'Active' | 'Suspended') => {
    const isSuspending = currentStatus === 'Active';
    const newStatus = isSuspending ? 'Suspended' : 'Active';

    setConfirmModal({
      isOpen: true,
      title: isSuspending ? 'Suspend Broker Access' : 'Reactivate Broker Account',
      message: isSuspending
        ? `Are you sure you want to suspend "${name}"? They will not be able to log in or access properties and deals.`
        : `Reactivate platform access for "${name}"?`,
      type: isSuspending ? 'warning' : 'success',
      confirmText: isSuspending ? 'Suspend Broker' : 'Reactivate Broker',
      onConfirm: async () => {
        setIsActionLoading(true);
        const res = await apiFetch(`/brokers/${id}/status`, {
          method: 'PATCH',
          body: JSON.stringify({ status: newStatus }),
        });
        setIsActionLoading(false);

        if (res.success) {
          toast.success(`Broker "${name}" status updated to ${newStatus}`);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          fetchBrokers();
        } else {
          toast.error(res.message || 'Status update failed');
        }
      },
    });
  };

  const openDeleteConfirmModal = (id: number, name: string) => {
    setConfirmModal({
      isOpen: true,
      title: 'Delete Broker User',
      message: `Are you sure you want to permanently delete broker "${name}"? Their account records will be removed from MySQL.`,
      type: 'danger',
      confirmText: 'Delete Broker',
      onConfirm: async () => {
        setIsActionLoading(true);
        const res = await apiFetch(`/brokers/${id}`, {
          method: 'DELETE',
        });
        setIsActionLoading(false);

        if (res.success) {
          toast.success(`Broker user "${name}" deleted permanently.`);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          fetchBrokers();
        } else {
          toast.error(res.message || 'Failed to delete broker');
        }
      },
    });
  };

  const handleAddBroker = async () => {
    if (!newBroker.name || !newBroker.email || !newBroker.agencyId) {
      toast.error('Broker Name, Email, and Target Agency are required.');
      return;
    }

    setIsActionLoading(true);
    const res = await apiFetch('/brokers', {
      method: 'POST',
      body: JSON.stringify(newBroker),
    });
    setIsActionLoading(false);

    if (res.success) {
      toast.success(res.message || `Broker ${newBroker.name} registered!`, { duration: 6000 });
      setShowAddModal(false);
      setNewBroker({
        name: '',
        email: '',
        phone: '',
        role: 'broker',
        agencyId: agencies.length > 0 ? String(agencies[0].id) : '',
        password: 'broker123',
      });
      fetchBrokers();
    } else {
      toast.error(res.message || 'Failed to add broker');
    }
  };

  const handleExportCSV = () => {
    if (!brokers || brokers.length === 0) {
      toast.error('No broker records available to export.');
      return;
    }

    const headers = [
      'Broker ID',
      'Full Name',
      'Email Address',
      'Phone Number',
      'Role Title',
      'Associated Agency Code',
      'Associated Agency Name',
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
      ...brokers.map((b) =>
        [
          escapeCSV(`BR-${b.id}`),
          escapeCSV(b.name),
          escapeCSV(b.email),
          escapeCSV(b.phone || 'N/A'),
          escapeCSV(b.role === 'agency_admin' ? 'Agency Tenant Admin' : 'Registered Broker'),
          escapeCSV(b.agency ? b.agency.agencyCode : 'N/A'),
          escapeCSV(b.agency ? b.agency.name : 'N/A'),
          escapeCSV(b.status),
          escapeCSV(new Date(b.createdAt).toLocaleDateString()),
        ].join(',')
      ),
    ];

    const csvContent = '\uFEFF' + csvRows.join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    const dateStr = new Date().toISOString().split('T')[0];
    link.setAttribute('href', url);
    link.setAttribute('download', `PropConnect_Brokers_Export_${dateStr}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success(`Exported ${brokers.length} broker records to CSV successfully!`);
  };

  // Convert agencies to SearchableSelect options
  const agencyFilterOptions: SelectOption[] = [
    { value: 'All', label: `All Agencies (${agencies.length})` },
    ...agencies.map((ag) => ({
      value: String(ag.id),
      label: ag.name,
      subLabel: ag.agencyCode,
    })),
  ];

  const modalAgencyOptions: SelectOption[] = agencies.map((ag) => ({
    value: String(ag.id),
    label: ag.name,
    subLabel: ag.agencyCode,
  }));

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Platform Brokers</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage multi-tenant broker profiles, onboard new users, and search & filter across 100+ agencies.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={handleExportCSV}>
            <Download size={14} style={{ marginRight: 6 }} /> Export CSV
          </button>
          <button className="btn-primary" onClick={() => setShowAddModal(true)}>
            <UserPlus size={14} style={{ marginRight: 6 }} /> + Onboard Broker
          </button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)', flexWrap: 'wrap', gap: 12 }}>
          {/* Status Tabs */}
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Brokers</button>
            <button className={statusFilter === 'Active' ? 'active' : ''} onClick={() => setStatusFilter('Active')}>Active</button>
            <button className={statusFilter === 'Suspended' ? 'active' : ''} onClick={() => setStatusFilter('Suspended')}>Suspended</button>
          </div>

          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            {/* Searchable Agency Dropdown Filter (Handles 100+ Agencies) */}
            <SearchableSelect 
              options={agencyFilterOptions}
              value={agencyFilter}
              onChange={(val) => setAgencyFilter(val)}
              searchPlaceholder="Search 100+ agencies..."
            />

            {/* Search Box */}
            <form onSubmit={handleSearchSubmit} style={{ display: 'flex', gap: 12 }}>
              <div className="search-box">
                <Search className="search-icon" size={16} />
                <input 
                  type="text" 
                  placeholder="Search brokers..." 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <button type="button" className="btn-secondary filter-btn" onClick={() => setShowFilterModal(true)}>
                <Filter size={16} /> Filters
              </button>
            </form>
          </div>
        </div>

        <div className="table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                <th>Broker Name</th>
                <th>Contact Info</th>
                <th>Role</th>
                <th>Associated Agency</th>
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
                      <div className="entity-info">
                        <span className="skeleton-box" style={{ width: 36, height: 36, borderRadius: 8 }} />
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                          <span className="skeleton-box" style={{ width: 120 }} />
                          <span className="skeleton-box" style={{ width: 60 }} />
                        </div>
                      </div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                        <span className="skeleton-box" style={{ width: 140 }} />
                        <span className="skeleton-box" style={{ width: 100 }} />
                      </div>
                    </td>
                    <td><span className="skeleton-box" style={{ width: 80 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 130 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 70, height: 22, borderRadius: 16 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 80 }} /></td>
                    <td><span className="skeleton-box" style={{ width: 60 }} /></td>
                  </tr>
                ))
              ) : brokers.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: 30, color: 'var(--text-secondary)' }}>
                    No brokers found matching current filters.
                  </td>
                </tr>
              ) : (
                  brokers.map((broker) => (
                    <tr key={broker.id}>
                      <td><input type="checkbox" className="table-checkbox" /></td>
                      <td>
                        <div className="entity-info">
                          <div className="entity-avatar"><User size={18} /></div>
                          <div>
                            <strong>{broker.name}</strong>
                            <span className="entity-sub">BR-{String(broker.id).padStart(3, '0')}</span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                          <span className="entity-sub"><Mail size={12} style={{ display: 'inline', marginRight: 4 }} /> {broker.email}</span>
                          <span className="entity-sub"><Phone size={12} style={{ display: 'inline', marginRight: 4 }} /> {broker.phone || 'N/A'}</span>
                        </div>
                      </td>
                      <td>
                        <span style={{ fontSize: 13, fontWeight: broker.role === 'agency_admin' ? 600 : 400 }}>
                          {broker.role === 'agency_admin' ? 'Agency Admin' : 'Broker'}
                        </span>
                      </td>
                      <td>
                        {broker.agency ? (
                          <span className="agency-tag">{broker.agency.name} ({broker.agency.agencyCode})</span>
                        ) : (
                          <span className="entity-sub">Independent / None</span>
                        )}
                      </td>
                      <td>
                        <span className={`status-badge ${broker.status.toLowerCase()}`}>
                          {broker.status}
                        </span>
                      </td>
                      <td><span className="entity-sub">{new Date(broker.createdAt).toLocaleDateString()}</span></td>
                      <td>
                        <div className="action-buttons">
                          <ActionDropdown 
                            actions={[
                              { label: 'View Profile Details', onClick: () => toast.success(`Viewing profile for ${broker.name}`) },
                              { label: broker.status === 'Active' ? 'Suspend Broker' : 'Reactivate Broker', onClick: () => openStatusConfirmModal(broker.id, broker.name, broker.status) },
                              { label: 'Delete Broker User', onClick: () => openDeleteConfirmModal(broker.id, broker.name), danger: true },
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
          <span className="page-info">Total Brokers: {brokers.length}</span>
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
              <h2>Filter Brokers</h2>
              <button className="icon-btn" onClick={() => setShowFilterModal(false)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="form-group">
                <label>Filter by Status</label>
                <select 
                  className="form-select" 
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <option value="All">All Statuses</option>
                  <option value="Active">Active</option>
                  <option value="Suspended">Suspended</option>
                </select>
              </div>

              <div className="form-group">
                <label>Filter by Target Agency</label>
                <SearchableSelect 
                  options={agencyFilterOptions}
                  value={agencyFilter}
                  onChange={(val) => setAgencyFilter(val)}
                  searchPlaceholder="Search 100+ agencies..."
                  style={{ width: '100%' }}
                />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-primary" onClick={() => { setShowFilterModal(false); fetchBrokers(); }}>Apply Filters</button>
            </div>
          </div>
        </div>
      )}

      {/* Onboard Platform Broker Modal */}
      {showAddModal && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Onboard Platform Broker User</h2>
              <button className="icon-btn" onClick={() => setShowAddModal(false)}><X size={20} /></button>
            </div>
            
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Full Name *</label>
                  <input 
                    type="text" 
                    placeholder="e.g. Amit Singh" 
                    value={newBroker.name}
                    onChange={(e) => setNewBroker({...newBroker, name: e.target.value})}
                  />
                </div>
                <div className="form-group">
                  <label>Email Address *</label>
                  <input 
                    type="email" 
                    placeholder="amit@sunrise.in" 
                    value={newBroker.email}
                    onChange={(e) => setNewBroker({...newBroker, email: e.target.value})}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Phone Number</label>
                  <input 
                    type="tel" 
                    placeholder="+91 99887 76655" 
                    value={newBroker.phone}
                    onChange={(e) => setNewBroker({...newBroker, phone: e.target.value})}
                  />
                </div>
                <div className="form-group">
                  <label>Initial Login Password</label>
                  <input 
                    type="password" 
                    value={newBroker.password}
                    onChange={(e) => setNewBroker({...newBroker, password: e.target.value})}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Target SaaS Agency *</label>
                  <SearchableSelect 
                    options={modalAgencyOptions}
                    value={newBroker.agencyId}
                    onChange={(val) => setNewBroker({ ...newBroker, agencyId: val })}
                    searchPlaceholder="Search target agency..."
                    style={{ width: '100%' }}
                  />
                </div>

                <div className="form-group">
                  <label>User Role</label>
                  <select 
                    className="form-select"
                    value={newBroker.role}
                    onChange={(e) => setNewBroker({...newBroker, role: e.target.value})}
                  >
                    <option value="broker">Registered Broker</option>
                    <option value="agency_admin">Agency Tenant Admin</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowAddModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleAddBroker} disabled={isActionLoading}>
                {isActionLoading ? (
                  <span className="spinner-btn-content">
                    <Loader2 size={16} className="animate-spin" />
                    <span>Onboarding Broker...</span>
                  </span>
                ) : (
                  'Onboard Broker User'
                )}
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
