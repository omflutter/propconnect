import { useState } from 'react';
import { Search, Filter, MoreVertical, Building2, MapPin, Trash2, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';

export function Properties() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [properties, setProperties] = useState([
    { id: 'PR-104', title: 'Sea Face Villa', location: 'Bandra West, Mumbai', price: '₹4.2 Cr', agency: 'Sunrise Properties', type: 'Sale', status: 'Available' },
    { id: 'PR-105', title: 'DLF Cyber City Office', location: 'Gurugram, Delhi NCR', price: '₹8.5 Cr', agency: 'Metro Reality India', type: 'Sale', status: 'Under Offer' },
    { id: 'PR-106', title: 'Koramangala Condo', location: 'Bangalore', price: '₹85 Lakhs', agency: 'Bangalore Estates', type: 'Sale', status: 'Available' },
    { id: 'PR-107', title: 'IT Park Space', location: 'Hinjewadi, Pune', price: '₹1.2 Lakhs/mo', agency: 'Sunrise Properties', type: 'Rent', status: 'Available' },
    { id: 'PR-108', title: 'Andheri East Apartment', location: 'Mumbai', price: '₹1.5 Cr', agency: 'Sunrise Properties', type: 'Sale', status: 'Sold' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');

  const handleDelete = (id: string) => {
    setProperties(properties.filter(p => p.id !== id));
    toast.success(`Property ${id} removed globally.`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Global Inventory</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Monitor all public and private property listings across the platform.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary">Export Data</button>
          <button className="btn-primary">+ Add Global Property</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Properties</button>
            <button className={statusFilter === 'Available' ? 'active' : ''} onClick={() => setStatusFilter('Available')}>Available</button>
            <button className={statusFilter === 'Under Offer' ? 'active' : ''} onClick={() => setStatusFilter('Under Offer')}>Under Offer</button>
            <button className={statusFilter === 'Sold' ? 'active' : ''} onClick={() => setStatusFilter('Sold')}>Sold</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search properties..." 
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
                <th>Property</th>
                <th>Agency</th>
                <th>Type</th>
                <th>Price</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {properties
                .filter(p => p.title.toLowerCase().includes(searchQuery.toLowerCase()) || p.location.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(p => statusFilter === 'All' ? true : p.status === statusFilter)
                .map((prop) => (
                <tr key={prop.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div className="entity-avatar"><Building2 size={20} /></div>
                      <div>
                        <strong>{prop.title}</strong>
                        <span className="entity-sub">
                          <MapPin size={12} style={{ display: 'inline', marginRight: 4 }} />
                          {prop.location}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span className="agency-tag">{prop.agency}</span>
                  </td>
                  <td>{prop.type}</td>
                  <td><strong>{prop.price}</strong></td>
                  <td>
                    <span className={`status-badge ${prop.status.toLowerCase().replace(' ', '-')}`}>
                      {prop.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Property Details', onClick: () => toast.success(`Viewing ${prop.title}`) },
                          { label: 'Edit Listing', onClick: () => toast.success('Edit mode') },
                          { label: 'Delete Listing', onClick: () => handleDelete(prop.id), danger: true },
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
              <h2>Filter Properties</h2>
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
                  <option value="Available">Available</option>
                  <option value="Under Offer">Under Offer</option>
                  <option value="Sold">Sold</option>
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
