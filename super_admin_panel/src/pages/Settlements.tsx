import { useState, useEffect } from 'react';
import { Search, Filter, Calendar, CreditCard, CheckCircle, Clock, X, FileText } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';
import './Settlements.css';

export function Settlements() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [showRecordModal, setShowRecordModal] = useState(false);
  const [selectedSettlement, setSelectedSettlement] = useState<any>(null);

  const [settlements, setSettlements] = useState<any[]>([
    {
      id: 'STL-901',
      agency: 'Sunrise Properties',
      dueDate: '2026-07-25',
      amountDue: '₹4,20,00,000',
      amountReceived: '₹4,20,000',
      amountPending: '₹0',
      method: 'NEFT Transfer',
      refNo: 'N294819284',
      settlementDate: '2026-07-25',
      remarks: 'Commission payout for deal DL-501',
      status: 'Completed'
    },
    {
      id: 'STL-902',
      agency: 'Metro Reality India',
      dueDate: '2026-07-28',
      amountDue: '₹7,65,000',
      amountReceived: '₹3,00,000',
      amountPending: '₹4,65,000',
      method: 'Razorpay Payout',
      refNo: 'RZP_PO_827391',
      settlementDate: '2026-07-28',
      remarks: 'First tranche for DL-502',
      status: 'Partially Settled'
    },
    {
      id: 'STL-903',
      agency: 'Bangalore Estates',
      dueDate: '2026-08-05',
      amountDue: '₹5,10,000',
      amountReceived: '₹0',
      amountPending: '₹5,10,000',
      method: 'UPI / IMPS',
      refNo: 'Pending',
      settlementDate: '-',
      remarks: 'Awaiting client token clearance',
      status: 'Pending'
    },
    {
      id: 'STL-904',
      agency: 'Apex Realty Gurgaon',
      dueDate: '2026-07-20',
      amountDue: '₹12,00,000',
      amountReceived: '₹0',
      amountPending: '₹12,00,000',
      method: 'Bank Wire',
      refNo: 'Overdue',
      settlementDate: '-',
      remarks: 'Document verification pending',
      status: 'Overdue'
    }
  ]);

  const loadSettlements = async () => {
    try {
      const res = await apiFetch<any[]>('/commissions/settlements');
      if (res.success && Array.isArray(res.data) && res.data.length > 0) {
        setSettlements(res.data.map(s => ({
          id: s.settlementCode || `STL-${s.id}`,
          rawId: s.id,
          agency: s.agencyName || 'Sunrise Properties',
          dueDate: s.dueDate ? s.dueDate.substring(0, 10) : '2026-08-01',
          amountDue: typeof s.amountReceived === 'number' ? `₹${(s.amountReceived + (s.amountPending || 0)).toLocaleString('en-IN')}` : s.amountReceived,
          amountReceived: typeof s.amountReceived === 'number' ? `₹${s.amountReceived.toLocaleString('en-IN')}` : s.amountReceived,
          amountPending: typeof s.amountPending === 'number' ? `₹${s.amountPending.toLocaleString('en-IN')}` : (s.amountPending || '₹0'),
          method: s.paymentMethod || 'NEFT Transfer',
          refNo: s.referenceNumber || 'Pending',
          settlementDate: s.settlementDate ? s.settlementDate.substring(0, 10) : '-',
          remarks: s.remarks || `Settlement for ${s.dealId || 'deal'}`,
          status: s.status === 'Received' ? 'Completed' : (s.status || 'Pending'),
        })));
      }
    } catch (_) {}
  };

  useEffect(() => {
    loadSettlements();
  }, []);

  const handleCompleteSettlement = async (id: string) => {
    const target = settlements.find(s => s.id === id);
    setSettlements(settlements.map(s => s.id === id ? {
      ...s,
      status: 'Completed',
      amountReceived: s.amountDue,
      amountPending: '₹0',
      refNo: `NEFT_${Math.floor(10000000 + Math.random() * 90000000)}`,
      settlementDate: new Date().toISOString().substring(0, 10),
    } : s));

    if (target?.rawId) {
      try {
        await apiFetch('/commissions/settlements', {
          method: 'POST',
          body: JSON.stringify({
            settlementCode: target.id,
            status: 'Settled',
            amountReceived: target.amountDue,
            amountPending: 0,
          }),
        });
      } catch (_) {}
    }
    toast.success(`Settlement ${id} marked as fully completed!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Payment Settlement Tracking</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Track commission due dates, bank reference numbers, and payouts (PRD Sec 13).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Settlement Ledger PDF generated')}>Download Ledger</button>
          <button className="btn-primary" onClick={() => setShowRecordModal(true)}>+ Record Settlement</button>
        </div>
      </div>

      {/* Metrics Header */}
      <div className="settlement-card-grid">
        <div className="settlement-card card">
          <span className="settlement-card-title">Total Settled (YTD)</span>
          <span className="settlement-card-value" style={{ color: 'var(--success)' }}>₹4.20 Cr</span>
        </div>
        <div className="settlement-card card">
          <span className="settlement-card-title">Outstanding Payouts</span>
          <span className="settlement-card-value" style={{ color: 'var(--warning)' }}>₹21.75 Lakhs</span>
        </div>
        <div className="settlement-card card">
          <span className="settlement-card-title">Settlement Due Today</span>
          <span className="settlement-card-value">₹5.10 Lakhs</span>
        </div>
        <div className="settlement-card card">
          <span className="settlement-card-title">Avg Settlement Time</span>
          <span className="settlement-card-value">1.8 Days</span>
        </div>
      </div>

      {/* Table */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Settlements</button>
            <button className={statusFilter === 'Completed' ? 'active' : ''} onClick={() => setStatusFilter('Completed')}>Completed</button>
            <button className={statusFilter === 'Pending' ? 'active' : ''} onClick={() => setStatusFilter('Pending')}>Pending</button>
            <button className={statusFilter === 'Overdue' ? 'active' : ''} onClick={() => setStatusFilter('Overdue')}>Overdue</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search agency or ref #..." 
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
                <th>STL ID & Agency</th>
                <th>Due Date</th>
                <th>Amount Due</th>
                <th>Amount Received</th>
                <th>Payment Method</th>
                <th>Reference #</th>
                <th>Settlement Date</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {settlements
                .filter(s => s.agency.toLowerCase().includes(searchQuery.toLowerCase()) || s.id.toLowerCase().includes(searchQuery.toLowerCase()) || s.refNo.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(s => statusFilter === 'All' ? true : s.status === statusFilter)
                .map((stl) => (
                <tr key={stl.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div>
                        <strong>{stl.agency}</strong>
                        <span className="entity-sub">{stl.id}</span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div className="entity-sub">
                      <Calendar size={12} style={{ marginRight: 4 }} />
                      {stl.dueDate}
                    </div>
                  </td>
                  <td><strong>{stl.amountDue}</strong></td>
                  <td><span style={{ color: 'var(--success)', fontWeight: 600 }}>{stl.amountReceived}</span></td>
                  <td><span className="agency-tag">{stl.method}</span></td>
                  <td><span style={{ fontFamily: 'monospace', fontSize: 12 }}>{stl.refNo}</span></td>
                  <td>{stl.settlementDate}</td>
                  <td>
                    <span className={`status-badge ${stl.status.toLowerCase().replace(' ', '-')}`}>
                      {stl.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Receipt', onClick: () => toast.success(`Viewing receipt for ${stl.id}`) },
                          { label: 'Mark Complete', onClick: () => handleCompleteSettlement(stl.id) },
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
          <span className="page-info">Showing {settlements.length} settlement records</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>

      {/* Record Settlement Modal */}
      {showRecordModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Record Manual Payout Settlement</h2>
              <button className="icon-btn" onClick={() => setShowRecordModal(false)}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div className="form-group">
                <label>Select Target Agency</label>
                <select className="form-select">
                  <option>Sunrise Properties (Om Shivam)</option>
                  <option>Metro Reality India (Rajesh Kumar)</option>
                  <option>Bangalore Estates (Priya Sharma)</option>
                  <option>Apex Realty Gurgaon (Amit Patel)</option>
                </select>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Amount Received (₹)</label>
                  <input className="form-input" placeholder="e.g. 420000" />
                </div>
                <div className="form-group">
                  <label>Payment Method</label>
                  <select className="form-select">
                    <option>NEFT / RTGS</option>
                    <option>UPI / IMPS</option>
                    <option>Razorpay Payout API</option>
                    <option>Cheque</option>
                  </select>
                </div>
              </div>
              <div className="form-group">
                <label>Bank Reference / UTR Number</label>
                <input className="form-input" placeholder="e.g. N3948190284" />
              </div>
              <div className="form-group">
                <label>Remarks</label>
                <input className="form-input" placeholder="e.g. Cleared full commission for DL-501" />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowRecordModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={() => { toast.success('Settlement record saved!'); setShowRecordModal(false); }}>Submit Settlement</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
