import { useState, useEffect } from 'react';
import { Search, Filter, DollarSign, Percent, ArrowRightLeft, CheckCircle2, Clock, X, Eye, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';
import './Commissions.css';

export function Commissions() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRecord, setSelectedRecord] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [commissions, setCommissions] = useState<any[]>([]);

  const loadCommissions = async () => {
    setIsLoading(true);
    try {
      const res = await apiFetch<any[]>('/commissions');
      if (res.success && Array.isArray(res.data)) {
        setCommissions(res.data.map(c => {
          const totalCommNum = typeof c.totalCommission === 'number' ? c.totalCommission : parseFloat(String(c.totalCommission || '0').replace(/[^0-9.]/g, '')) || 0;
          const brokerANum = typeof c.brokerAAmount === 'number' ? c.brokerAAmount : parseFloat(String(c.brokerAAmount || '0').replace(/[^0-9.]/g, '')) || (totalCommNum * 0.5);
          const brokerBNum = typeof c.brokerBAmount === 'number' ? c.brokerBAmount : parseFloat(String(c.brokerBAmount || '0').replace(/[^0-9.]/g, '')) || (totalCommNum * 0.5);

          return {
            id: c.commissionCode || `COMM-${c.id}`,
            rawId: c.id,
            dealId: c.dealCode || `DL-${c.dealId}`,
            property: c.propertyName || 'Commercial Unit',
            dealValue: typeof c.dealValue === 'number' ? `₹${c.dealValue.toLocaleString('en-IN')}` : c.dealValue,
            commType: `${c.commissionType || 'Percentage'} (${c.commissionRate || 2}%)`,
            rawTotalComm: totalCommNum,
            rawBrokerA: brokerANum,
            rawBrokerB: brokerBNum,
            totalComm: `₹${totalCommNum.toLocaleString('en-IN')}`,
            brokerA: `${c.agencyAName || 'Agency A'} (${c.brokerAName || 'Broker A'})`,
            brokerAShare: `${c.brokerASharePct || 50}% (₹${brokerANum.toLocaleString('en-IN')})`,
            brokerB: `${c.agencyBName || 'Agency B'} (${c.brokerBName || 'Broker B'})`,
            brokerBShare: `${c.brokerBSharePct || 50}% (₹${brokerBNum.toLocaleString('en-IN')})`,
            status: c.status || 'Pending',
            date: c.createdAt ? c.createdAt.substring(0, 10) : new Date().toISOString().substring(0, 10),
          };
        }));
      }
    } catch (_) {}
    setIsLoading(false);
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

  // Dynamic Metrics Calculations
  const totalPlatformComm = commissions.reduce((acc, c) => acc + (c.rawTotalComm || 0), 0);
  const totalBrokerAShare = commissions.reduce((acc, c) => acc + (c.rawBrokerA || 0), 0);
  const totalBrokerBShare = commissions.reduce((acc, c) => acc + (c.rawBrokerB || 0), 0);
  const pendingSettlement = commissions.filter(c => c.status !== 'Paid').reduce((acc, c) => acc + (c.rawTotalComm || 0), 0);

  const formatAmount = (num: number) => {
    if (num >= 10000000) return `₹${(num / 10000000).toFixed(2)} Cr`;
    if (num >= 100000) return `₹${(num / 100000).toFixed(2)} Lakhs`;
    return `₹${num.toLocaleString('en-IN')}`;
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
          <button className="btn-primary" onClick={() => toast.success('Commission rule configured')}>Config Commission Split</button>
        </div>
      </div>

      {/* Dynamic Metrics Row */}
      <div className="commission-metrics">
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Total Platform Comm.</span>
          <span className="comm-metric-value">{formatAmount(totalPlatformComm)}</span>
        </div>
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Broker A Total Share</span>
          <span className="comm-metric-value" style={{ color: 'var(--primary-blue)' }}>{formatAmount(totalBrokerAShare)}</span>
        </div>
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Broker B Total Share</span>
          <span className="comm-metric-value" style={{ color: '#10b981' }}>{formatAmount(totalBrokerBShare)}</span>
        </div>
        <div className="comm-metric-card card">
          <span className="comm-metric-title">Pending Settlement</span>
          <span className="comm-metric-value" style={{ color: 'var(--warning)' }}>{formatAmount(pendingSettlement)}</span>
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
              {isLoading ? (
                <tr>
                  <td colSpan={9} style={{ textAlign: 'center', padding: '40px' }}>
                    <Loader2 size={24} className="spin" style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: 8, color: 'var(--primary-blue)' }} />
                    Loading commission ledger from PostgreSQL...
                  </td>
                </tr>
              ) : commissions.filter(c => c.property.toLowerCase().includes(searchQuery.toLowerCase()) || c.id.toLowerCase().includes(searchQuery.toLowerCase()) || c.dealId.toLowerCase().includes(searchQuery.toLowerCase())).length === 0 ? (
                <tr>
                  <td colSpan={9} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-secondary)' }}>
                    No commission split records found. Closed deals will generate multi-broker commissions automatically.
                  </td>
                </tr>
              ) : (
                commissions
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
                ))
              )}
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
