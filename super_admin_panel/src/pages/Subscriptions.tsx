import { useState } from 'react';
import { Search, Filter, Check, Shield, Zap, Sparkles, Crown, Edit, MoreVertical, Calendar, DollarSign, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';
import './Subscriptions.css';

export function Subscriptions() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  const plans = [
    { name: 'Free Trial', badge: 'trial', price: '₹0', cycle: '14 Days', brokers: '2 Brokers', properties: '10 Listings', storage: '500 MB', whatsapp: '50 Msgs', support: 'Community' },
    { name: 'Basic', badge: 'basic', price: '₹2,999', cycle: '/month', brokers: '5 Brokers', properties: '50 Listings', storage: '5 GB', whatsapp: '500 Msgs/mo', support: 'Email' },
    { name: 'Professional', badge: 'pro', price: '₹7,999', cycle: '/month', brokers: '20 Brokers', properties: '300 Listings', storage: '25 GB', whatsapp: '2,500 Msgs/mo', support: 'Priority 24/7' },
    { name: 'Enterprise', badge: 'enterprise', price: '₹19,999', cycle: '/month', brokers: 'Unlimited', properties: 'Unlimited', storage: '250 GB', whatsapp: '10,000 Msgs/mo', support: 'Dedicated Manager' },
  ];

  const [agencySubs, setAgencySubs] = useState([
    { id: 'SUB-101', agency: 'Sunrise Properties', plan: 'Professional', cycle: 'Monthly', fee: '₹7,999', startDate: '2026-01-15', renewDate: '2026-08-15', autoRenew: true, status: 'Active' },
    { id: 'SUB-102', agency: 'Metro Reality India', plan: 'Enterprise', cycle: 'Annual', fee: '₹1,99,990', startDate: '2025-11-01', renewDate: '2026-11-01', autoRenew: true, status: 'Active' },
    { id: 'SUB-103', agency: 'Bangalore Estates', plan: 'Basic', cycle: 'Monthly', fee: '₹2,999', startDate: '2026-06-05', renewDate: '2026-08-05', autoRenew: false, status: 'Expiring Soon' },
    { id: 'SUB-104', agency: 'Apex Realty Gurgaon', plan: 'Free Trial', cycle: 'Trial', fee: '₹0', startDate: '2026-07-25', renewDate: '2026-08-08', autoRenew: false, status: 'Trial Active' },
    { id: 'SUB-105', agency: 'Deccan Housing Corp', plan: 'Basic', cycle: 'Monthly', fee: '₹2,999', startDate: '2026-02-10', renewDate: '2026-07-10', autoRenew: true, status: 'Past Due' },
  ]);

  const handleCancelSub = (id: string) => {
    setAgencySubs(agencySubs.map(s => s.id === id ? { ...s, status: 'Canceled', autoRenew: false } : s));
    toast.error(`Subscription ${id} canceled.`);
  };

  const handleUpgrade = (agency: string) => {
    toast.success(`Plan upgrade initiated for ${agency}`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>SaaS Subscription Module</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage multi-tenant SaaS tiers, pricing limits, and agency active subscriptions.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Subscription report downloaded')}>Export Tax Report</button>
          <button className="btn-primary" onClick={() => toast.success('Plan creator modal opened')}>+ Edit SaaS Plans</button>
        </div>
      </div>

      {/* Plan Tier Cards */}
      <div className="plans-grid">
        {plans.map((p, i) => (
          <div key={i} className="plan-card card">
            <span className={`plan-badge ${p.badge}`}>{p.name}</span>
            <div className="plan-title">{p.name}</div>
            <div className="plan-price">{p.price} <span>{p.cycle}</span></div>
            <ul className="plan-limits">
              <li><Check size={14} /> {p.brokers}</li>
              <li><Check size={14} /> {p.properties}</li>
              <li><Check size={14} /> {p.storage} Storage</li>
              <li><Check size={14} /> {p.whatsapp}</li>
              <li><Check size={14} /> {p.support} Support</li>
            </ul>
          </div>
        ))}
      </div>

      {/* Active Subscriptions Table */}
      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Subscriptions</button>
            <button className={statusFilter === 'Active' ? 'active' : ''} onClick={() => setStatusFilter('Active')}>Active</button>
            <button className={statusFilter === 'Expiring Soon' ? 'active' : ''} onClick={() => setStatusFilter('Expiring Soon')}>Expiring Soon</button>
            <button className={statusFilter === 'Past Due' ? 'active' : ''} onClick={() => setStatusFilter('Past Due')}>Past Due</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search by agency name..." 
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
                <th>Sub ID & Agency</th>
                <th>Current Plan</th>
                <th>Billing Cycle</th>
                <th>Fee</th>
                <th>Next Renewal</th>
                <th>Auto-Renew</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {agencySubs
                .filter(s => s.agency.toLowerCase().includes(searchQuery.toLowerCase()) || s.id.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(s => statusFilter === 'All' ? true : s.status === statusFilter)
                .map((sub) => (
                <tr key={sub.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div>
                        <strong>{sub.agency}</strong>
                        <span className="entity-sub">{sub.id}</span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span className="agency-tag">{sub.plan}</span>
                  </td>
                  <td><span className="entity-sub">{sub.cycle}</span></td>
                  <td><strong>{sub.fee}</strong></td>
                  <td>
                    <div className="entity-sub">
                      <Calendar size={12} style={{ marginRight: 4 }} />
                      {sub.renewDate}
                    </div>
                  </td>
                  <td>
                    <span style={{ fontSize: 12, fontWeight: 600, color: sub.autoRenew ? 'var(--success)' : 'var(--text-secondary)' }}>
                      {sub.autoRenew ? 'Enabled' : 'Disabled'}
                    </span>
                  </td>
                  <td>
                    <span className={`status-badge ${sub.status.toLowerCase().replace(' ', '-')}`}>
                      {sub.status}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'Upgrade Plan', onClick: () => handleUpgrade(sub.agency) },
                          { label: 'Extend Trial / Days', onClick: () => toast.success(`Extended 14 days for ${sub.agency}`) },
                          { label: 'Cancel Subscription', onClick: () => handleCancelSub(sub.id), danger: true },
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
          <span className="page-info">Showing {agencySubs.length} subscriptions</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}
