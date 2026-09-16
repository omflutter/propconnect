import { ReactNode, useState, useRef, useEffect } from 'react';
import { NavLink, useNavigate, useLocation } from 'react-router-dom';
import toast from 'react-hot-toast';
import { 
  LayoutDashboard, Building2, Settings, LogOut, Briefcase, Users, Ticket, 
  Search, Bell, CreditCard, Banknote, MessageCircle,
  MessageSquare, Network, Activity, Smartphone, Link, Wallet, Rocket
} from 'lucide-react';
import { ConfirmModal } from './ConfirmModal';
import './Layout.css';

interface LayoutProps {
  children: ReactNode;
}

export function Layout({ children }: LayoutProps) {
  const navigate = useNavigate();
  const location = useLocation();

  const [showNotifs, setShowNotifs] = useState(false);
  const [unreadCount, setUnreadCount] = useState(3);
  const [showLogoutModal, setShowLogoutModal] = useState(false);
  const notifRef = useRef<HTMLDivElement>(null);

  const [topNotifs, setTopNotifs] = useState([
    { id: 1, title: 'New Collaboration Request', desc: 'Metro Reality requested collaboration on PR-105', time: '2m ago', link: '/collaborations', unread: true, icon: Network },
    { id: 2, title: 'Commission Payout Approved', desc: '₹4.2 Lakhs payout cleared for deal DL-501', time: '14m ago', link: '/commissions', unread: true, icon: Banknote },
    { id: 3, title: 'High Priority Support Ticket', desc: 'Ticket #TKT-1001 submitted by Sunrise Properties', time: '1h ago', link: '/support', unread: true, icon: Ticket },
    { id: 4, title: 'Razorpay Payment Received', desc: '₹7,999 Subscription renewal paid by Sunrise', time: '3h ago', link: '/gateways', unread: false, icon: CreditCard },
  ]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setShowNotifs(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleConfirmLogout = () => {
    localStorage.removeItem('isAuthenticated');
    localStorage.removeItem('userEmail');
    toast.success('Logged out of Super Admin Panel');
    setShowLogoutModal(false);
    navigate('/login');
  };

  const getBreadcrumbs = () => {
    const path = location.pathname.split('/').filter(Boolean);
    if (path.length === 0) return 'Dashboard / Command Center';
    return `Dashboard / ${path[0].charAt(0).toUpperCase() + path[0].slice(1)}`;
  };

  const handleMarkAllRead = () => {
    setTopNotifs(topNotifs.map(n => ({ ...n, unread: false })));
    setUnreadCount(0);
    toast.success('All notifications marked as read');
  };

  const handleNotifClick = (link: string, id: number) => {
    setTopNotifs(topNotifs.map(n => n.id === id ? { ...n, unread: false } : n));
    setUnreadCount(prev => Math.max(0, prev - 1));
    setShowNotifs(false);
    navigate(link);
  };

  const handleGenerateReport = () => {
    toast.success('Generating Platform YTD Audit Report... Download started!');
  };

  return (
    <div className="layout-container">
      {/* Heavy Enterprise Sidebar */}
      <aside className="sidebar-massive">
        <div className="sidebar-header">
          <Building2 className="logo-icon" size={26} />
          <h2>PropConnect CRM</h2>
        </div>

        <div className="sidebar-scrollable">
          <nav className="sidebar-nav-group">
            <span className="nav-group-title">OVERVIEW</span>
            <NavLink to="/" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`} end>
              <LayoutDashboard className="nav-icon" size={18} />
              <span>Command Center</span>
            </NavLink>
            <NavLink to="/audit-logs" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Activity className="nav-icon" size={18} />
              <span>Live Audit Logs</span>
            </NavLink>
          </nav>

          <nav className="sidebar-nav-group">
            <span className="nav-group-title">CORE CRM</span>
            <NavLink to="/agencies" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Building2 className="nav-icon" size={18} />
              <span>Agencies Matrix</span>
            </NavLink>
            <NavLink to="/brokers" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Users className="nav-icon" size={18} />
              <span>Platform Brokers</span>
            </NavLink>
            <NavLink to="/properties" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Building2 className="nav-icon" size={18} />
              <span>Global Inventory</span>
            </NavLink>
            <NavLink to="/leads" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Users className="nav-icon" size={18} />
              <span>Lead Ownership</span>
            </NavLink>
            <NavLink to="/deals" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Briefcase className="nav-icon" size={18} />
              <span>Deal Pipelines</span>
            </NavLink>
            <NavLink to="/collaborations" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Network className="nav-icon" size={18} />
              <span>Collaborations</span>
            </NavLink>
          </nav>

          <nav className="sidebar-nav-group">
            <span className="nav-group-title">FINANCE & BILLING</span>
            <NavLink to="/subscriptions" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <CreditCard className="nav-icon" size={18} />
              <span>SaaS Subscriptions</span>
            </NavLink>
            <NavLink to="/commissions" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Banknote className="nav-icon" size={18} />
              <span>Commissions</span>
            </NavLink>
            <NavLink to="/settlements" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Wallet className="nav-icon" size={18} />
              <span>Settlements</span>
            </NavLink>
          </nav>

          <nav className="sidebar-nav-group">
            <span className="nav-group-title">COMMUNICATION</span>
            <NavLink to="/whatsapp" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Smartphone className="nav-icon" size={18} />
              <span>WhatsApp API</span>
            </NavLink>
            <NavLink to="/chat-logs" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <MessageSquare className="nav-icon" size={18} />
              <span>Broker Chat Logs</span>
            </NavLink>
            <NavLink to="/notifications" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <MessageCircle className="nav-icon" size={18} />
              <span>Push Notifications</span>
            </NavLink>
          </nav>

          <nav className="sidebar-nav-group">
            <span className="nav-group-title">SYSTEM</span>
            <NavLink to="/gateways" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Link className="nav-icon" size={18} />
              <span>Payment Gateways</span>
            </NavLink>
            <NavLink to="/support" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Ticket className="nav-icon" size={18} />
              <span>Support Tickets</span>
            </NavLink>
            <NavLink to="/settings" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <Settings className="nav-icon" size={18} />
              <span>Platform Config</span>
            </NavLink>
          </nav>
        </div>
        
        <div className="user-profile">
          <div className="avatar">SA</div>
          <div className="user-info">
            <span className="user-name">Om Shivam</span>
            <span className="user-role">Super Admin</span>
          </div>
          <button className="logout-btn" onClick={() => setShowLogoutModal(true)} title="Sign Out">
            <LogOut size={18} />
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        {/* Top Navbar */}
        <header className="top-navbar-massive">
          <div className="topbar-left">
            <div className="breadcrumbs">{getBreadcrumbs()}</div>
            <div className="global-search-massive">
              <Search size={16} color="#64748B" />
              <input type="text" placeholder="Search ID, Broker, Agency..." />
            </div>
          </div>
          <div className="topbar-actions">
            <button className="btn-secondary" style={{ padding: '6px 12px', fontSize: 13, height: 32 }} onClick={handleGenerateReport}>
              Generate Report
            </button>
            <div className="divider-vertical"></div>
            
            {/* Notifications Dropdown */}
            <div className="notif-dropdown-wrapper" ref={notifRef}>
              <button 
                className="notification-btn" 
                onClick={() => setShowNotifs(!showNotifs)}
                title="Notifications"
              >
                <Bell size={18} />
                {unreadCount > 0 && <div className="notification-dot"></div>}
              </button>

              {showNotifs && (
                <div className="notif-menu">
                  <div className="notif-header">
                    <h4>System Alerts ({unreadCount})</h4>
                    <button className="mark-read-btn" onClick={handleMarkAllRead}>Mark all read</button>
                  </div>
                  <div className="notif-list">
                    {topNotifs.map((item) => {
                      const IconComponent = item.icon;
                      return (
                        <div 
                          key={item.id} 
                          className={`notif-item ${item.unread ? 'unread' : ''}`}
                          onClick={() => handleNotifClick(item.link, item.id)}
                        >
                          <div className="notif-item-icon">
                            <IconComponent size={14} />
                          </div>
                          <div>
                            <span className="notif-item-title">{item.title}</span>
                            <span className="notif-item-desc">{item.desc}</span>
                            <span className="notif-item-time">{item.time}</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  <div className="notif-footer">
                    <button className="notif-footer-btn" onClick={() => { setShowNotifs(false); navigate('/notifications'); }}>
                      View All System Notifications & Rules →
                    </button>
                  </div>
                </div>
              )}
            </div>

            <div className="topbar-avatar" title="Settings" onClick={() => navigate('/settings')}>
              SA
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="page-container-massive">
          {children}
        </div>
      </main>

      {/* Global ConfirmModal for Logout */}
      <ConfirmModal
        isOpen={showLogoutModal}
        title="Sign Out of Super Admin Panel"
        message="Are you sure you want to log out of your Super Admin account? Any unsaved changes in active forms will be lost."
        type="warning"
        confirmText="Sign Out"
        cancelText="Stay Logged In"
        onConfirm={handleConfirmLogout}
        onCancel={() => setShowLogoutModal(false)}
      />
    </div>
  );
}
