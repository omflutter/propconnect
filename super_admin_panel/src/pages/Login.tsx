import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Building2, Lock, Mail, ArrowRight, ShieldCheck } from 'lucide-react';
import toast from 'react-hot-toast';
import './Login.css';

export function Login() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('om@propconnect.in');
  const [password, setPassword] = useState('••••••••');
  const [rememberMe, setRememberMe] = useState(true);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      toast.error('Please enter email and password');
      return;
    }
    localStorage.setItem('isAuthenticated', 'true');
    localStorage.setItem('userEmail', email);
    toast.success('Authenticated as Platform Super Admin!');
    navigate('/');
  };

  const handleDemoAccess = () => {
    localStorage.setItem('isAuthenticated', 'true');
    localStorage.setItem('userEmail', 'om@propconnect.in');
    toast.success('Logged in via Quick Super Admin Access!');
    navigate('/');
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <div className="login-logo">
            <Building2 size={26} />
          </div>
          <h1>PropConnect India</h1>
          <p>SaaS Super Admin & Operations Portal</p>
        </div>

        <form className="login-form" onSubmit={handleLogin}>
          <div className="form-group">
            <label>Admin Email Address</label>
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
              <input 
                type="email" 
                className="form-input" 
                value={email} 
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@propconnect.in"
                required
                style={{ paddingLeft: '38px', width: '100%' }}
              />
              <Mail size={16} style={{ position: 'absolute', left: 12, color: 'var(--text-secondary)' }} />
            </div>
          </div>

          <div className="form-group">
            <label>Security Password</label>
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
              <input 
                type="password" 
                className="form-input" 
                value={password} 
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                style={{ paddingLeft: '38px', width: '100%' }}
              />
              <Lock size={16} style={{ position: 'absolute', left: 12, color: 'var(--text-secondary)' }} />
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 12.5 }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
              <input 
                type="checkbox" 
                checked={rememberMe} 
                onChange={(e) => setRememberMe(e.target.checked)} 
              />
              Remember session
            </label>
            <span 
              style={{ color: 'var(--primary-blue)', fontWeight: 600, cursor: 'pointer' }}
              onClick={() => toast.success('Password reset link sent to registered email.')}
            >
              Forgot Password?
            </span>
          </div>

          <button type="submit" className="btn-primary" style={{ width: '100%', padding: '12px', fontSize: '14px', marginTop: '8px' }}>
            Sign In to Super Admin <ArrowRight size={16} />
          </button>
        </form>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '4px 0' }}>
            <div style={{ flex: 1, height: 1, backgroundColor: 'var(--border)' }}></div>
            <span style={{ fontSize: 11, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>OR</span>
            <div style={{ flex: 1, height: 1, backgroundColor: 'var(--border)' }}></div>
          </div>

          <button 
            type="button" 
            className="btn-secondary" 
            style={{ width: '100%', padding: '10px', fontSize: '13px' }}
            onClick={handleDemoAccess}
          >
            <ShieldCheck size={16} color="var(--primary-blue)" /> Quick Super Admin Demo Login
          </button>
        </div>

        <div className="login-footer">
          PropConnect SaaS Platform v2.4 (Phase 1 PRD Standard) • ISO 27001 Secured
        </div>
      </div>
    </div>
  );
}
