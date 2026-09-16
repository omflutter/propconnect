import { useState } from 'react';
import { Rocket, CheckCircle2, Clock, Calendar, ShieldCheck, Download, Code2, Building2, Users, Settings, History, Activity, Database, Smartphone, Layout, CreditCard, Sparkles } from 'lucide-react';
import toast from 'react-hot-toast';
import './GlobalData.css';
import './Progress.css';

export interface ProgressItem {
  id: string;
  title: string;
  desc: string;
  status: 'live-working' | 'ui-completed' | 'in-progress' | 'next-phase';
}

export interface ProgressCategory {
  id: string;
  title: string;
  icon: any;
  status: 'live-working' | 'ui-completed' | 'in-progress' | 'next-phase';
  badgeText: string;
  items: ProgressItem[];
}

export function Progress() {
  const [filter, setFilter] = useState<'all' | 'live-working' | 'ui-completed' | 'in-progress' | 'next-phase'>('all');

  const categories: ProgressCategory[] = [
    {
      id: 'ui',
      title: 'User Interface & Frontend Designs',
      icon: Layout,
      status: 'ui-completed',
      badgeText: '100% UI Complete',
      items: [
        { id: 'u1', title: 'Super Admin Web Panel UI', desc: 'Vite React application with dark glassmorphic design system', status: 'live-working' },
        { id: 'u2', title: 'Flutter Mobile Application UI', desc: 'Cross-platform mobile UI screens, agency portals & broker login', status: 'ui-completed' },
        { id: 'u3', title: 'Custom In-App Modal Component System', desc: 'Replaced browser alerts with dark glassmorphic action dialogs', status: 'live-working' },
        { id: 'u4', title: 'SearchableSelect Dropdown Component', desc: 'Popover search input handling 100+ agencies seamlessly', status: 'live-working' },
      ],
    },
    {
      id: 'backend',
      title: 'Node.js & MySQL Database Backend Core',
      icon: Database,
      status: 'live-working',
      badgeText: '100% Live & Working',
      items: [
        { id: 'b1', title: 'Express TypeScript Server (Port 5001)', desc: 'Backend REST API architecture listening cleanly', status: 'live-working' },
        { id: 'b2', title: 'MySQL Relational Database Sync', desc: 'Sequelize models, foreign keys, tables auto-created', status: 'live-working' },
        { id: 'b3', title: 'Swagger UI OpenAPI Documentation', desc: 'Interactive API specs registered live at /api-docs', status: 'live-working' },
        { id: 'b4', title: 'Unified Start Command (npm run start:all)', desc: 'Runs Express backend and Vite admin panel concurrently', status: 'live-working' },
      ],
    },
    {
      id: 'agencies',
      title: 'Agencies Matrix Section',
      icon: Building2,
      status: 'live-working',
      badgeText: '100% Live & Working',
      items: [
        { id: 'c1', title: 'Agency Onboarding & Registration API', desc: 'POST /agencies creating records & credentials in MySQL', status: 'live-working' },
        { id: 'c2', title: 'Full Agency CRUD Operations', desc: 'Read, edit profile details, toggle status, and delete agency', status: 'live-working' },
        { id: 'c3', title: 'Individual Agency Profile Page', desc: 'Dynamic profile view connected live to GET /agencies/:id', status: 'live-working' },
        { id: 'c4', title: 'RFC 4180 UTF-8 BOM CSV Exporting', desc: 'One-click CSV download formatted for Excel & Sheets', status: 'live-working' },
      ],
    },
    {
      id: 'brokers',
      title: 'Platform Brokers Section',
      icon: Users,
      status: 'live-working',
      badgeText: '100% Live & Working',
      items: [
        { id: 'd1', title: '100+ Multi-Tenant Agency Search Filter', desc: 'Filter brokers by target agency using SearchableSelect', status: 'live-working' },
        { id: 'd2', title: 'Broker User Onboarding Form', desc: 'Register broker users & assign to target SaaS agency', status: 'live-working' },
        { id: 'd3', title: 'Broker Account Status Toggles', desc: 'Suspend or reactivate broker logins with ConfirmModal', status: 'live-working' },
        { id: 'd4', title: 'Brokers RFC 4180 CSV Exporting', desc: 'Export filtered broker user records to CSV file', status: 'live-working' },
      ],
    },
    {
      id: 'config',
      title: 'Platform Config & Granular Admin Powers',
      icon: Settings,
      status: 'live-working',
      badgeText: '100% Live & Working',
      items: [
        { id: 'e1', title: 'Granular Section Permission Matrix Grid', desc: 'View, Edit, Delete checkboxes across 8 platform sections', status: 'live-working' },
        { id: 'e2', title: 'Predefined Permanent System Roles', desc: 'Super Admin, Operations Manager, Finance Lead, Support Agent', status: 'live-working' },
        { id: 'e3', title: 'System Fee Policies & Maintenance Mode', desc: 'Update commission %, tier pricing, & enable lockdown mode', status: 'live-working' },
        { id: 'e4', title: 'Super Admin Profile Credential Updates', desc: 'Update admin name, email, and bcrypt password hash', status: 'live-working' },
      ],
    },
    {
      id: 'audit',
      title: 'Live Audit Logs & Trail Section',
      icon: History,
      status: 'live-working',
      badgeText: '100% Live & Working',
      items: [
        { id: 'f1', title: 'Tamper-Proof MySQL Audit Storage', desc: 'AuditLog model storing actor, IP, action, and JSON payload', status: 'live-working' },
        { id: 'f2', title: 'Real-Time 5-Second Polling', desc: 'Live auto-refresh toggle with pulsing green status dot', status: 'live-working' },
        { id: 'f3', title: 'Raw Payload Code Inspector Modal', desc: 'Dark terminal viewer for event JSON context & stack trace', status: 'live-working' },
        { id: 'f4', title: 'Calendar Day Range Filter', desc: 'Filter logs for Today, Yesterday, or custom date (YYYY-MM-DD)', status: 'live-working' },
        { id: 'f5', title: 'Multi-Format Audit Exports', desc: 'Export audit logs to formatted JSON or CSV files', status: 'live-working' },
      ],
    },
    {
      id: 'dashboard',
      title: 'Global Command Center Dashboard',
      icon: Activity,
      status: 'live-working',
      badgeText: '100% Live & Working',
      items: [
        { id: 'g1', title: 'Live MySQL Summary Stat Cards', desc: 'Queries MySQL database for Agencies, Brokers, Revenue', status: 'live-working' },
        { id: 'g2', title: 'Live System Activity Feed', desc: 'Displays 6 latest audit trail events directly on dashboard', status: 'live-working' },
        { id: 'g3', title: 'Interactive Card Navigation Routing', desc: 'One-click stat card navigation to all platform sections', status: 'live-working' },
      ],
    },
    {
      id: 'mobile-api',
      title: 'Mobile App API Connectors & Sync',
      icon: Smartphone,
      status: 'in-progress',
      badgeText: 'In Progress (API Sync)',
      items: [
        { id: 'h1', title: 'Flutter Auth & Login API Connector', desc: 'Connected mobile login screen to Express auth route', status: 'live-working' },
        { id: 'h2', title: 'Agency Selection in Mobile Registration', desc: 'Dynamic agency dropdown fetch in Flutter app', status: 'in-progress' },
        { id: 'h3', title: 'Mobile Property Inventory Sync', desc: 'Fetching property inventory on Flutter app screens', status: 'in-progress' },
      ],
    },
    {
      id: 'properties-deals',
      title: 'Properties & Deal Pipeline Features',
      icon: Building2,
      status: 'next-phase',
      badgeText: 'Next Deliverables',
      items: [
        { id: 'i1', title: 'Property Image & Video Upload Pipeline', desc: 'Multi-photo media gallery for property listings', status: 'in-progress' },
        { id: 'i2', title: 'RERA Verification Badge Pipeline', desc: 'Automated verification check against state RERA databases', status: 'in-progress' },
        { id: 'i3', title: 'Broker Joint Deal Pipeline & Chat', desc: 'Lead sharing agreements & broker chat log moderation', status: 'next-phase' },
        { id: 'i4', title: 'Razorpay Auto Subscriptions & GST Invoicing', desc: 'Recurring subscription billing & GST tax invoices', status: 'next-phase' },
      ],
    },
  ];

  const totalItems = categories.reduce((sum, c) => sum + c.items.length, 0);
  const liveWorkingCount = categories.reduce(
    (sum, c) => sum + c.items.filter((i) => i.status === 'live-working').length,
    0
  );
  const uiCompletedCount = categories.reduce(
    (sum, c) => sum + c.items.filter((i) => i.status === 'ui-completed').length,
    0
  );
  const inProgressCount = categories.reduce(
    (sum, c) => sum + c.items.filter((i) => i.status === 'in-progress').length,
    0
  );
  const nextPhaseCount = categories.reduce(
    (sum, c) => sum + c.items.filter((i) => i.status === 'next-phase').length,
    0
  );

  const overallPercent = Math.round(((liveWorkingCount + uiCompletedCount) / totalItems) * 100);

  const filteredCategories = categories
    .map((cat) => ({
      ...cat,
      items: cat.items.filter((item) => (filter === 'all' ? true : item.status === filter)),
    }))
    .filter((cat) => cat.items.length > 0);

  const handleExportReport = () => {
    const textLines = [
      `PROPCONNECT PLATFORM FEATURE PROGRESS REPORT`,
      `Generated Date: ${new Date().toLocaleString()}`,
      `Overall Readiness: ${overallPercent}% (${liveWorkingCount + uiCompletedCount}/${totalItems} Features Delivered)`,
      `Live & Working End-to-End: ${liveWorkingCount} Features`,
      `UI Completed: ${uiCompletedCount} Features`,
      `API Sync In Progress: ${inProgressCount} Features`,
      `Next Phase Planned: ${nextPhaseCount} Features`,
      `--------------------------------------------------`,
      ...categories.flatMap((cat) => [
        `\n[${cat.title}] - ${cat.badgeText}`,
        ...cat.items.map(
          (item) => `  - [${item.status.toUpperCase()}] ${item.title}: ${item.desc}`
        ),
      ]),
    ];

    const blob = new Blob([textLines.join('\n')], { type: 'text/plain;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    const dateStr = new Date().toISOString().split('T')[0];
    link.setAttribute('href', url);
    link.setAttribute('download', `PropConnect_Feature_Roadmap_${dateStr}.txt`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success('Downloaded Feature Roadmap Status Report!');
  };

  return (
    <div className="progress-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Project Progress & Feature Status Roadmap</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>
            Detailed breakdown of 100% working live sections, completed UI designs, active API syncs, and next phase deliverables.
          </p>
        </div>
        <div className="header-actions">
          <button className="btn-primary" onClick={handleExportReport}>
            <Download size={14} style={{ marginRight: 6 }} /> Export Roadmap Report
          </button>
        </div>
      </div>

      {/* Top Hero Overall Completion Banner */}
      <div className="progress-hero-card">
        <div className="hero-top-row">
          <div className="hero-title-group">
            <h2>
              <Sparkles size={24} color="#60a5fa" /> Platform Development Status
            </h2>
            <p>
              Agencies Matrix, Platform Brokers (100+ Searchable Agencies), Platform Config & Permission Matrix, Live Audit Logs (5s Polling & Day Filter), Command Center Dashboard, and Backend APIs are 100% Live & Working in MySQL.
            </p>
          </div>

          <div className="percentage-badge">
            <span className="percentage-value">{overallPercent}%</span>
            <span className="percentage-label">Total Platform Readiness</span>
          </div>
        </div>

        <div className="overall-meter-container">
          <div className="meter-track">
            <div className="meter-fill" style={{ width: `${overallPercent}%` }}></div>
          </div>
          <div className="meter-labels">
            <span>🟢 {liveWorkingCount} Live & Working End-to-End</span>
            <span>🔵 {uiCompletedCount} UI Completed</span>
            <span>🟡 {inProgressCount} API Sync In Progress</span>
            <span>🟣 {nextPhaseCount} Next Phase</span>
          </div>
        </div>
      </div>

      {/* 4 Summary Stat Cards */}
      <div className="progress-summary-grid">
        <div className="summary-card">
          <div className="summary-icon-wrapper" style={{ backgroundColor: '#10b98115', color: '#10b981' }}>
            <CheckCircle2 size={24} />
          </div>
          <div className="summary-info">
            <h4>{liveWorkingCount}</h4>
            <span>100% Live & Working</span>
          </div>
        </div>

        <div className="summary-card">
          <div className="summary-icon-wrapper" style={{ backgroundColor: '#3b82f615', color: '#3b82f6' }}>
            <Layout size={24} />
          </div>
          <div className="summary-info">
            <h4>{uiCompletedCount + liveWorkingCount}</h4>
            <span>UI Designs Completed</span>
          </div>
        </div>

        <div className="summary-card">
          <div className="summary-icon-wrapper" style={{ backgroundColor: '#f59e0b15', color: '#f59e0b' }}>
            <Clock size={24} />
          </div>
          <div className="summary-info">
            <h4>{inProgressCount}</h4>
            <span>API Sync In Progress</span>
          </div>
        </div>

        <div className="summary-card">
          <div className="summary-icon-wrapper" style={{ backgroundColor: '#a855f715', color: '#a855f7' }}>
            <Calendar size={24} />
          </div>
          <div className="summary-info">
            <h4>{nextPhaseCount}</h4>
            <span>Next Phase Features</span>
          </div>
        </div>
      </div>

      {/* Filter Segmented Tabs */}
      <div className="card table-container" style={{ padding: '16px 20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
          <div className="segmented-tabs">
            <button className={filter === 'all' ? 'active' : ''} onClick={() => setFilter('all')}>
              All Deliverables ({totalItems})
            </button>
            <button className={filter === 'live-working' ? 'active' : ''} onClick={() => setFilter('live-working')}>
              🟢 Live & Working ({liveWorkingCount})
            </button>
            <button className={filter === 'ui-completed' ? 'active' : ''} onClick={() => setFilter('ui-completed')}>
              🔵 UI Completed ({uiCompletedCount})
            </button>
            <button className={filter === 'in-progress' ? 'active' : ''} onClick={() => setFilter('in-progress')}>
              🟡 API Sync In Progress ({inProgressCount})
            </button>
            <button className={filter === 'next-phase' ? 'active' : ''} onClick={() => setFilter('next-phase')}>
              🟣 Next Phase ({nextPhaseCount})
            </button>
          </div>
        </div>
      </div>

      {/* Modules Checklist Grid */}
      <div className="feature-modules-grid">
        {filteredCategories.map((category) => {
          const IconComp = category.icon;
          return (
            <div key={category.id} className="module-card">
              <div className="module-header">
                <div className="module-title-group">
                  <IconComp size={20} color="var(--primary-blue)" />
                  <div>
                    <h3>{category.title}</h3>
                    <small style={{ color: 'var(--text-secondary)' }}>{category.items.length} Feature Deliverables</small>
                  </div>
                </div>
                <span className={`module-badge ${category.status}`}>
                  {category.badgeText}
                </span>
              </div>

              <div className="feature-checklist">
                {category.items.map((item) => (
                  <div key={item.id} className="checklist-item">
                    <div className={`item-status-icon ${item.status}`}>
                      {item.status === 'live-working' && <CheckCircle2 size={16} />}
                      {item.status === 'ui-completed' && <Layout size={16} />}
                      {item.status === 'in-progress' && <Clock size={16} />}
                      {item.status === 'next-phase' && <Calendar size={16} />}
                    </div>
                    <div className="item-text">
                      <span className="item-title">
                        {item.title}
                        {item.status === 'live-working' && (
                          <span style={{ fontSize: 10, color: '#10b981', fontWeight: 700, marginLeft: 4 }}>[LIVE]</span>
                        )}
                      </span>
                      <span className="item-desc">{item.desc}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
