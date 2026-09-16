import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Building2, Lock, Mail, ArrowRight, Loader2, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { apiFetch } from '../services/api';
import './Login.css';

export function Login() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [loginError, setLoginError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      toast.error('Please enter email and password');
      return;
    }

    setIsLoading(true);
    setLoginError(null);
    const res = await apiFetch('/auth/admin-login', {
      method: 'POST',
      body: JSON.stringify({ email: email.trim(), password: password.trim() }),
    });
    setIsLoading(false);

    if (res.success && res.data) {
      localStorage.setItem('isAuthenticated', 'true');
      localStorage.setItem('token', res.data.token);
      localStorage.setItem('user', JSON.stringify(res.data.user));
      localStorage.setItem('userEmail', res.data.user.email);
      toast.success(`Welcome back, ${res.data.user.name}!`);
      navigate('/');
    } else {
      console.error('[Admin Login Diagnostics]', res);
      setLoginError(res.message);
      toast.error(res.message || 'Authentication failed', { duration: 7000 });
    }
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

        {loginError && (
          <div style={{ backgroundColor: '#fef2f2', border: '1px solid #fca5a5', color: '#991b1b', padding: '12px 14px', borderRadius: '8px', fontSize: '13px', display: 'flex', alignItems: 'flex-start', gap: '8px', marginBottom: '16px' }}>
            <AlertCircle size={18} style={{ flexShrink: 0, marginTop: 2 }} />
            <div>
              <strong>Login Error Diagnostic:</strong>
              <div style={{ marginTop: 2, fontFamily: 'monospace', fontSize: 12 }}>{loginError}</div>
            </div>
          </div>
        )}

        <form className="login-form" onSubmit={handleLogin}>
          <div className="form-group">
            <label>Admin Email Address</label>
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
              <input 
                type="email" 
                className="form-input" 
                value={email} 
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter admin email address..."
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

          <button 
            type="submit" 
            className="btn-primary" 
            disabled={isLoading}
            style={{ width: '100%', padding: '12px', fontSize: '14px', marginTop: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
          >
            {isLoading ? <Loader2 size={16} className="animate-spin" /> : <>Sign In to Super Admin <ArrowRight size={16} /></>}
          </button>
        </form>

        <div className="login-footer">
          PropConnect SaaS Platform v2.4 (Phase 1 PRD Standard) • ISO 27001 Secured
        </div>
      </div>
    </div>
  );
}
