import { useState } from 'react';
import { Search, Filter, CreditCard, Shield, CheckCircle, FileText, Download, RefreshCw, Key } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';
import './Gateways.css';

export function Gateways() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  const [invoices, setInvoices] = useState([
    {
      id: 'INV-2026-001',
      agency: 'Sunrise Properties',
      plan: 'Professional (Monthly)',
      baseAmount: '₹6,778.81',
      gstAmount: '₹1,220.19 (18%)',
      totalAmount: '₹7,999.00',
      gateway: 'Razorpay',
      txnRef: 'pay_P9284192841',
      date: '2026-07-15',
      status: 'Paid'
    },
    {
      id: 'INV-2026-002',
      agency: 'Metro Reality India',
      plan: 'Enterprise (Annual)',
      baseAmount: '₹1,69,483.05',
      gstAmount: '₹30,506.95 (18%)',
      totalAmount: '₹1,99,990.00',
      gateway: 'Razorpay',
      txnRef: 'pay_P9182948102',
      date: '2025-11-01',
      status: 'Paid'
    },
    {
      id: 'INV-2026-003',
      agency: 'Bangalore Estates',
      plan: 'Basic (Monthly)',
      baseAmount: '₹2,541.53',
      gstAmount: '₹457.47 (18%)',
      totalAmount: '₹2,999.00',
      gateway: 'Stripe',
      txnRef: 'ch_3M0192841928',
      date: '2026-07-05',
      status: 'Paid'
    },
    {
      id: 'INV-2026-004',
      agency: 'Deccan Housing Corp',
      plan: 'Basic (Monthly)',
      baseAmount: '₹2,541.53',
      gstAmount: '₹457.47 (18%)',
      totalAmount: '₹2,999.00',
      gateway: 'Razorpay',
      txnRef: 'pay_FAILED_0918',
      date: '2026-07-10',
      status: 'Failed'
    }
  ]);

  const handleDownloadPDF = (id: string) => {
    toast.success(`GST Tax Invoice ${id} (PDF) downloaded!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Payment Gateway & GST Invoices</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage Razorpay/Stripe integrations, auto-renewals, and GST 18% tax invoicing (PRD Sec 15).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('GST Audit Statement Exported')}>Export GST Audit Sheet</button>
          <button className="btn-primary" onClick={() => toast.success('API Key settings modal opened')}>
            <Key size={14} style={{ marginRight: 6 }} /> API Credentials
          </button>
        </div>
      </div>

      {/* Gateway Cards */}
      <div className="gateway-cards-grid">
        <div className="gateway-card card">
          <div className="gateway-header">
            <span className="gateway-title">Razorpay (India Primary)</span>
            <span className="status-badge closed"><CheckCircle size={12} style={{ marginRight: 4 }} /> Live & Active</span>
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
            Key ID: <span style={{ fontFamily: 'monospace' }}>rzp_live_891238491****</span>
          </div>
          <div style={{ display: 'flex', gap: 16, fontSize: 12, marginTop: 8 }}>
            <span>Auto Renewal: <strong>Active</strong></span>
            <span>GST Tax Handling: <strong>Enabled (18% HSN 9983)</strong></span>
          </div>
        </div>

        <div className="gateway-card stripe card">
          <div className="gateway-header">
            <span className="gateway-title">Stripe (International Cards)</span>
            <span className="status-badge closed"><CheckCircle size={12} style={{ marginRight: 4 }} /> Configured</span>
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
            Key ID: <span style={{ fontFamily: 'monospace' }}>pk_live_51M0918239****</span>
          </div>
          <div style={{ display: 'flex', gap: 16, fontSize: 12, marginTop: 8 }}>
            <span>Webhook Status: <strong>Synced</strong></span>
            <span>Currency: <strong>INR / USD</strong></span>
          </div>
        </div>
      </div>

      {/* GST Invoices Table */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Invoices</button>
            <button className={statusFilter === 'Paid' ? 'active' : ''} onClick={() => setStatusFilter('Paid')}>Paid</button>
            <button className={statusFilter === 'Failed' ? 'active' : ''} onClick={() => setStatusFilter('Failed')}>Failed</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search invoice # or agency..." 
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
                <th>Invoice #</th>
                <th>Agency Name</th>
                <th>SaaS Plan</th>
                <th>Base Amount</th>
                <th>GST (18%)</th>
                <th>Total Paid</th>
                <th>Gateway & Txn Ref</th>
                <th>Date</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {invoices
                .filter(i => i.agency.toLowerCase().includes(searchQuery.toLowerCase()) || i.id.toLowerCase().includes(searchQuery.toLowerCase()) || i.txnRef.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(i => statusFilter === 'All' ? true : i.status === statusFilter)
                .map((inv) => (
                <tr key={inv.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td><strong>{inv.id}</strong></td>
                  <td>{inv.agency}</td>
                  <td><span className="agency-tag">{inv.plan}</span></td>
                  <td>{inv.baseAmount}</td>
                  <td><span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{inv.gstAmount}</span></td>
                  <td><strong style={{ color: 'var(--primary-blue)' }}>{inv.totalAmount}</strong></td>
                  <td>
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                      <span style={{ fontSize: 12, fontWeight: 600 }}>{inv.gateway}</span>
                      <span style={{ fontFamily: 'monospace', fontSize: 11, color: 'var(--text-secondary)' }}>{inv.txnRef}</span>
                    </div>
                  </td>
                  <td>{inv.date}</td>
                  <td>
                    <span className={`status-badge ${inv.status.toLowerCase()}`}>
                      {inv.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'Download Tax Invoice (PDF)', onClick: () => handleDownloadPDF(inv.id) },
                          { label: 'Retry Payment Webhook', onClick: () => toast.success(`Webhook retried for ${inv.id}`) },
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
          <span className="page-info">Showing {invoices.length} GST tax invoices</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}
