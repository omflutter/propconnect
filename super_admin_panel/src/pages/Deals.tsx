import { useState, useEffect } from 'react';
import { Search, Filter, MoreVertical, Briefcase, Calendar, XCircle, X, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';

export function Deals() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [isLoading, setIsLoading] = useState(true);
  const [deals, setDeals] = useState<any[]>([]);

  const [searchQuery, setSearchQuery] = useState('');

  const loadDeals = async () => {
    setIsLoading(true);
    try {
      const res = await apiFetch<any[]>('/deals');
      if (res.success && Array.isArray(res.data)) {
        setDeals(res.data.map(d => ({
          id: d.dealCode || `DL-${d.id}`,
          rawId: d.id,
          title: d.propertyName || 'Commercial Space',
          value: d.dealValue || '₹1.0 Cr',
          agencyA: d.agencyAName || 'Sunrise Properties',
          agencyB: d.agencyBName || 'Partner Agency',
          status: d.status || 'Negotiation',
          date: d.createdAt ? d.createdAt.substring(0, 10) : new Date().toISOString().substring(0, 10),
        })));
      }
    } catch (_) {}
    setIsLoading(false);
  };

  useEffect(() => {
    loadDeals();
  }, []);

  const handleCancelDeal = async (id: string) => {
    const target = deals.find(d => d.id === id);
    setDeals(deals.map(d => d.id === id ? { ...d, status: 'Dropped' } : d));
    
    if (target?.rawId) {
      try {
        await apiFetch(`/deals/${target.rawId}/status`, {
          method: 'PUT',
          body: JSON.stringify({ status: 'Dropped', notes: 'Force dropped by Super Admin' }),
        });
      } catch (_) {}
    }
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
              {isLoading ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '40px' }}>
                    <Loader2 size={24} className="spin" style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: 8, color: 'var(--primary-blue)' }} />
                    Loading deals from PostgreSQL...
                  </td>
                </tr>
              ) : deals.filter(d => d.title.toLowerCase().includes(searchQuery.toLowerCase()) || d.id.toLowerCase().includes(searchQuery.toLowerCase())).length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-secondary)' }}>
                    No deal transactions found in pipeline.
                  </td>
                </tr>
              ) : (
                deals
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
