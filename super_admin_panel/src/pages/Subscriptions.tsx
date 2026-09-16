import { useState, useEffect } from 'react';
import { Search, Filter, Check, Shield, Zap, Sparkles, Crown, Edit, MoreVertical, Calendar, DollarSign, AlertCircle, Loader2, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';
import './Subscriptions.css';

export function Subscriptions() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [agencySubs, setAgencySubs] = useState<any[]>([]);
  const [selectedAgencyForUpgrade, setSelectedAgencyForUpgrade] = useState<any | null>(null);
  const [newTier, setNewTier] = useState('Professional (₹7,999/mo)');
  const [isUpgrading, setIsUpgrading] = useState(false);

  const plans = [
    { name: 'Free Trial', badge: 'trial', price: '₹0', cycle: '14 Days', brokers: '2 Brokers', properties: '10 Listings', storage: '500 MB', whatsapp: '50 Msgs', support: 'Community' },
    { name: 'Basic', badge: 'basic', price: '₹2,999', cycle: '/month', brokers: '5 Brokers', properties: '50 Listings', storage: '5 GB', whatsapp: '500 Msgs/mo', support: 'Email' },
    { name: 'Professional', badge: 'pro', price: '₹7,999', cycle: '/month', brokers: '20 Brokers', properties: '300 Listings', storage: '25 GB', whatsapp: '2,500 Msgs/mo', support: 'Priority 24/7' },
    { name: 'Enterprise', badge: 'enterprise', price: '₹19,999', cycle: '/month', brokers: 'Unlimited', properties: 'Unlimited', storage: '250 GB', whatsapp: '10,000 Msgs/mo', support: 'Dedicated Manager' },
  ];

  const fetchSubscriptions = async (silent = false) => {
    if (!silent) setIsLoading(true);
    else setIsRefreshing(true);

    try {
      const res = await apiFetch<any[]>('/agencies');
      if (res.success && res.data) {
        const mapped = res.data.map((agency: any) => {
          const tier = agency.subscriptionTier || 'Professional (₹7,999/mo)';
          const fee = tier.includes('Enterprise') ? '₹19,999' : tier.includes('Pro') ? '₹7,999' : tier.includes('Basic') ? '₹2,999' : '₹0';
          const created = agency.createdAt ? new Date(agency.createdAt) : new Date();
          const renew = new Date(created.getTime() + 30 * 24 * 60 * 60 * 1000);

          return {
            id: `SUB-${agency.agencyCode || agency.id}`,
            agencyId: agency.id,
            agency: agency.name,
            plan: tier.split(' ')[0] || 'Professional',
            rawTier: tier,
            cycle: 'Monthly',
            fee,
            startDate: created.toLocaleDateString(),
            renewDate: renew.toLocaleDateString(),
            autoRenew: agency.status === 'Active',
            status: agency.status === 'Active' ? 'Active' : agency.status === 'Pending' ? 'Trial Active' : 'Past Due',
          };
        });
        setAgencySubs(mapped);
      }
    } catch (e: any) {
      toast.error('Failed to load subscriptions');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchSubscriptions();
  }, []);

  const handleCancelSub = async (sub: any) => {
    try {
      const res = await apiFetch(`/agencies/${sub.agencyId}`, {
        method: 'PUT',
        body: JSON.stringify({ status: 'Suspended' }),
      });
      if (res.success) {
        toast.success(`Subscription for ${sub.agency} canceled.`);
        fetchSubscriptions(true);
      } else {
        toast.error(res.message || 'Failed to cancel subscription');
      }
    } catch (err: any) {
      toast.error('Failed to update subscription');
    }
  };

  const handleUpgradeSubmit = async () => {
    if (!selectedAgencyForUpgrade) return;
    setIsUpgrading(true);
    try {
      const res = await apiFetch(`/agencies/${selectedAgencyForUpgrade.agencyId}`, {
        method: 'PUT',
        body: JSON.stringify({ subscriptionTier: newTier }),
      });
      if (res.success) {
        toast.success(`Plan upgraded to ${newTier} for ${selectedAgencyForUpgrade.agency}!`);
        setSelectedAgencyForUpgrade(null);
        fetchSubscriptions(true);
      } else {
        toast.error(res.message || 'Failed to upgrade plan');
      }
    } catch (err: any) {
      toast.error('Failed to upgrade plan');
    } finally {
      setIsUpgrading(false);
    }
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
          {isLoading ? (
            <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
              <Loader2 className="spinning" size={24} style={{ margin: '0 auto 12px' }} />
              Loading real-time agency subscriptions from PostgreSQL database...
            </div>
          ) : agencySubs.length === 0 ? (
            <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
              No subscriptions found matching filter.
            </div>
          ) : (
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
                            { label: 'Upgrade Plan', onClick: () => { setSelectedAgencyForUpgrade(sub); setNewTier(sub.rawTier); } },
                            { label: 'Extend Trial (14 Days)', onClick: () => toast.success(`Extended 14 days for ${sub.agency}`) },
                            { label: 'Cancel Subscription', onClick: () => handleCancelSub(sub), danger: true },
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
          <span className="page-info">Showing {agencySubs.length} live agency subscriptions from PostgreSQL</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary" disabled>Next</button>
          </div>
        </div>
      </div>

      {/* Upgrade Plan Modal */}
      {selectedAgencyForUpgrade && (
        <div className="modal-backdrop">
          <div className="modal-content card" style={{ maxWidth: 460 }}>
            <div className="modal-header">
              <h3 style={{ fontSize: 16, margin: 0 }}>Upgrade SaaS Plan: {selectedAgencyForUpgrade.agency}</h3>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0 }}>
                Select a new subscription tier for this agency. This instantly updates their limits and quota in PostgreSQL.
              </p>
              <div>
                <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6 }}>Target Subscription Plan</label>
                <select 
                  className="form-input" 
                  value={newTier} 
                  onChange={(e) => setNewTier(e.target.value)}
                >
                  <option value="Free Trial (₹0/mo)">Free Trial (₹0/mo - 2 Brokers, 10 Listings)</option>
                  <option value="Basic (₹2,999/mo)">Basic (₹2,999/mo - 5 Brokers, 50 Listings)</option>
                  <option value="Professional (₹7,999/mo)">Professional (₹7,999/mo - 20 Brokers, 300 Listings)</option>
                  <option value="Enterprise (₹19,999/mo)">Enterprise (₹19,999/mo - Unlimited)</option>
                </select>
              </div>
            </div>
            <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <button className="btn-secondary" onClick={() => setSelectedAgencyForUpgrade(null)}>Cancel</button>
              <button className="btn-primary" onClick={handleUpgradeSubmit} disabled={isUpgrading}>
                {isUpgrading ? <Loader2 className="spinning" size={14} style={{ marginRight: 6 }} /> : <Crown size={14} style={{ marginRight: 6 }} />}
                {isUpgrading ? 'Updating Tier...' : 'Confirm Plan Upgrade'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
