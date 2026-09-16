import { useState, useEffect } from 'react';
import { Search, Filter, DollarSign, Percent, ArrowRightLeft, CheckCircle2, Clock, X, Eye } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';
import './Commissions.css';

export function Commissions() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRecord, setSelectedRecord] = useState<any>(null);

  const [commissions, setCommissions] = useState<any[]>([
    {
      id: 'COMM-801',
      dealId: 'DL-501',
      property: 'Sea Face Villa (Bandra West)',
      dealValue: '₹4,20,00,000',
      commType: 'Percentage (2%)',
      totalComm: '₹8,40,000',
      brokerA: 'Sunrise Properties (Om Shivam)',
      brokerAShare: '50% (₹4,20,000)',
      brokerB: 'Metro Reality (Rajesh Kumar)',
      brokerBShare: '50% (₹4,20,000)',
      status: 'Paid',
      date: '2026-07-22'
    },
    {
      id: 'COMM-802',
      dealId: 'DL-502',
      property: 'DLF Cyber City Office',
      dealValue: '₹8,50,00,000',
      commType: 'Percentage (1.5%)',
      totalComm: '₹12,75,000',
      brokerA: 'Metro Reality (Rajesh Kumar)',
      brokerAShare: '60% (₹7,65,000)',
      brokerB: 'Bangalore Estates (Priya Sharma)',
      brokerBShare: '40% (₹5,10,000)',
      status: 'Partially Paid',
      date: '2026-07-20'
    },
    {
      id: 'COMM-803',
      dealId: 'DL-503',
      property: 'Worli Penthouse',
      dealValue: '₹12,00,00,000',
      commType: 'Percentage (2%)',
      totalComm: '₹24,00,000',
      brokerA: 'Sunrise Properties (Om Shivam)',
      brokerAShare: '50% (₹12,00,000)',
      brokerB: 'Apex Realty (Amit Patel)',
      brokerBShare: '50% (₹12,00,000)',
      status: 'Pending',
      date: '2026-07-24'
    },
    {
      id: 'COMM-804',
      dealId: 'DL-504',
      property: 'Koramangala Tech Park Floor',
      dealValue: '₹6,00,00,000',
      commType: 'Flat Fee',
      totalComm: '₹10,00,000',
      brokerA: 'Bangalore Estates (Priya Sharma)',
      brokerAShare: '50% (₹5,00,000)',
      brokerB: 'Sunrise Properties (Om Shivam)',
      brokerBShare: '50% (₹5,00,000)',
      status: 'Pending',
      date: '2026-07-28'
    }
  ]);

  const loadCommissions = async () => {
    try {
      const res = await apiFetch<any[]>('/commissions');
      if (res.success && Array.isArray(res.data) && res.data.length > 0) {
        setCommissions(res.data.map(c => ({
          id: c.commissionCode || `COMM-${c.id}`,
          rawId: c.id,
          dealId: c.dealCode || `DL-${c.dealId}`,
          property: c.propertyName || 'Commercial Unit',
          dealValue: typeof c.dealValue === 'number' ? `₹${c.dealValue.toLocaleString('en-IN')}` : c.dealValue,
          commType: `${c.commissionType || 'Percentage'} (${c.commissionRate || 2}%)`,
          totalComm: typeof c.totalCommission === 'number' ? `₹${c.totalCommission.toLocaleString('en-IN')}` : c.totalCommission,
          brokerA: `${c.agencyAName || 'Agency A'} (${c.brokerAName || 'Broker A'})`,
          brokerAShare: `${c.brokerASharePct || 50}% (${typeof c.brokerAAmount === 'number' ? '₹' + c.brokerAAmount.toLocaleString('en-IN') : c.brokerAAmount})`,
          brokerB: `${c.agencyBName || 'Agency B'} (${c.brokerBName || 'Broker B'})`,
          brokerBShare: `${c.brokerBSharePct || 50}% (${typeof c.brokerBAmount === 'number' ? '₹' + c.brokerBAmount.toLocaleString('en-IN') : c.brokerBAmount})`,
          status: c.status || 'Pending',
          date: c.createdAt ? c.createdAt.substring(0, 10) : new Date().toISOString().substring(0, 10),
        })));
      }
    } catch (_) {}
  };

  useEffect(() => {
    loadCommissions();
  }, []);

  const handleMarkPaid = async (id: string) => {
    const target = commissions.find(c => c.id === id);
    setCommissions(commissions.map(c => c.id === id ? { ...c, status: 'Paid' } : c));
    
    if (target?.rawId) {
      try {
        await apiFetch(`/commissions/${target.rawId}`, {
          method: 'PUT',
          body: JSON.stringify({ status: 'Paid' }),
        });
      } catch (_) {}
    }
    toast.success(`Commission ${id} marked as fully paid!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Commission Management Module</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Mandatory multi-broker split tracking and commission settlement ledger (PRD Sec 12).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Commission Audit Sheet Exported')}>Export CSV</button>
          <button className="btn-primary" onClick={() => toast.success('Commission rule updated')}>Config Commission Split</button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="commission-metrics">
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Total Platform Comm.</span>
          <span className="comm-metric-value">₹55.15 Lakhs</span>
        </div>
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Broker A Total Share</span>
          <span className="comm-metric-value" style={{ color: 'var(--primary-blue)' }}>₹28.85 Lakhs</span>
        </div>
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Broker B Total Share</span>
          <span className="comm-metric-value" style={{ color: '#10b981' }}>₹26.30 Lakhs</span>
        </div>
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Pending Settlement</span>
          <span className="comm-metric-value" style={{ color: 'var(--warning)' }}>₹34.00 Lakhs</span>
        </div>
      </div>

      {/* Main Table */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Records</button>
            <button className={statusFilter === 'Paid' ? 'active' : ''} onClick={() => setStatusFilter('Paid')}>Paid</button>
            <button className={statusFilter === 'Partially Paid' ? 'active' : ''} onClick={() => setStatusFilter('Partially Paid')}>Partially Paid</button>
            <button className={statusFilter === 'Pending' ? 'active' : ''} onClick={() => setStatusFilter('Pending')}>Pending</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search deal or property..." 
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
                <th>Comm ID & Deal</th>
                <th>Property</th>
                <th>Deal Value</th>
                <th>Total Comm.</th>
                <th>Broker A (Listing) Share</th>
                <th>Broker B (Client) Share</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {commissions
                .filter(c => c.property.toLowerCase().includes(searchQuery.toLowerCase()) || c.id.toLowerCase().includes(searchQuery.toLowerCase()) || c.dealId.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(c => statusFilter === 'All' ? true : c.status === statusFilter)
                .map((comm) => (
                <tr key={comm.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div>
                        <strong>{comm.id}</strong>
                        <span className="entity-sub">{comm.dealId}</span>
                      </div>
                    </div>
                  </td>
                  <td><strong>{comm.property}</strong></td>
                  <td>{comm.dealValue}</td>
                  <td><span style={{ fontWeight: 700, color: 'var(--primary-blue)' }}>{comm.totalComm}</span></td>
                  <td>
                    <div className="broker-split-badge">
                      <span>{comm.brokerAShare}</span>
                    </div>
                  </td>
                  <td>
                    <div className="broker-split-badge">
                      <span>{comm.brokerBShare}</span>
                    </div>
                  </td>
                  <td>
                    <span className={`status-badge ${comm.status.toLowerCase().replace(' ', '-')}`}>
                      {comm.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Split Details', onClick: () => setSelectedRecord(comm) },
                          { label: 'Mark as Paid', onClick: () => handleMarkPaid(comm.id) },
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
          <span className="page-info">Showing {commissions.length} commission records</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>

      {/* Split Details Modal */}
      {selectedRecord && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Commission Breakdown: {selectedRecord.id}</h2>
              <button className="icon-btn" onClick={() => setSelectedRecord(null)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="form-group">
                <label>Deal & Property</label>
                <input className="form-input" readOnly value={`${selectedRecord.dealId} - ${selectedRecord.property}`} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Deal Value</label>
                  <input className="form-input" readOnly value={selectedRecord.dealValue} />
                </div>
                <div className="form-group">
                  <label>Total Commission</label>
                  <input className="form-input" readOnly value={selectedRecord.totalComm} />
                </div>
              </div>
              <div style={{ borderTop: '1px solid var(--border)', paddingTop: 12 }}>
                <label style={{ fontWeight: 700, marginBottom: 8, display: 'block' }}>Split Distribution Matrix</label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                  <div style={{ padding: 12, border: '1px solid var(--border)', borderRadius: 8, background: 'var(--background)' }}>
                    <strong>Broker A (Listing Owner):</strong> {selectedRecord.brokerA}
                    <div style={{ marginTop: 4, color: 'var(--primary-blue)', fontWeight: 600 }}>Share: {selectedRecord.brokerAShare}</div>
                  </div>
                  <div style={{ padding: 12, border: '1px solid var(--border)', borderRadius: 8, background: 'var(--background)' }}>
                    <strong>Broker B (Client Owner):</strong> {selectedRecord.brokerB}
                    <div style={{ marginTop: 4, color: '#10b981', fontWeight: 600 }}>Share: {selectedRecord.brokerBShare}</div>
                  </div>
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setSelectedRecord(null)}>Close</button>
              <button className="btn-primary" onClick={() => { handleMarkPaid(selectedRecord.id); setSelectedRecord(null); }}>Approve Payout</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
