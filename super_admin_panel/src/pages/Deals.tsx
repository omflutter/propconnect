import { useState } from 'react';
import { Search, Filter, MoreVertical, Briefcase, Calendar, XCircle, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';

export function Deals() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [deals, setDeals] = useState([
    { id: 'DL-501', title: 'Sea Face Villa', value: '₹4.2 Cr', agencyA: 'Sunrise Properties', agencyB: 'Metro Reality India', status: 'Negotiation', date: '2026-07-20' },
    { id: 'DL-502', title: 'DLF Cyber City Office', value: '₹8.5 Cr', agencyA: 'Metro Reality India', agencyB: 'Bangalore Estates', status: 'Closed', date: '2026-07-15' },
    { id: 'DL-503', title: 'IT Park Space', value: '₹1.2 Lakhs/mo', agencyA: 'Sunrise Properties', agencyB: 'Sunrise Properties', status: 'Token', date: '2026-07-22' },
    { id: 'DL-504', title: 'Koramangala Condo', value: '₹85 Lakhs', agencyA: 'Bangalore Estates', agencyB: 'Sunrise Properties', status: 'Lead Assigned', date: '2026-07-23' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');

  const handleCancelDeal = (id: string) => {
    setDeals(deals.map(d => d.id === id ? { ...d, status: 'Dropped' } : d));
    toast.error(`Deal ${id} has been forcefully dropped.`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Deal Pipelines</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Track multi-agency collaborations and transaction stages.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary">Export Deals</button>
          <button className="btn-primary">+ Force Create Deal</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Deals</button>
            <button className={statusFilter === 'Negotiation' ? 'active' : ''} onClick={() => setStatusFilter('Negotiation')}>Negotiation</button>
            <button className={statusFilter === 'Token' ? 'active' : ''} onClick={() => setStatusFilter('Token')}>Token</button>
            <button className={statusFilter === 'Closed' ? 'active' : ''} onClick={() => setStatusFilter('Closed')}>Closed</button>
            <button className={statusFilter === 'Dropped' ? 'active' : ''} onClick={() => setStatusFilter('Dropped')}>Dropped</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search deals..." 
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
                <th>Deal / Property</th>
                <th>Listing Agency</th>
                <th>Partner Agency</th>
                <th>Value</th>
                <th>Stage</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {deals
                .filter(d => d.title.toLowerCase().includes(searchQuery.toLowerCase()) || d.id.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(d => statusFilter === 'All' ? true : d.status === statusFilter)
                .map((deal) => (
                <tr key={deal.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div className="entity-avatar"><Briefcase size={20} /></div>
                      <div>
                        <strong>{deal.title}</strong>
                        <span className="entity-sub">{deal.id}</span>
                      </div>
                    </div>
                  </td>
                  <td><span className="agency-tag">{deal.agencyA}</span></td>
                  <td>
                    {deal.agencyA === deal.agencyB ? (
                      <span className="text-secondary" style={{ fontSize: 13 }}>Internal Deal</span>
                    ) : (
                      <span className="agency-tag">{deal.agencyB}</span>
                    )}
                  </td>
                  <td><strong>{deal.value}</strong></td>
                  <td>
                    <span className={`status-badge ${deal.status.toLowerCase().replace(' ', '-')}`}>
                      {deal.status}
                    </span>
                  </td>
                  <td>
                    <div className="entity-sub">
                      <Calendar size={12} style={{ marginRight: 4 }} />
                      {deal.date}
                    </div>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Deal Log', onClick: () => toast.success(`Viewing log for ${deal.id}`) },
                          { label: 'Contact Agencies', onClick: () => toast.success('Opening messaging') },
                          { label: 'Force Drop Deal', onClick: () => handleCancelDeal(deal.id), danger: true },
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
              <h2>Filter Deals</h2>
              <button className="icon-btn" onClick={() => setShowFilterModal(false)}><X size={20} /></button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <label>Filter by Stage</label>
                <select 
                  className="form-select" 
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <option value="All">All Stages</option>
                  <option value="Lead Assigned">Lead Assigned</option>
                  <option value="Negotiation">Negotiation</option>
                  <option value="Token">Token</option>
                  <option value="Closed">Closed</option>
                  <option value="Dropped">Dropped</option>
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
