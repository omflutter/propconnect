import { useState } from 'react';
import { Search, Filter, Smartphone, CheckCircle, Clock, Send, FileText, AlertCircle, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';
import './WhatsApp.css';

export function WhatsApp() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  const templates = [
    { name: 'Property Share & Brochure', code: 'wa_prop_brochure_v1', category: 'Utility', status: 'Approved' },
    { name: 'Collaboration Notification', code: 'wa_collab_req_v2', category: 'Transactional', status: 'Approved' },
    { name: 'Deal Status Update', code: 'wa_deal_update_v1', category: 'Transactional', status: 'Approved' },
    { name: 'Subscription Reminder', code: 'wa_sub_renew_v1', category: 'Marketing', status: 'Approved' },
  ];

  const [logs, setLogs] = useState([
    {
      id: 'MSG-9801',
      recipient: '+91 98765 43210',
      event: 'Collaboration Request Alert',
      template: 'wa_collab_req_v2',
      sentAt: '2026-08-01 12:45:10',
      status: 'Delivered'
    },
    {
      id: 'MSG-9802',
      recipient: '+91 91234 56789',
      event: 'Property Brochure Shared',
      template: 'wa_prop_brochure_v1',
      sentAt: '2026-08-01 12:30:00',
      status: 'Read'
    },
    {
      id: 'MSG-9803',
      recipient: '+91 99000 11223',
      event: 'Subscription Renewal Warning',
      template: 'wa_sub_renew_v1',
      sentAt: '2026-08-01 11:15:22',
      status: 'Delivered'
    },
    {
      id: 'MSG-9804',
      recipient: '+91 98201 00000',
      event: 'Deal Stage Changed to Closed',
      template: 'wa_deal_update_v1',
      sentAt: '2026-08-01 10:05:40',
      status: 'Failed'
    }
  ]);

  const handleTestPing = () => {
    toast.success('Test WhatsApp message sent to Admin phone!');
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>WhatsApp Business API Console</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage Meta WhatsApp Business API connection, templates, and outbound logs (PRD Sec 16).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={handleTestPing}>Send Test Message</button>
          <button className="btn-primary" onClick={() => toast.success('Syncing Meta Templates...')}>
            <RefreshCw size={14} style={{ marginRight: 6 }} /> Sync Meta Templates
          </button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="wa-stats-grid">
        <div className="wa-stat-card card">
          <span className="wa-stat-title">API Connection Status</span>
          <span className="wa-stat-value" style={{ color: 'var(--success)', display: 'flex', alignItems: 'center', gap: 6 }}>
            <CheckCircle size={20} /> Connected
          </span>
        </div>
        <div className="wa-stat-card card">
          <span className="wa-stat-title">Messages Today</span>
          <span className="wa-stat-value">1,482 / 10,000</span>
        </div>
        <div className="wa-stat-card card">
          <span className="wa-stat-title">Delivery Success Rate</span>
          <span className="wa-stat-value" style={{ color: 'var(--primary-blue)' }}>99.4%</span>
        </div>
        <div className="wa-stat-card card">
          <span className="wa-stat-title">Approved Templates</span>
          <span className="wa-stat-value">4 Templates</span>
        </div>
      </div>

      {/* Approved Templates Grid */}
      <div className="card" style={{ padding: 20, marginBottom: 24 }}>
        <h3 style={{ fontSize: 15, marginBottom: 12 }}>Configured WhatsApp Templates</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {templates.map((t, i) => (
            <div key={i} style={{ padding: 12, border: '1px solid var(--border)', borderRadius: 8, background: 'var(--background)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                <span style={{ fontSize: 12, fontWeight: 700 }}>{t.name}</span>
                <span className="wa-template-chip">{t.status}</span>
              </div>
              <div style={{ fontFamily: 'monospace', fontSize: 11, color: 'var(--text-secondary)' }}>{t.code}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Outbound Logs Table */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Logs</button>
            <button className={statusFilter === 'Read' ? 'active' : ''} onClick={() => setStatusFilter('Read')}>Read</button>
            <button className={statusFilter === 'Delivered' ? 'active' : ''} onClick={() => setStatusFilter('Delivered')}>Delivered</button>
            <button className={statusFilter === 'Failed' ? 'active' : ''} onClick={() => setStatusFilter('Failed')}>Failed</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search phone or ID..." 
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
                <th>Message ID</th>
                <th>Recipient Phone</th>
                <th>Trigger Event</th>
                <th>Template Used</th>
                <th>Sent Timestamp</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {logs
                .filter(l => l.recipient.includes(searchQuery) || l.id.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(l => statusFilter === 'All' ? true : l.status === statusFilter)
                .map((log) => (
                <tr key={log.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td><strong>{log.id}</strong></td>
                  <td><span style={{ fontFamily: 'monospace', fontWeight: 600 }}>{log.recipient}</span></td>
                  <td>{log.event}</td>
                  <td><span className="agency-tag">{log.template}</span></td>
                  <td>
                    <div className="entity-sub">
                      <Clock size={12} style={{ marginRight: 4 }} />
                      {log.sentAt}
                    </div>
                  </td>
                  <td>
                    <span className={`status-badge ${log.status === 'Read' ? 'closed' : log.status === 'Delivered' ? 'under-offer' : 'dropped'}`}>
                      {log.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Payload Logs', onClick: () => toast.success(`Payload for ${log.id} displayed in dev tools`) },
                          { label: 'Resend Message', onClick: () => toast.success(`Resent message ${log.id}`) },
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
          <span className="page-info">Showing {logs.length} WhatsApp API logs</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}
