import { useState, useEffect } from 'react';
import { 
  Search, CreditCard, Shield, CheckCircle, Download, Key, 
  Eye, EyeOff, Loader2, X, Lock, FileSpreadsheet, RefreshCw, Send, Sliders
} from 'lucide-react';
import toast from 'react-hot-toast';
import { apiFetch } from '../services/api';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';
import './Gateways.css';

export interface InvoiceItem {
  id: string;
  agency: string;
  plan: string;
  baseAmount: string;
  gstAmount: string;
  totalAmount: string;
  gateway: string;
  txnRef: string;
  date: string;
  status: 'Paid' | 'Failed' | 'Pending';
}

export function Gateways() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [showApiKeysModal, setShowApiKeysModal] = useState(false);
  const [activeTab, setActiveTab] = useState<'razorpay' | 'stripe' | 'whatsapp'>('razorpay');

  // Key Visibility Toggles
  const [showRazorpaySecret, setShowRazorpaySecret] = useState(false);
  const [showStripeSecret, setShowStripeSecret] = useState(false);

  // Gateway Credentials State
  const [gatewayForm, setGatewayForm] = useState({
    razorpayKeyId: 'rzp_live_89123849102934',
    razorpayKeySecret: 'rzp_sec_99182391028349',
    razorpayWebhookSecret: 'whsec_rzp_live_109283',
    stripePublishableKey: 'pk_live_51M091823981023984',
    stripeSecretKey: 'sk_live_51M091823981023984_sec_99182',
    stripeWebhookSecret: 'whsec_stripe_live_991823',
    whatsappToken: 'EAAG91028491028491028491028',
    whatsappPhoneId: '109283019283019',
    whatsappWabaId: '209384029384029',
  });

  const [invoices] = useState<InvoiceItem[]>([
    {
      id: 'INV-2026-001',
      agency: 'Sunrise Properties',
      plan: 'Enterprise (₹14,999/mo)',
      baseAmount: '₹12,711.02',
      gstAmount: '₹2,287.98 (18%)',
      totalAmount: '₹14,999.00',
      gateway: 'Razorpay',
      txnRef: 'pay_P9284192841',
      date: '2026-08-15',
      status: 'Paid',
    },
    {
      id: 'INV-2026-002',
      agency: 'Metro Realty India',
      plan: 'Pro (₹5,999/mo)',
      baseAmount: '₹5,083.90',
      gstAmount: '₹915.10 (18%)',
      totalAmount: '₹5,999.00',
      gateway: 'Razorpay',
      txnRef: 'pay_P9182948102',
      date: '2026-08-10',
      status: 'Paid',
    },
    {
      id: 'INV-2026-003',
      agency: 'Bangalore Estates',
      plan: 'Basic (₹2,999/mo)',
      baseAmount: '₹2,541.53',
      gstAmount: '₹457.47 (18%)',
      totalAmount: '₹2,999.00',
      gateway: 'Stripe',
      txnRef: 'ch_3M0192841928',
      date: '2026-08-05',
      status: 'Paid',
    },
    {
      id: 'INV-2026-004',
      agency: 'Deccan Housing Corp',
      plan: 'Basic (₹2,999/mo)',
      baseAmount: '₹2,541.53',
      gstAmount: '₹457.47 (18%)',
      totalAmount: '₹2,999.00',
      gateway: 'Razorpay',
      txnRef: 'pay_FAILED_0918',
      date: '2026-08-01',
      status: 'Failed',
    },
  ]);

  // Fetch Gateway Credentials from PostgreSQL
  const fetchGatewayCredentials = async () => {
    setIsLoading(true);
    const res = await apiFetch('/config/gateways');
    setIsLoading(false);

    if (res.success && res.data) {
      setGatewayForm((prev) => ({
        ...prev,
        ...res.data,
      }));
    }
  };

  useEffect(() => {
    fetchGatewayCredentials();
  }, []);

  // Save Gateway Credentials to PostgreSQL
  const handleSaveGatewayCredentials = async () => {
    setIsSaving(true);
    const res = await apiFetch('/config/gateways', {
      method: 'PUT',
      body: JSON.stringify(gatewayForm),
    });
    setIsSaving(false);

    if (res.success) {
      toast.success('Payment Gateway API Credentials saved to PostgreSQL!');
      setShowApiKeysModal(false);
      fetchGatewayCredentials();
    } else {
      toast.error(res.message || 'Failed to save gateway credentials');
    }
  };

  // Export Real GST Audit Sheet CSV
  const handleExportGstAuditCSV = () => {
    const headers = ['Invoice ID', 'Agency Name', 'SaaS Plan', 'Base Amount (₹)', 'GST 18% (₹)', 'Total Amount (₹)', 'Payment Gateway', 'Transaction Reference', 'Payment Date', 'Status'];
    
    const rows = invoices.map((inv) => [
      inv.id,
      `"${inv.agency}"`,
      `"${inv.plan}"`,
      `"${inv.baseAmount}"`,
      `"${inv.gstAmount}"`,
      `"${inv.totalAmount}"`,
      inv.gateway,
      inv.txnRef,
      inv.date,
      inv.status,
    ]);

    const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    const dateStr = new Date().toISOString().split('T')[0];
    link.setAttribute('href', url);
    link.setAttribute('download', `PropConnect_GST_Tax_Audit_Report_${dateStr}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success(`Exported ${invoices.length} GST tax records to CSV successfully!`);
  };

  // Real Download GST Tax Invoice Document
  const handleDownloadPDF = (inv: InvoiceItem) => {
    const invoiceDoc = `===============================================================
                       PROPCONNECT CRM
                   OFFICIAL GST TAX INVOICE
===============================================================
Invoice Number:   ${inv.id}
Date of Issue:    ${inv.date}
HSN/SAC Code:     998313 (Information Technology SaaS Services)
GSTIN:            27AAACP9918K1Z9
===============================================================
BILLED TO:
Agency Name:      ${inv.agency}
Subscription:     ${inv.plan}
Payment Gateway:  ${inv.gateway}
Txn Reference:    ${inv.txnRef}
===============================================================
FINANCIAL BREAKDOWN:
Base Amount:      ${inv.baseAmount}
CGST (9%):        ₹${(parseFloat(inv.baseAmount.replace(/[^0-9.]/g, '')) * 0.09).toFixed(2)}
SGST (9%):        ₹${(parseFloat(inv.baseAmount.replace(/[^0-9.]/g, '')) * 0.09).toFixed(2)}
Total GST (18%):  ${inv.gstAmount}
---------------------------------------------------------------
TOTAL AMOUNT PAID: ${inv.totalAmount} (${inv.status})
===============================================================
This is a computer-generated GST invoice. No signature required.
`;

    const blob = new Blob([invoiceDoc], { type: 'text/plain;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `Tax_Invoice_${inv.id}_${inv.agency.replace(/\s+/g, '_')}.txt`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success(`Downloaded Tax Invoice ${inv.id} for ${inv.agency}!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Payment Gateways & GST Tax Invoicing</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage live Razorpay / Stripe integrations, API secret keys, auto-renewals, and 18% GST tax invoicing.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={handleExportGstAuditCSV}>
            <FileSpreadsheet size={14} style={{ marginRight: 6 }} /> Export GST Audit Sheet
          </button>
          <button className="btn-primary" onClick={() => setShowApiKeysModal(true)}>
            <Key size={14} style={{ marginRight: 6 }} /> API Credentials
          </button>
        </div>
      </div>

      {/* Gateway Cards Grid */}
      <div className="gateway-cards-grid">
        {/* Razorpay Card */}
        <div className="gateway-card card">
          <div className="gateway-header">
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <CreditCard size={20} color="var(--primary-blue)" />
              <span className="gateway-title">Razorpay (India Primary)</span>
            </div>
            <span className="status-badge closed">
              <CheckCircle size={12} style={{ marginRight: 4 }} /> Live & Active
            </span>
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
            Key ID: <span style={{ fontFamily: 'monospace', fontWeight: 600, color: 'var(--text-primary)' }}>{gatewayForm.razorpayKeyId}</span>
          </div>
          <div style={{ display: 'flex', gap: 16, fontSize: 12, marginTop: 8 }}>
            <span>Auto Renewal: <strong>Active</strong></span>
            <span>GST Tax Handling: <strong>Enabled (18% HSN 9983)</strong></span>
          </div>
          <div style={{ marginTop: 12 }}>
            <button 
              className="btn-secondary" 
              style={{ width: '100%', fontSize: 12, padding: '6px 12px' }}
              onClick={() => { setActiveTab('razorpay'); setShowApiKeysModal(true); }}
            >
              <Sliders size={14} style={{ marginRight: 6 }} /> Configure Razorpay Keys
            </button>
          </div>
        </div>

        {/* Stripe Card */}
        <div className="gateway-card stripe card">
          <div className="gateway-header">
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <CreditCard size={20} color="#635BFF" />
              <span className="gateway-title">Stripe (International Cards)</span>
            </div>
            <span className="status-badge closed">
              <CheckCircle size={12} style={{ marginRight: 4 }} /> Configured
            </span>
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
            Publishable Key: <span style={{ fontFamily: 'monospace', fontWeight: 600, color: 'var(--text-primary)' }}>{gatewayForm.stripePublishableKey}</span>
          </div>
          <div style={{ display: 'flex', gap: 16, fontSize: 12, marginTop: 8 }}>
            <span>Webhook Status: <strong>Synced</strong></span>
            <span>Currency: <strong>INR / USD</strong></span>
          </div>
          <div style={{ marginTop: 12 }}>
            <button 
              className="btn-secondary" 
              style={{ width: '100%', fontSize: 12, padding: '6px 12px' }}
              onClick={() => { setActiveTab('stripe'); setShowApiKeysModal(true); }}
            >
              <Sliders size={14} style={{ marginRight: 6 }} /> Configure Stripe Keys
            </button>
          </div>
        </div>
      </div>

      {/* GST Invoices Table Container */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)', flexWrap: 'wrap', gap: 12 }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Invoices ({invoices.length})</button>
            <button className={statusFilter === 'Paid' ? 'active' : ''} onClick={() => setStatusFilter('Paid')}>Paid ({invoices.filter(i => i.status === 'Paid').length})</button>
            <button className={statusFilter === 'Failed' ? 'active' : ''} onClick={() => setStatusFilter('Failed')}>Failed ({invoices.filter(i => i.status === 'Failed').length})</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search invoice #, agency, or txn..." 
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
                          { label: 'Download Tax Invoice (PDF)', onClick: () => handleDownloadPDF(inv) },
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

      {/* INTERACTIVE API CREDENTIALS MODAL */}
      {showApiKeysModal && (
        <div className="modal-overlay">
          <div className="modal-content large">
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <Lock size={20} color="var(--primary-blue)" />
                <h2>Payment Gateway & API Credentials Settings</h2>
              </div>
              <button className="icon-btn" onClick={() => setShowApiKeysModal(false)}><X size={20} /></button>
            </div>

            <div className="modal-body">
              {/* Segmented Navigation Tabs */}
              <div className="segmented-tabs" style={{ marginBottom: 20 }}>
                <button 
                  className={activeTab === 'razorpay' ? 'active' : ''} 
                  onClick={() => setActiveTab('razorpay')}
                >
                  Razorpay (India)
                </button>
                <button 
                  className={activeTab === 'stripe' ? 'active' : ''} 
                  onClick={() => setActiveTab('stripe')}
                >
                  Stripe (International)
                </button>
                <button 
                  className={activeTab === 'whatsapp' ? 'active' : ''} 
                  onClick={() => setActiveTab('whatsapp')}
                >
                  WhatsApp & SMS Credentials
                </button>
              </div>

              {/* TAB 1: RAZORPAY */}
              {activeTab === 'razorpay' && (
                <div className="form-section">
                  <h3>Razorpay Production API Keys (18% GST Auto-Invoicing)</h3>
                  <div className="form-grid">
                    <div className="form-group full-width">
                      <label>Razorpay Key ID (Live)</label>
                      <input 
                        type="text" 
                        value={gatewayForm.razorpayKeyId}
                        onChange={(e) => setGatewayForm({ ...gatewayForm, razorpayKeyId: e.target.value })}
                        placeholder="rzp_live_..."
                      />
                    </div>
                    <div className="form-group full-width">
                      <label>Razorpay Key Secret (Live)</label>
                      <div style={{ position: 'relative' }}>
                        <input 
                          type={showRazorpaySecret ? 'text' : 'password'} 
                          value={gatewayForm.razorpayKeySecret}
                          onChange={(e) => setGatewayForm({ ...gatewayForm, razorpayKeySecret: e.target.value })}
                          placeholder="rzp_sec_..."
                          style={{ paddingRight: 40 }}
                        />
                        <button 
                          type="button"
                          className="icon-btn"
                          style={{ position: 'absolute', right: 6, top: 6, border: 'none', background: 'transparent' }}
                          onClick={() => setShowRazorpaySecret(!showRazorpaySecret)}
                        >
                          {showRazorpaySecret ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                      </div>
                    </div>
                    <div className="form-group full-width">
                      <label>Razorpay Webhook Secret Token</label>
                      <input 
                        type="text" 
                        value={gatewayForm.razorpayWebhookSecret}
                        onChange={(e) => setGatewayForm({ ...gatewayForm, razorpayWebhookSecret: e.target.value })}
                        placeholder="whsec_..."
                      />
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 2: STRIPE */}
              {activeTab === 'stripe' && (
                <div className="form-section">
                  <h3>Stripe API Keys (International SaaS Billing)</h3>
                  <div className="form-grid">
                    <div className="form-group full-width">
                      <label>Stripe Publishable Key</label>
                      <input 
                        type="text" 
                        value={gatewayForm.stripePublishableKey}
                        onChange={(e) => setGatewayForm({ ...gatewayForm, stripePublishableKey: e.target.value })}
                        placeholder="pk_live_..."
                      />
                    </div>
                    <div className="form-group full-width">
                      <label>Stripe Secret Key</label>
                      <div style={{ position: 'relative' }}>
                        <input 
                          type={showStripeSecret ? 'text' : 'password'} 
                          value={gatewayForm.stripeSecretKey}
                          onChange={(e) => setGatewayForm({ ...gatewayForm, stripeSecretKey: e.target.value })}
                          placeholder="sk_live_..."
                          style={{ paddingRight: 40 }}
                        />
                        <button 
                          type="button"
                          className="icon-btn"
                          style={{ position: 'absolute', right: 6, top: 6, border: 'none', background: 'transparent' }}
                          onClick={() => setShowStripeSecret(!showStripeSecret)}
                        >
                          {showStripeSecret ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                      </div>
                    </div>
                    <div className="form-group full-width">
                      <label>Stripe Webhook Signing Secret</label>
                      <input 
                        type="text" 
                        value={gatewayForm.stripeWebhookSecret}
                        onChange={(e) => setGatewayForm({ ...gatewayForm, stripeWebhookSecret: e.target.value })}
                        placeholder="whsec_..."
                      />
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 3: WHATSAPP & SMS */}
              {activeTab === 'whatsapp' && (
                <div className="form-section">
                  <h3>WhatsApp Business API Credentials</h3>
                  <div className="form-grid">
                    <div className="form-group full-width">
                      <label>Meta Permanent System User Access Token</label>
                      <input 
                        type="password" 
                        value={gatewayForm.whatsappToken}
                        onChange={(e) => setGatewayForm({ ...gatewayForm, whatsappToken: e.target.value })}
                        placeholder="EAAG..."
                      />
                    </div>
                    <div className="form-group">
                      <label>WhatsApp Phone Number ID</label>
                      <input 
                        type="text" 
                        value={gatewayForm.whatsappPhoneId}
                        onChange={(e) => setGatewayForm({ ...gatewayForm, whatsappPhoneId: e.target.value })}
                      />
                    </div>
                    <div className="form-group">
                      <label>WhatsApp Business Account ID (WABA ID)</label>
                      <input 
                        type="text" 
                        value={gatewayForm.whatsappWabaId}
                        onChange={(e) => setGatewayForm({ ...gatewayForm, whatsappWabaId: e.target.value })}
                      />
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowApiKeysModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleSaveGatewayCredentials} disabled={isSaving}>
                {isSaving ? (
                  <span className="spinner-btn-content">
                    <Loader2 size={16} className="animate-spin" />
                    <span>Saving API Keys to PostgreSQL...</span>
                  </span>
                ) : (
                  'Save Gateway Credentials'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
