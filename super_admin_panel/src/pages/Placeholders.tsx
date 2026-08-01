import { Code, Settings, MessageSquare, Briefcase, CreditCard, ShieldAlert, Network, UserPlus } from 'lucide-react';
import './GlobalData.css';

const createPlaceholder = (title: string, description: string, Icon: any) => {
  return function Placeholder() {
    return (
      <div className="global-page">
        <div className="page-header" style={{ alignItems: 'flex-start' }}>
          <div>
            <h1>{title}</h1>
            <p>{description}</p>
          </div>
        </div>
        <div className="card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '64px 24px', textAlign: 'center', gap: '16px' }}>
          <div style={{ padding: '16px', backgroundColor: 'var(--background)', borderRadius: '50%', color: 'var(--text-secondary)' }}>
            <Icon size={32} />
          </div>
          <h2 style={{ fontSize: '18px', color: 'var(--text-primary)' }}>{title} Module</h2>
          <p style={{ color: 'var(--text-secondary)', maxWidth: '400px', fontSize: '13px' }}>
            This module is currently being provisioned as part of the Enterprise CRM expansion. Data integration with the backend services is pending.
          </p>
          <button className="btn-primary" style={{ marginTop: '12px' }}>Configure Module</button>
        </div>
      </div>
    );
  };
};

export const AuditLogs = createPlaceholder('Live Audit Logs', 'Real-time system events, actions, and security logs across the platform.', Code);
export const Leads = createPlaceholder('Lead Ownership', 'Track client leads, strict data privacy, and broker ownership rules.', UserPlus);
export const Collaborations = createPlaceholder('Collaborations', 'Monitor broker-to-broker collaboration requests and shared pipelines.', Network);
export const Subscriptions = createPlaceholder('SaaS Subscriptions', 'Manage Free Trial, Basic, Pro, and Enterprise agency plans.', CreditCard);
export const Commissions = createPlaceholder('Commission Management', 'Track platform-wide generated commissions, flat fees, and percentages.', Briefcase);
export const Settlements = createPlaceholder('Payment Settlements', 'Track outstanding agency payouts and completed settlements.', ShieldAlert);
export const WhatsApp = createPlaceholder('WhatsApp API', 'Manage the WhatsApp Business API connection, templates, and quota.', MessageSquare);
export const ChatLogs = createPlaceholder('Broker Chat Logs', 'Monitor one-to-one and deal-specific internal chat systems.', MessageSquare);
export const Notifications = createPlaceholder('Push Notifications', 'Configure global in-app and email notification templates.', Settings);
export const Gateways = createPlaceholder('Payment Gateways', 'Configure Razorpay and Stripe API keys and webhook endpoints.', CreditCard);
