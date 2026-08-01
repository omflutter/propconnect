import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Mail, Phone, ShieldCheck, Building2, Users, Briefcase } from 'lucide-react';
import './AgencyProfile.css';

export function AgencyProfile() {
  const { id } = useParams();
  const navigate = useNavigate();

  // Mock data for the specific agency
  const agency = {
    id: id || 'AG-001',
    name: 'Metro Reality India',
    admin: 'Rajesh Kumar',
    email: 'admin@metroreality.in',
    phone: '+91 91234 56789',
    location: 'Connaught Place, Delhi NCR',
    rera: 'PRM/KA/RERA/1251/310/PR/180507/001646',
    plan: 'Enterprise (₹14,999/mo)',
    joined: '2026-05-20',
    status: 'Active',
    stats: {
      properties: 128,
      deals: 34,
      brokers: 12,
      revenue: '₹1.2 Cr',
    }
  };

  return (
    <div className="profile-page">
      <div className="page-header profile-header-actions">
        <button className="btn-icon-text" onClick={() => navigate(-1)}>
          <ArrowLeft size={18} />
          Back to Agencies
        </button>
      </div>

      <div className="profile-hero card">
        <div className="hero-content">
          <div className="profile-avatar large">
            {agency.name.charAt(0)}
          </div>
          <div className="hero-info">
            <div className="title-row">
              <h1>{agency.name}</h1>
              <span className={`status-badge ${agency.status.toLowerCase()}`}>{agency.status}</span>
            </div>
            <div className="meta-row">
              <span className="meta-item"><MapPin size={14} /> {agency.location}</span>
              <span className="meta-item"><ShieldCheck size={14} /> RERA: {agency.rera}</span>
            </div>
          </div>
        </div>
        <div className="hero-actions">
          <button className="btn-secondary">Edit Profile</button>
          <button className="btn-secondary danger-text">Suspend Agency</button>
        </div>
      </div>

      <div className="stats-grid">
        <div className="stat-card card">
          <div className="stat-header">
            <div className="stat-icon-wrapper" style={{ backgroundColor: '#10b98115' }}>
              <Building2 className="stat-icon" style={{ color: '#10b981' }} />
            </div>
          </div>
          <div className="stat-info">
            <h3 className="stat-value">{agency.stats.properties}</h3>
            <span className="stat-label">Active Properties</span>
          </div>
        </div>
        <div className="stat-card card">
          <div className="stat-header">
            <div className="stat-icon-wrapper" style={{ backgroundColor: '#f59e0b15' }}>
              <Briefcase className="stat-icon" style={{ color: '#f59e0b' }} />
            </div>
          </div>
          <div className="stat-info">
            <h3 className="stat-value">{agency.stats.deals}</h3>
            <span className="stat-label">Closed Deals</span>
          </div>
        </div>
        <div className="stat-card card">
          <div className="stat-header">
            <div className="stat-icon-wrapper" style={{ backgroundColor: '#3b82f615' }}>
              <Users className="stat-icon" style={{ color: '#3b82f6' }} />
            </div>
          </div>
          <div className="stat-info">
            <h3 className="stat-value">{agency.stats.brokers}</h3>
            <span className="stat-label">Registered Brokers</span>
          </div>
        </div>
      </div>

      <div className="profile-details-grid">
        <div className="card details-card">
          <h3>Admin Contact Information</h3>
          <ul className="details-list">
            <li>
              <span className="detail-label">Full Name</span>
              <span className="detail-value">{agency.admin}</span>
            </li>
            <li>
              <span className="detail-label"><Mail size={14} style={{ display: 'inline', marginRight: 4 }}/> Email</span>
              <span className="detail-value">{agency.email}</span>
            </li>
            <li>
              <span className="detail-label"><Phone size={14} style={{ display: 'inline', marginRight: 4 }}/> Phone</span>
              <span className="detail-value">{agency.phone}</span>
            </li>
          </ul>
        </div>
        <div className="card details-card">
          <h3>Platform Details</h3>
          <ul className="details-list">
            <li>
              <span className="detail-label">Subscription Tier</span>
              <span className="detail-value">{agency.plan}</span>
            </li>
            <li>
              <span className="detail-label">Join Date</span>
              <span className="detail-value">{agency.joined}</span>
            </li>
            <li>
              <span className="detail-label">Agency ID</span>
              <span className="detail-value">{agency.id}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}
