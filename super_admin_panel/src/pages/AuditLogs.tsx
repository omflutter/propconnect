import { useState } from 'react';
import { Search, Filter, Shield, Clock, Terminal, CheckCircle2, AlertTriangle, Info } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';
import './AuditLogs.css';

export function AuditLogs() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  const [logs, setLogs] = useState([
    { id: 'LOG-7001', time: '2026-08-01 12:54:10', actor: 'Om Shivam', role: 'Super Admin', action: 'Property Created', target: 'Sea Face Villa (PR-104)', ip: '103.22.180.4', result: 'Success' },
    { id: 'LOG-7002', time: '2026-08-01 12:45:00', actor: 'Rajesh Kumar', role: 'Agency Admin', action: 'Collaboration Requested', target: 'REQ-301 (DL-501)', ip: '115.240.90.12', result: 'Success' },
    { id: 'LOG-7003', time: '2026-08-01 12:30:15', actor: 'Priya Sharma', role: 'Broker', action: 'Deal Status Changed', target: 'DL-502 -> Closed', ip: '49.207.140.88', result: 'Success' },
    { id: 'LOG-7004', time: '2026-08-01 11:50:00', actor: 'System Webhook', role: 'Razorpay API', action: 'Payment Completed', target: 'INV-2026-001 (₹7,999)', ip: '52.66.190.22', result: 'Success' },
    { id: 'LOG-7005', time: '2026-08-01 11:10:44', actor: 'Amit Patel', role: 'Agency Admin', action: 'Subscription Purchased', target: 'Basic Plan (Monthly)', ip: '103.88.220.10', result: 'Success' },
    { id: 'LOG-7006', time: '2026-08-01 10:00:12', actor: 'Om Shivam', role: 'Super Admin', action: 'Commission Updated', target: 'COMM-801 (₹8.4 Lakhs)', ip: '103.22.180.4', result: 'Success' },
    { id: 'LOG-7007', time: '2026-08-01 09:15:33', actor: 'Guest User', role: 'Unknown', action: 'User Login Failed', target: 'Auth / Token Invalid', ip: '185.220.101.5', result: 'Warning' },
  ]);

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Platform Audit Logs & Trail</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Complete tamper-proof audit trail for every action across all tenant agencies (PRD Sec 18).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Audit Trail JSON Exported')}>Export JSON Logs</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Events</button>
            <button className={statusFilter === 'Success' ? 'active' : ''} onClick={() => setStatusFilter('Success')}>Success</button>
            <button className={statusFilter === 'Warning' ? 'active' : ''} onClick={() => setStatusFilter('Warning')}>Warnings</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search action or actor..." 
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
                <th>Log ID & Time</th>
                <th>Actor Name & Role</th>
                <th>Action Type</th>
                <th>Target Resource</th>
                <th>Client IP</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {logs
                .filter(l => l.actor.toLowerCase().includes(searchQuery.toLowerCase()) || l.action.toLowerCase().includes(searchQuery.toLowerCase()) || l.id.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(l => statusFilter === 'All' ? true : l.result === statusFilter)
                .map((log) => (
                <tr key={log.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div>
                        <strong>{log.id}</strong>
                        <span className="entity-sub">{log.time}</span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div className="audit-actor">
                      <strong>{log.actor}</strong>
                      <span className="entity-sub">{log.role}</span>
                    </div>
                  </td>
                  <td>
                    <span className="audit-action-tag">{log.action}</span>
                  </td>
                  <td>{log.target}</td>
                  <td><span style={{ fontFamily: 'monospace', fontSize: 12 }}>{log.ip}</span></td>
                  <td>
                    <span className={`status-badge ${log.result === 'Success' ? 'closed' : 'negotiation'}`}>
                      {log.result}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'Inspect Stack Trace / Context', onClick: () => toast.success(`Raw log object for ${log.id} dumped to console`) },
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
          <span className="page-info">Showing {logs.length} audit logs</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}
