import { useState } from 'react';
import { Search, Filter, Network, CheckCircle, XCircle, Clock, X, ArrowRight, UserCheck } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';
import './Collaborations.css';

export function Collaborations() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCollab, setSelectedCollab] = useState<any>(null);

  const [requests, setRequests] = useState([
    {
      id: 'REQ-301',
      propertyId: 'PR-104 (Sea Face Villa)',
      brokerA: 'Sunrise Properties (Om Shivam)',
      brokerB: 'Metro Reality (Rajesh Kumar)',
      clientRequirement: 'NRI Client looking for 4BHK Sea View Penthouse/Villa in Bandra',
      budget: '₹4.50 Cr',
      remarks: 'Client ready with 10% token amount upfront.',
      date: '2026-07-28',
      status: 'Approved'
    },
    {
      id: 'REQ-302',
      propertyId: 'PR-105 (DLF Cyber City Office)',
      brokerA: 'Metro Reality (Rajesh Kumar)',
      brokerB: 'Bangalore Estates (Priya Sharma)',
      clientRequirement: 'Fintech Startup seeking 5,000 sq.ft. commercial office space',
      budget: '₹8.50 Cr',
      remarks: 'Site visit scheduled for coming Monday.',
      date: '2026-07-30',
      status: 'Pending'
    },
    {
      id: 'REQ-303',
      propertyId: 'PR-106 (Worli Luxury Flat)',
      brokerA: 'Sunrise Properties (Om Shivam)',
      brokerB: 'Apex Realty (Amit Patel)',
      clientRequirement: 'Luxury residential requirement with private pool',
      budget: '₹12.00 Cr',
      remarks: 'Client budget too low compared to seller expectation.',
      date: '2026-07-26',
      status: 'Rejected'
    },
    {
      id: 'REQ-304',
      propertyId: 'PR-107 (Koramangala Plot)',
      brokerA: 'Bangalore Estates (Priya Sharma)',
      brokerB: 'Sunrise Properties (Om Shivam)',
      clientRequirement: 'Commercial plot for boutique hotel construction',
      budget: '₹6.00 Cr',
      remarks: 'Client bought alternate property.',
      date: '2026-07-22',
      status: 'Cancelled'
    }
  ]);

  const handleApprove = (id: string) => {
    setRequests(requests.map(r => r.id === id ? { ...r, status: 'Approved' } : r));
    toast.success(`Collaboration Request ${id} approved & Deal Created!`);
  };

  const handleReject = (id: string) => {
    setRequests(requests.map(r => r.id === id ? { ...r, status: 'Rejected' } : r));
    toast.error(`Collaboration Request ${id} rejected.`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Broker Collaborations Module</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Monitor cross-broker property sharing and collaboration workflows (PRD Sec 6 & 7).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Collaboration Matrix Exported')}>Export Matrix</button>
        </div>
      </div>

      {/* PRD Workflow Banner */}
      <div className="collab-steps-banner card">
        <div className="collab-step"><span className="collab-step-num">1</span> Broker A lists public property</div>
        <ArrowRight size={14} color="var(--text-secondary)" />
        <div className="collab-step"><span className="collab-step-num">2</span> Broker B searches inventory</div>
        <ArrowRight size={14} color="var(--text-secondary)" />
        <div className="collab-step"><span className="collab-step-num">3</span> Request Collaboration</div>
        <ArrowRight size={14} color="var(--text-secondary)" />
        <div className="collab-step"><span className="collab-step-num">4</span> Approval / Rejection</div>
        <ArrowRight size={14} color="var(--text-secondary)" />
        <div className="collab-step"><span className="collab-step-num">5</span> Joint Deal Created</div>
      </div>

      {/* Table */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Requests</button>
            <button className={statusFilter === 'Pending' ? 'active' : ''} onClick={() => setStatusFilter('Pending')}>Pending Approval</button>
            <button className={statusFilter === 'Approved' ? 'active' : ''} onClick={() => setStatusFilter('Approved')}>Approved</button>
            <button className={statusFilter === 'Rejected' ? 'active' : ''} onClick={() => setStatusFilter('Rejected')}>Rejected</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search property or broker..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
        </div>

        <div className="table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                <th>Req ID & Property</th>
                <th>Listing Broker (A)</th>
                <th>Requesting Broker (B)</th>
                <th>Expected Budget</th>
                <th>Request Date</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {requests
                .filter(r => r.propertyId.toLowerCase().includes(searchQuery.toLowerCase()) || r.id.toLowerCase().includes(searchQuery.toLowerCase()) || r.brokerB.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(r => statusFilter === 'All' ? true : r.status === statusFilter)
                .map((req) => (
                <tr key={req.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div>
                        <strong>{req.propertyId}</strong>
                        <span className="entity-sub">{req.id}</span>
                      </div>
                    </div>
                  </td>
                  <td><span className="agency-tag">{req.brokerA}</span></td>
                  <td><span className="agency-tag" style={{ borderColor: 'var(--primary-blue-light)' }}>{req.brokerB}</span></td>
                  <td><strong>{req.budget}</strong></td>
                  <td>
                    <div className="entity-sub">
                      <Clock size={12} style={{ marginRight: 4 }} />
                      {req.date}
                    </div>
                  </td>
                  <td>
                    <span className={`status-badge ${req.status.toLowerCase().replace(' ', '-')}`}>
                      {req.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Request Details', onClick: () => setSelectedCollab(req) },
                          { label: 'Force Approve & Create Deal', onClick: () => handleApprove(req.id) },
                          { label: 'Force Reject Request', onClick: () => handleReject(req.id), danger: true },
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
          <span className="page-info">Showing {requests.length} collaboration requests</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>

      {/* Detail Modal */}
      {selectedCollab && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Collaboration Request: {selectedCollab.id}</h2>
              <button className="icon-btn" onClick={() => setSelectedCollab(null)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="form-group">
                <label>Target Property</label>
                <input className="form-input" readOnly value={selectedCollab.propertyId} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Listing Broker (Property Owner)</label>
                  <input className="form-input" readOnly value={selectedCollab.brokerA} />
                </div>
                <div className="form-group">
                  <label>Requesting Broker (Client Owner)</label>
                  <input className="form-input" readOnly value={selectedCollab.brokerB} />
                </div>
              </div>
              <div className="form-group">
                <label>Client Requirement</label>
                <textarea className="form-input" readOnly rows={3} value={selectedCollab.clientRequirement} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Expected Budget</label>
                  <input className="form-input" readOnly value={selectedCollab.budget} />
                </div>
                <div className="form-group">
                  <label>Request Remarks</label>
                  <input className="form-input" readOnly value={selectedCollab.remarks} />
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setSelectedCollab(null)}>Close</button>
              <button className="btn-primary" onClick={() => { handleApprove(selectedCollab.id); setSelectedCollab(null); }}>Approve & Create Joint Deal</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
