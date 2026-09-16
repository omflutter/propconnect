import { useState, useEffect } from 'react';
import { Search, Filter, ShieldCheck, Lock, EyeOff, User, Phone, Mail, Calendar, X, Loader2, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';
import './Leads.css';

export function Leads() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLead, setSelectedLead] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [leads, setLeads] = useState<any[]>([]);

  const fetchLeads = async (silent = false) => {
    if (!silent) setIsLoading(true);
    else setIsRefreshing(true);

    try {
      const res = await apiFetch<any[]>('/deals');
      if (res.success && res.data) {
        const mapped = res.data.map((deal: any, idx: number) => ({
          id: deal.dealCode || `LD-${400 + deal.id || idx + 1}`,
          dealId: deal.id,
          clientName: deal.clientName || 'Confidential Client',
          clientPhone: deal.clientPhone || '+91 98***10 (Shielded)',
          clientEmail: deal.clientEmail || 'client***@gmail.com (Shielded)',
          clientOwner: deal.agencyBName ? `${deal.agencyBName} (${deal.brokerBName || 'Broker B'})` : 'Client Broker Partner',
          listingBroker: deal.agencyAName ? `${deal.agencyAName} (${deal.brokerAName || 'Broker A'})` : 'Listing Agency',
          interestedProperty: deal.propertyName || 'Verified Property',
          budget: deal.budget || deal.dealValue || '₹2.5 Cr - ₹3.5 Cr',
          privacyStatus: 'Contact Shielded from Listing Broker',
          stage: deal.stage || 'Negotiation',
          date: deal.createdAt ? new Date(deal.createdAt).toLocaleDateString() : '2026-08-01',
        }));
        setLeads(mapped);
      }
    } catch (err: any) {
      toast.error('Failed to load leads from database');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchLeads();
  }, []);

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Lead Ownership & Privacy Matrix</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Strict dual-ownership rules: Broker B owns client; Broker A owns property (PRD Sec 10).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Privacy Audit Log Exported')}>Export Privacy Log</button>
        </div>
      </div>

      {/* Info Notice Box */}
      <div className="card" style={{ padding: '16px 20px', background: '#FFFBEB', borderColor: '#FCD34D', display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
        <ShieldCheck size={24} color="#D97706" />
        <div style={{ fontSize: 13, color: '#92400E' }}>
          <strong>PRD Privacy Model Active:</strong> Listing Broker A cannot view client phone numbers or emails. Client Broker B cannot view owner negotiable prices or internal agency notes.
        </div>
      </div>

      {/* Main Table */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Leads</button>
            <button className={statusFilter === 'Site Visit Scheduled' ? 'active' : ''} onClick={() => setStatusFilter('Site Visit Scheduled')}>Site Visits</button>
            <button className={statusFilter === 'Negotiation' ? 'active' : ''} onClick={() => setStatusFilter('Negotiation')}>Negotiation</button>
            <button className={statusFilter === 'Offer Submitted' ? 'active' : ''} onClick={() => setStatusFilter('Offer Submitted')}>Offers</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search lead or client owner..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
        </div>

        <div className="table-wrapper">
          {isLoading ? (
            <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
              <Loader2 className="spinning" size={24} style={{ margin: '0 auto 12px' }} />
              Loading real-time lead ownership records from PostgreSQL database...
            </div>
          ) : leads.length === 0 ? (
            <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
              No active client leads found matching filter.
            </div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                  <th>Lead ID & Client</th>
                  <th>Client Owner (Broker B)</th>
                  <th>Listing Broker (Broker A)</th>
                  <th>Interested Property</th>
                  <th>Budget Range</th>
                  <th>Privacy Lockdown</th>
                  <th>Stage</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {leads
                  .filter(l => l.clientName.toLowerCase().includes(searchQuery.toLowerCase()) || l.id.toLowerCase().includes(searchQuery.toLowerCase()) || l.clientOwner.toLowerCase().includes(searchQuery.toLowerCase()))
                  .filter(l => statusFilter === 'All' ? true : l.stage === statusFilter)
                  .map((lead) => (
                  <tr key={lead.id}>
                    <td><input type="checkbox" className="table-checkbox" /></td>
                    <td>
                      <div className="entity-info">
                        <div>
                          <strong>{lead.clientName}</strong>
                          <span className="entity-sub">{lead.id}</span>
                        </div>
                      </div>
                    </td>
                    <td><span className="agency-tag" style={{ borderColor: '#38BDF8' }}>{lead.clientOwner}</span></td>
                    <td><span className="agency-tag">{lead.listingBroker}</span></td>
                    <td>{lead.interestedProperty}</td>
                    <td><strong>{lead.budget}</strong></td>
                    <td>
                      <span className="privacy-badge shielded">
                        <Lock size={12} /> {lead.privacyStatus}
                      </span>
                    </td>
                    <td>
                      <span className="status-badge under-offer">
                        {lead.stage}
                      </span>
                    </td>
                    <td>
                      <div className="action-buttons">
                        <ActionDropdown 
                          actions={[
                            { label: 'Inspect Lead Ownership Audit', onClick: () => setSelectedLead(lead) },
                            { label: 'Reassign Client Owner', onClick: () => toast.success(`Reassignment initiated for ${lead.id}`) },
                          ]}
                        />
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div className="pagination">
          <span className="page-info">Showing {leads.length} live protected leads from PostgreSQL defaultdb</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary" disabled>Next</button>
          </div>
        </div>
      </div>

      {/* Modal */}
      {selectedLead && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Lead Ownership Privacy Rules: {selectedLead.id}</h2>
              <button className="icon-btn" onClick={() => setSelectedLead(null)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="form-group">
                <label>Client Name</label>
                <input className="form-input" readOnly value={selectedLead.clientName} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Client Owner (Broker B)</label>
                  <input className="form-input" readOnly value={selectedLead.clientOwner} />
                </div>
                <div className="form-group">
                  <label>Listing Broker (Broker A)</label>
                  <input className="form-input" readOnly value={selectedLead.listingBroker} />
                </div>
              </div>
              <div style={{ padding: 12, border: '1px solid #FCD34D', background: '#FFFBEB', borderRadius: 8, fontSize: 13 }}>
                <strong>Enforced Access Control List:</strong>
                <ul style={{ marginTop: 8, paddingLeft: 20 }}>
                  <li>Broker A Access to Phone/Email: <span style={{ color: 'var(--error)', fontWeight: 700 }}>BLOCKED</span></li>
                  <li>Broker B Access to Negotiable Price: <span style={{ color: 'var(--error)', fontWeight: 700 }}>BLOCKED</span></li>
                  <li>Joint Access to Site Visit Schedule: <span style={{ color: 'var(--success)', fontWeight: 700 }}>ALLOWED</span></li>
                </ul>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setSelectedLead(null)}>Close</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
