import { Users, Building, Activity, DollarSign, Server, Smartphone, CheckCircle, AlertTriangle, TrendingUp, History, Briefcase, CreditCard } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, LineChart, Line } from 'recharts';
import { useNavigate } from 'react-router-dom';
import './Dashboard.css';

export function Dashboard() {
  const navigate = useNavigate();

  const miniChartData = [
    { value: 10 }, { value: 25 }, { value: 15 }, { value: 40 }, { value: 30 }, { value: 50 }, { value: 45 }
  ];

  const stats = [
    { label: 'Platform Revenue', value: '₹1.24 Cr', icon: DollarSign, color: '#00308F', trend: '+22%' },
    { label: 'Commission Gen.', value: '₹4.8 Cr', icon: Activity, color: '#10b981', trend: '+18%' },
    { label: 'Active Subscriptions', value: '142', icon: CreditCard, color: '#f59e0b', trend: '+12%' },
    { label: 'Public Properties', value: '3,845', icon: Building, color: '#8b5cf6', trend: '+5.2%' },
    { label: 'Active Deals', value: '892', icon: Briefcase, color: '#ec4899', trend: '+14%' },
    { label: 'Platform Brokers', value: '1,204', icon: Users, color: '#0ea5e9', trend: '+8%' },
  ];

  const chartData = [
    { name: 'Jan', revenue: 40, commission: 24 },
    { name: 'Feb', revenue: 30, commission: 13 },
    { name: 'Mar', revenue: 50, commission: 98 },
    { name: 'Apr', revenue: 87, commission: 39 },
    { name: 'May', revenue: 58, commission: 48 },
    { name: 'Jun', revenue: 93, commission: 38 },
    { name: 'Jul', revenue: 124, commission: 43 },
  ];

  const subData = [
    { name: 'Basic', users: 80, fill: '#94A3B8' },
    { name: 'Pro', users: 45, fill: '#38BDF8' },
    { name: 'Enterprise', users: 17, fill: '#00308F' },
  ];

  const auditLogs = [
    { time: '2m ago', action: 'Agency Profile Updated', user: 'Sunrise Properties', type: 'info' },
    { time: '14m ago', action: 'New Collaboration Request', user: 'Metro Reality -> Bangalore Estates', type: 'success' },
    { time: '1h ago', action: 'Deal Stage Changed: Closed', user: 'DL-502', type: 'success' },
    { time: '2h ago', action: 'Failed Payment Hook', user: 'Razorpay API', type: 'error' },
    { time: '3h ago', action: 'New Property Added', user: 'PR-109 (₹4.5Cr)', type: 'info' },
    { time: '4h ago', action: 'Broker Account Suspended', user: 'Om Shivam', type: 'warning' },
  ];

  return (
    <div className="dashboard-massive">
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '20px' }}>Global Command Center</h1>
          <p style={{ marginTop: 4, fontSize: '13px' }}>System health, revenue, and platform-wide metrics for PropConnect India.</p>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <div className="status-pill success">
            <Server size={14} />
            <span>AWS Mumbai: Healthy</span>
          </div>
          <div className="status-pill success">
            <CheckCircle size={14} />
            <span>Razorpay: Online</span>
          </div>
          <div className="status-pill success">
            <Smartphone size={14} />
            <span>WhatsApp API: Online</span>
          </div>
        </div>
      </div>

      {/* Massive 6-Card Top Row */}
      <div className="stats-grid-massive">
        {stats.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <div key={idx} className="stat-card card">
              <div className="stat-header">
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <span className="stat-label">{stat.label}</span>
                  <h3 className="stat-value">{stat.value}</h3>
                </div>
                <div className="stat-icon-wrapper" style={{ backgroundColor: `${stat.color}15` }}>
                  <Icon className="stat-icon" size={20} style={{ color: stat.color }} />
                </div>
              </div>
              <div className="stat-footer">
                <span className="trend positive">
                  <TrendingUp size={12} /> {stat.trend}
                </span>
                <div style={{ height: 24, width: 60 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={miniChartData}>
                      <Line type="monotone" dataKey="value" stroke={stat.color} strokeWidth={2} dot={false} />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="dashboard-content-massive">
        <div className="chart-section" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div className="chart-container card">
            <div className="chart-header">
              <h3>Financial Overview (YTD)</h3>
              <span className="subtitle">Revenue vs Commission Generated (in Lakhs)</span>
            </div>
            <div className="chart-wrapper">
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={chartData} margin={{ top: 10, right: 0, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#00308F" stopOpacity={0.4}/>
                      <stop offset="95%" stopColor="#00308F" stopOpacity={0}/>
                    </linearGradient>
                    <linearGradient id="colorCom" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.4}/>
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="name" stroke="#94A3B8" fontSize={11} tickLine={false} axisLine={false} />
                  <YAxis stroke="#94A3B8" fontSize={11} tickLine={false} axisLine={false} tickFormatter={(v) => `₹${v}L`} />
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                  <Tooltip contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', fontSize: '12px' }} />
                  <Area type="monotone" dataKey="revenue" name="Platform Revenue" stroke="#00308F" strokeWidth={2} fillOpacity={1} fill="url(#colorRev)" />
                  <Area type="monotone" dataKey="commission" name="Broker Commission" stroke="#10b981" strokeWidth={2} fillOpacity={1} fill="url(#colorCom)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="chart-container card">
            <div className="chart-header">
              <h3>Active Subscriptions by Tier</h3>
            </div>
            <div className="chart-wrapper">
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={subData} margin={{ top: 10, right: 0, left: -20, bottom: 0 }} layout="vertical">
                  <XAxis type="number" stroke="#94A3B8" fontSize={11} tickLine={false} axisLine={false} />
                  <YAxis type="category" dataKey="name" stroke="#94A3B8" fontSize={11} tickLine={false} axisLine={false} />
                  <Tooltip cursor={{fill: 'transparent'}} contentStyle={{ borderRadius: '8px', border: 'none', fontSize: '12px' }} />
                  <Bar dataKey="users" name="Agencies" radius={[0, 4, 4, 0]} barSize={24} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* Live Audit Log Feed */}
        <div className="card audit-feed">
          <div className="chart-header" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <History size={18} color="var(--primary-blue)" />
              <h3>Live System Activity</h3>
            </div>
          </div>
          <div className="feed-list">
            {auditLogs.map((log, i) => (
              <div key={i} className="feed-item">
                <div className={`feed-indicator ${log.type}`}></div>
                <div className="feed-content">
                  <span className="feed-action">{log.action}</span>
                  <span className="feed-user">{log.user}</span>
                </div>
                <span className="feed-time">{log.time}</span>
              </div>
            ))}
          </div>
          <button className="btn-secondary" style={{ width: '100%', marginTop: 'auto', fontSize: '12px' }} onClick={() => navigate('/audit-logs')}>
            View Full Audit Logs
          </button>
        </div>
      </div>
    </div>
  );
}

// Ensure Briefcase and CreditCard are available by importing them properly at the top.
// Wait, I missed importing them in the line above. Let me add them to the import.
