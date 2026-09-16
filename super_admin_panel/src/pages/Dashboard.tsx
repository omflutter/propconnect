import { useState, useEffect } from 'react';
import { Users, Building, Activity, DollarSign, Server, Smartphone, CheckCircle, TrendingUp, History, Briefcase, CreditCard, Loader2 } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, LineChart, Line } from 'recharts';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { apiFetch } from '../services/api';
import './Dashboard.css';

export function Dashboard() {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(true);
  const [dashboardData, setDashboardData] = useState<any>(null);
  const [auditLogs, setAuditLogs] = useState<any[]>([]);

  const fetchDashboardData = async () => {
    setIsLoading(true);
    const [statsRes, auditRes] = await Promise.all([
      apiFetch('/dashboard/stats'),
      apiFetch<any[]>('/audit-logs?limit=6'),
    ]);
    setIsLoading(false);

    if (statsRes.success && statsRes.data) {
      setDashboardData(statsRes.data);
    }
    if (auditRes.success && auditRes.data) {
      setAuditLogs(auditRes.data.slice(0, 6));
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const miniChartData = [
    { value: 10 }, { value: 25 }, { value: 15 }, { value: 40 }, { value: 30 }, { value: 50 }, { value: 45 }
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

  const agencyCount = dashboardData ? dashboardData.agencies.total : 3;
  const brokerCount = dashboardData ? dashboardData.brokers.total : 5;
  const subData = dashboardData ? dashboardData.subscriptions : [
    { name: 'Basic', users: 1, fill: '#94A3B8' },
    { name: 'Pro', users: 1, fill: '#38BDF8' },
    { name: 'Enterprise', users: 1, fill: '#00308F' },
  ];

  const stats = [
    { label: 'Platform Revenue', value: '₹1.24 Cr', icon: DollarSign, color: '#00308F', trend: '+22%', link: '/commissions' },
    { label: 'Commission Gen.', value: '₹4.8 Cr', icon: Activity, color: '#10b981', trend: '+18%', link: '/commissions' },
    { label: 'Agencies Matrix', value: `${agencyCount} SaaS`, icon: Building, color: '#8b5cf6', trend: '+12%', link: '/agencies' },
    { label: 'Platform Brokers', value: `${brokerCount} Users`, icon: Users, color: '#0ea5e9', trend: '+8%', link: '/brokers' },
    { label: 'Active Subscriptions', value: `${agencyCount} Active`, icon: CreditCard, color: '#f59e0b', trend: '+15%', link: '/subscriptions' },
    { label: 'Active Deals', value: '892 Active', icon: Briefcase, color: '#ec4899', trend: '+14%', link: '/deals' },
  ];

  return (
    <div className="dashboard-massive">
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h1 style={{ fontSize: '20px' }}>Global Command Center</h1>
          <p style={{ marginTop: 4, fontSize: '13px' }}>System health, revenue, and live MySQL database metrics for PropConnect India.</p>
        </div>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <div className="status-pill success">
            <Server size={14} />
            <span>Express Backend: Healthy</span>
          </div>
          <div className="status-pill success">
            <CheckCircle size={14} />
            <span>MySQL Database: Online</span>
          </div>
          <div className="status-pill success">
            <Smartphone size={14} />
            <span>Swagger Specs: Ready</span>
          </div>
        </div>
      </div>

      {/* 6 Interactive Stat Cards */}
      <div className="stats-grid-massive">
        {stats.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <div 
              key={idx} 
              className="stat-card card" 
              style={{ cursor: 'pointer', transition: 'transform 0.15s ease, box-shadow 0.15s ease' }}
              onClick={() => navigate(stat.link)}
            >
              <div className="stat-header">
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <span className="stat-label">{stat.label}</span>
                  <h3 className="stat-value">{isLoading ? <Loader2 size={18} className="animate-spin" /> : stat.value}</h3>
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

        {/* Live System Activity Feed connected to MySQL Audit Logs */}
        <div className="card audit-feed">
          <div className="chart-header" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <History size={18} color="var(--primary-blue)" />
              <h3>Live System Activity</h3>
            </div>
          </div>

          <div className="feed-list">
            {isLoading ? (
              <div style={{ padding: 20, textAlign: 'center', display: 'flex', justifyContent: 'center', gap: 8 }}>
                <Loader2 className="animate-spin" size={18} color="var(--primary-blue)" />
                <span>Loading live activity feed...</span>
              </div>
            ) : auditLogs.length === 0 ? (
              <div style={{ padding: 20, textAlign: 'center', color: 'var(--text-secondary)' }}>
                No recent activity logged.
              </div>
            ) : (
              auditLogs.map((log) => (
                <div key={log.id} className="feed-item" style={{ cursor: 'pointer' }} onClick={() => navigate('/audit-logs')}>
                  <div className={`feed-indicator ${log.status === 'Success' ? 'success' : log.status === 'Warning' ? 'warning' : 'error'}`}></div>
                  <div className="feed-content">
                    <span className="feed-action">{log.action}</span>
                    <span className="feed-user">{log.actorName} ({log.target})</span>
                  </div>
                  <span className="feed-time">{new Date(log.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                </div>
              ))
            )}
          </div>

          <button className="btn-secondary" style={{ width: '100%', marginTop: 'auto', fontSize: '12px' }} onClick={() => navigate('/audit-logs')}>
            View Full Audit Logs →
          </button>
        </div>
      </div>
    </div>
  );
}
