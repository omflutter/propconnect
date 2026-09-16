import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Mail, Phone, ShieldCheck, Building2, Users, Briefcase, Loader2, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { apiFetch } from '../services/api';
import { ConfirmModal } from '../components/ConfirmModal';
import './AgencyProfile.css';

export function AgencyProfile() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [agency, setAgency] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isActionLoading, setIsActionLoading] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingAgency, setEditingAgency] = useState<any>(null);

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

  const fetchAgencyProfile = async () => {
    if (!id) return;
    setIsLoading(true);
    const res = await apiFetch(`/agencies/${id}`);
    setIsLoading(false);

    if (res.success && res.data) {
      setAgency(res.data);
      setEditingAgency(res.data);
    } else {
      toast.error(res.message || 'Failed to fetch agency profile');
    }
  };

  useEffect(() => {
    fetchAgencyProfile();
  }, [id]);

  const openStatusConfirmModal = () => {
    if (!agency) return;
    const isSuspending = agency.status === 'Active';
    const newStatus = isSuspending ? 'Suspended' : 'Active';

    setConfirmModal({
      isOpen: true,
      title: isSuspending ? 'Suspend Agency Account' : 'Reactivate Agency Account',
      message: isSuspending
        ? `Are you sure you want to suspend "${agency.name}"? Their agency admin and brokers will not be able to log in or access platform features while suspended.`
        : `Reactivate "${agency.name}" and restore full platform access for all registered brokers?`,
      type: isSuspending ? 'warning' : 'success',
      confirmText: isSuspending ? 'Suspend Account' : 'Reactivate Agency',
      onConfirm: async () => {
        setIsActionLoading(true);
        const res = await apiFetch(`/agencies/${agency.id}/status`, {
          method: 'PATCH',
          body: JSON.stringify({ status: newStatus }),
        });
        setIsActionLoading(false);

        if (res.success) {
          toast.success(`Agency status updated to ${newStatus}`);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          fetchAgencyProfile();
        } else {
          toast.error(res.message || 'Status update failed');
        }
      },
    });
  };

  const handleSaveEdit = async () => {
    if (!editingAgency) return;

    setIsActionLoading(true);
    const res = await apiFetch(`/agencies/${editingAgency.id}`, {
      method: 'PUT',
      body: JSON.stringify(editingAgency),
    });
    setIsActionLoading(false);

    if (res.success) {
      toast.success('Agency profile updated successfully.');
      setShowEditModal(false);
      fetchAgencyProfile();
    } else {
      toast.error(res.message || 'Update failed');
    }
  };

  if (isLoading && !agency) {
    return (
      <div className="profile-page" style={{ opacity: 0.9 }}>
        <div className="page-header profile-header-actions">
          <button className="btn-icon-text" disabled>
            <ArrowLeft size={18} />
            Back to Agencies
          </button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--primary-blue)', fontSize: 13, fontWeight: 600 }}>
            <Loader2 className="animate-spin" size={18} />
            <span>Fetching Live Agency Profile from PostgreSQL...</span>
          </div>
        </div>

        <div className="profile-hero card" style={{ padding: 24, display: 'flex', gap: 20, alignItems: 'center' }}>
          <span className="skeleton-box" style={{ width: 72, height: 72, borderRadius: 16 }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, flex: 1 }}>
            <span className="skeleton-box" style={{ width: 240, height: 26, borderRadius: 6 }} />
            <div style={{ display: 'flex', gap: 16 }}>
              <span className="skeleton-box" style={{ width: 130, height: 16, borderRadius: 4 }} />
              <span className="skeleton-box" style={{ width: 180, height: 16, borderRadius: 4 }} />
            </div>
          </div>
        </div>

        <div className="stats-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginTop: 24 }}>
          {[1, 2, 3, 4].map((idx) => (
            <div key={idx} className="card" style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 10 }}>
              <span className="skeleton-box" style={{ width: 60, height: 28, borderRadius: 6 }} />
              <span className="skeleton-box" style={{ width: 120, height: 14, borderRadius: 4 }} />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (!agency) {
    return (
      <div className="profile-page">
        <button className="btn-icon-text" onClick={() => navigate('/agencies')}>
          <ArrowLeft size={18} />
          Back to Agencies
        </button>
        <div style={{ marginTop: 24, textAlign: 'center', color: 'var(--text-secondary)' }}>
          Agency profile not found.
        </div>
      </div>
    );
  }

  return (
    <div className="profile-page">
      <div className="page-header profile-header-actions">
        <button className="btn-icon-text" onClick={() => navigate('/agencies')}>
          <ArrowLeft size={18} />
          Back to Agencies
        </button>
      </div>

      <div className="profile-hero card">
        <div className="hero-content">
          <div className="profile-avatar large">
            {agency.name.charAt(0)}
          </div>
          <div className="hero-info">
            <div className="title-row">
              <h1>{agency.name}</h1>
              <span className={`status-badge ${agency.status ? agency.status.toLowerCase() : 'active'}`}>{agency.status}</span>
            </div>
            <div className="meta-row">
              <span className="meta-item"><MapPin size={14} /> {agency.location}</span>
              <span className="meta-item"><ShieldCheck size={14} /> RERA: {agency.reraNumber || 'N/A'}</span>
            </div>
          </div>
        </div>
        <div className="hero-actions">
          <button className="btn-secondary" onClick={() => setShowEditModal(true)}>Edit Profile</button>
          <button 
            className={`btn-secondary ${agency.status === 'Active' ? 'danger-text' : ''}`}
            onClick={openStatusConfirmModal}
          >
            {agency.status === 'Active' ? 'Suspend Agency' : 'Reactivate Agency'}
          </button>
        </div>
      </div>

      <div className="stats-grid">
        <div className="stat-card card">
          <div className="stat-header">
            <div className="stat-icon-wrapper" style={{ backgroundColor: '#10b98115' }}>
              <Building2 className="stat-icon" style={{ color: '#10b981' }} />
            </div>
          </div>
          <div className="stat-info">
            <h3 className="stat-value">{agency.propertiesCount || 0}</h3>
            <span className="stat-label">Active Properties</span>
          </div>
        </div>
        <div className="stat-card card">
          <div className="stat-header">
            <div className="stat-icon-wrapper" style={{ backgroundColor: '#f59e0b15' }}>
              <Briefcase className="stat-icon" style={{ color: '#f59e0b' }} />
            </div>
          </div>
          <div className="stat-info">
            <h3 className="stat-value">{agency.dealsCount || 0}</h3>
            <span className="stat-label">Closed Deals</span>
          </div>
        </div>
        <div className="stat-card card">
          <div className="stat-header">
            <div className="stat-icon-wrapper" style={{ backgroundColor: '#3b82f615' }}>
              <Users className="stat-icon" style={{ color: '#3b82f6' }} />
            </div>
          </div>
          <div className="stat-info">
            <h3 className="stat-value">{agency.brokersCount || (agency.users ? agency.users.length : 0)}</h3>
            <span className="stat-label">Registered Users / Brokers</span>
          </div>
        </div>
      </div>

      <div className="profile-details-grid">
        <div className="card details-card">
          <h3>Admin Contact Information</h3>
          <ul className="details-list">
            <li>
              <span className="detail-label">Full Name</span>
              <span className="detail-value">{agency.adminName}</span>
            </li>
            <li>
              <span className="detail-label"><Mail size={14} style={{ display: 'inline', marginRight: 4 }}/> Email</span>
              <span className="detail-value">{agency.adminEmail}</span>
            </li>
            <li>
              <span className="detail-label"><Phone size={14} style={{ display: 'inline', marginRight: 4 }}/> Phone</span>
              <span className="detail-value">{agency.adminPhone || 'N/A'}</span>
            </li>
            <li>
              <span className="detail-label">Corporate Address</span>
              <span className="detail-value">{agency.address || 'N/A'}</span>
            </li>
          </ul>
        </div>
        <div className="card details-card">
          <h3>Platform Details</h3>
          <ul className="details-list">
            <li>
              <span className="detail-label">Subscription Tier</span>
              <span className="detail-value">{agency.subscriptionTier}</span>
            </li>
            <li>
              <span className="detail-label">User Quota Limit</span>
              <span className="detail-value">{agency.userQuota} Seats</span>
            </li>
            <li>
              <span className="detail-label">Join Date</span>
              <span className="detail-value">{new Date(agency.createdAt).toLocaleDateString()}</span>
            </li>
            <li>
              <span className="detail-label">Agency Code</span>
              <span className="detail-value">{agency.agencyCode}</span>
            </li>
          </ul>
        </div>
      </div>

      {/* Edit Agency Profile Modal */}
      {showEditModal && editingAgency && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <h2>Edit Profile ({editingAgency.agencyCode})</h2>
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
                    <input 
                      type="text" 
                      value={editingAgency.location}
                      onChange={(e) => setEditingAgency({...editingAgency, location: e.target.value})}
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Corporate Address</label>
                    <input 
                      type="text" 
                      value={editingAgency.address || ''}
                      onChange={(e) => setEditingAgency({...editingAgency, address: e.target.value})}
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
              <button className="btn-primary" onClick={handleSaveEdit} disabled={isActionLoading}>
                {isActionLoading ? <Loader2 size={16} className="animate-spin" /> : 'Save Profile'}
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
