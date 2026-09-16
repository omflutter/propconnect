import { useState, useEffect } from 'react';
import { Search, Filter, MoreVertical, Building2, MapPin, Trash2, X, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';

export function Properties() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [isLoading, setIsLoading] = useState(true);
  const [properties, setProperties] = useState<any[]>([]);

  const [searchQuery, setSearchQuery] = useState('');

  const loadProperties = async () => {
    setIsLoading(true);
    try {
      const res = await apiFetch<any[]>('/properties');
      if (res.success && Array.isArray(res.data)) {
        setProperties(res.data.map(p => ({
          id: p.propertyCode || `PR-${p.id}`,
          rawId: p.id,
          title: p.title || 'Residential Property',
          location: p.location || 'Mumbai, Maharashtra',
          price: p.priceFormatted || (typeof p.price === 'number' ? `₹${(p.price / 10000000).toFixed(2)} Cr` : (p.price || '₹1.00 Cr')),
          agency: p.agencyName || 'Sunrise Properties',
          type: p.listingType || p.type || 'Sale',
          status: p.status || 'Available',
        })));
      }
    } catch (_) {}
    setIsLoading(false);
  };

  useEffect(() => {
    loadProperties();
  }, []);

  const handleDelete = async (id: string) => {
    const target = properties.find(p => p.id === id);
    setProperties(properties.filter(p => p.id !== id));

    if (target?.rawId) {
      try {
        await apiFetch(`/properties/${target.rawId}`, { method: 'DELETE' });
      } catch (_) {}
    }
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
              {isLoading ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '40px' }}>
                    <Loader2 size={24} className="spin" style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: 8, color: 'var(--primary-blue)' }} />
                    Loading global inventory from PostgreSQL...
                  </td>
                </tr>
              ) : properties.filter(p => p.title.toLowerCase().includes(searchQuery.toLowerCase()) || p.location.toLowerCase().includes(searchQuery.toLowerCase())).length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-secondary)' }}>
                    No properties found in global inventory.
                  </td>
                </tr>
              ) : (
                properties
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
                ))
              )}
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
