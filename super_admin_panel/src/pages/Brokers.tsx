import { useState } from 'react';
import { Search, Filter, MoreVertical, User, Mail, Phone, ShieldBan, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';

export function Brokers() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [brokers, setBrokers] = useState([
    { id: 'BR-101', name: 'Om Shivam', email: 'om@sunrise.in', phone: '+91 98765 43210', role: 'Agency Admin', agency: 'Sunrise Properties', status: 'Active' },
    { id: 'BR-102', name: 'Rajesh Kumar', email: 'rajesh@metro.in', phone: '+91 91234 56789', role: 'Agency Admin', agency: 'Metro Reality India', status: 'Active' },
    { id: 'BR-103', name: 'Amit Singh', email: 'amit@sunrise.in', phone: '+91 99887 76655', role: 'Broker', agency: 'Sunrise Properties', status: 'Active' },
    { id: 'BR-104', name: 'Priya Sharma', email: 'priya@bangalore.in', phone: '+91 90011 22334', role: 'Agency Admin', agency: 'Bangalore Estates', status: 'Suspended' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');

  const handleSuspend = (id: string) => {
    setBrokers(brokers.map(b => b.id === id ? { ...b, status: 'Suspended' } : b));
    toast.error(`Broker ${id} has been suspended.`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Platform Brokers</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage permissions, access, and status of all brokers.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary">Export Users</button>
          <button className="btn-primary">+ Add Platform User</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Brokers</button>
            <button className={statusFilter === 'Active' ? 'active' : ''} onClick={() => setStatusFilter('Active')}>Active</button>
            <button className={statusFilter === 'Suspended' ? 'active' : ''} onClick={() => setStatusFilter('Suspended')}>Suspended</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search brokers..." 
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
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                <th>Broker</th>
                <th>Contact</th>
                <th>Role</th>
                <th>Agency</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {brokers
                .filter(b => b.name.toLowerCase().includes(searchQuery.toLowerCase()) || b.email.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(b => statusFilter === 'All' ? true : b.status === statusFilter)
                .map((broker) => (
                <tr key={broker.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div className="entity-avatar"><User size={20} /></div>
                      <div>
                        <strong>{broker.name}</strong>
                        <span className="entity-sub">{broker.id}</span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                      <span className="entity-sub"><Mail size={12} style={{ marginRight: 4 }} /> {broker.email}</span>
                      <span className="entity-sub"><Phone size={12} style={{ marginRight: 4 }} /> {broker.phone}</span>
                    </div>
                  </td>
                  <td>
                    <span style={{ fontSize: 13, fontWeight: broker.role === 'Agency Admin' ? 600 : 400 }}>
                      {broker.role}
                    </span>
                  </td>
                  <td><span className="agency-tag">{broker.agency}</span></td>
                  <td>
                    <span className={`status-badge ${broker.status.toLowerCase()}`}>
                      {broker.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Profile', onClick: () => toast.success(`Viewing ${broker.name}`) },
                          { label: 'Reset Password', onClick: () => toast.success('Password reset link sent') },
                          { label: 'Suspend Broker', onClick: () => handleSuspend(broker.id), danger: true },
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
              <h2>Filter Brokers</h2>
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
    </div>
  );
}
