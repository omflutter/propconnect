import { useState } from 'react';
import { Search, Filter, CheckCircle, XCircle, Plus, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './Agencies.css';

export function Agencies() {
  const navigate = useNavigate();
  const [showAddModal, setShowAddModal] = useState(false);
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [agencies, setAgencies] = useState([
    { id: 'AG-001', name: 'Sunrise Properties', admin: 'Om Shivam', properties: 45, deals: 12, status: 'Active', date: '2026-06-15', location: 'Mumbai' },
    { id: 'AG-002', name: 'Metro Reality India', admin: 'Rajesh Kumar', properties: 128, deals: 34, status: 'Active', date: '2026-05-20', location: 'Delhi NCR' },
    { id: 'AG-003', name: 'Bangalore Estates', admin: 'Priya Sharma', properties: 0, deals: 0, status: 'Pending', date: '2026-07-22', location: 'Bangalore' },
    { id: 'AG-004', name: 'Luxury Villas LLC', admin: 'Amit Patel', properties: 12, deals: 2, status: 'Suspended', date: '2026-01-10', location: 'Pune' },
    { id: 'AG-005', name: 'Koramangala Brokers', admin: 'Vikram Singh', properties: 67, deals: 19, status: 'Active', date: '2026-03-05', location: 'Bangalore' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');
  const [newAgency, setNewAgency] = useState({
    name: '',
    admin: '',
    location: '',
  });

  const handleApprove = (id: string) => {
    setAgencies(agencies.map(a => a.id === id ? { ...a, status: 'Active' } : a));
    toast.success('Agency approved successfully!');
  };

  const handleReject = (id: string) => {
    setAgencies(agencies.filter(a => a.id !== id));
    toast.error('Agency application rejected.');
  };

  const handleAddAgency = () => {
    if (!newAgency.name || !newAgency.admin) {
      toast.error('Please fill in required fields.');
      return;
    }
    
    const newEntry = {
      id: `AG-00${agencies.length + 1}`,
      name: newAgency.name,
      admin: newAgency.admin,
      location: newAgency.location || 'Pan India',
      properties: 0,
      deals: 0,
      status: 'Active',
      date: new Date().toISOString().split('T')[0]
    };
    
    setAgencies([newEntry, ...agencies]);
    setShowAddModal(false);
    setNewAgency({ name: '', admin: '', location: '' });
    toast.success(`${newAgency.name} has been registered!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Agencies Matrix</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage and monitor all multi-tenant SaaS agencies on the PropConnect platform.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary">Export CSV</button>
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

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search agencies..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <button className="btn-secondary filter-btn" onClick={() => setShowFilterModal(true)}>
              <Filter size={16} /> Filters
            </button>
          </div>
        </div>

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
              {agencies
                .filter(a => a.name.toLowerCase().includes(searchQuery.toLowerCase()) || a.location.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(a => statusFilter === 'All' ? true : a.status === statusFilter)
                .map((agency) => (
                <tr key={agency.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="agency-info">
                      <div className="agency-avatar">{agency.name.charAt(0)}</div>
                      <div>
                        <strong>{agency.name}</strong>
                        <span className="agency-id">{agency.id}</span>
                      </div>
                    </div>
                  </td>
                  <td>{agency.admin}</td>
                  <td>{agency.location}</td>
                  <td>{agency.properties}</td>
                  <td>{agency.deals}</td>
                  <td>
                    <span className={`status-badge ${agency.status.toLowerCase()}`}>
                      {agency.status}
                    </span>
                  </td>
                  <td>{agency.date}</td>
                  <td>
                    <div className="action-buttons">
                      {agency.status === 'Pending' && (
                        <>
                          <button className="icon-btn success" title="Approve" onClick={() => handleApprove(agency.id)}>
                            <CheckCircle size={18} />
                          </button>
                          <button className="icon-btn danger" title="Reject" onClick={() => handleReject(agency.id)}>
                            <XCircle size={18} />
                          </button>
                        </>
                      )}
                      <ActionDropdown 
                        actions={[
                          { label: 'View Full Profile', onClick: () => navigate(`/agencies/${agency.id}`) },
                          { label: 'Edit Agency Data', onClick: () => toast.success('Edit mode enabled') },
                          { label: 'Suspend Account', onClick: () => handleReject(agency.id), danger: true },
                        ]} 
                      />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        <div className="pagination">
          <span className="page-info">Showing results for filter: {statusFilter}</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>

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
              <button className="btn-primary" onClick={() => setShowFilterModal(false)}>Apply Filters</button>
            </div>
          </div>
        </div>
      )}

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
                    <label>RERA Registration Number *</label>
                    <input type="text" placeholder="e.g. PRM/KA/RERA/..." />
                  </div>
                  <div className="form-group full-width">
                    <label>Operating Cities</label>
                    <input 
                      type="text" 
                      placeholder="e.g. Mumbai, Pune" 
                      value={newAgency.location}
                      onChange={(e) => setNewAgency({...newAgency, location: e.target.value})}
                    />
                  </div>
                  <div className="form-group full-width">
                    <label>Corporate Address</label>
                    <input type="text" placeholder="Street, Area, City, PIN" />
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
                      value={newAgency.admin}
                      onChange={(e) => setNewAgency({...newAgency, admin: e.target.value})}
                    />
                  </div>
                  <div className="form-group">
                    <label>Phone Number *</label>
                    <input type="tel" placeholder="+91 98765 43210" />
                  </div>
                  <div className="form-group full-width">
                    <label>Admin Email Address *</label>
                    <input type="email" placeholder="admin@agency.in" />
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3>Platform Configuration</h3>
                <div className="form-grid">
                  <div className="form-group">
                    <label>Subscription Tier</label>
                    <select className="form-select">
                      <option>Basic (₹2,999/mo)</option>
                      <option>Pro (₹5,999/mo)</option>
                      <option>Enterprise (₹14,999/mo)</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Initial User Quota</label>
                    <input type="number" defaultValue={5} />
                  </div>
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowAddModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleAddAgency}>Register Agency</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
