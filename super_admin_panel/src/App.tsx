import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Layout } from './components/Layout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Agencies } from './pages/Agencies';
import { AgencyProfile } from './pages/AgencyProfile';
import { Properties } from './pages/Properties';
import { Deals } from './pages/Deals';
import { Brokers } from './pages/Brokers';
import { Support } from './pages/Support';
import { Settings } from './pages/Settings';
import { Subscriptions } from './pages/Subscriptions';
import { Commissions } from './pages/Commissions';
import { Settlements } from './pages/Settlements';
import { Collaborations } from './pages/Collaborations';
import { Leads } from './pages/Leads';
import { WhatsApp } from './pages/WhatsApp';
import { Gateways } from './pages/Gateways';
import { AuditLogs } from './pages/AuditLogs';
import { ChatLogs } from './pages/ChatLogs';
import { Notifications } from './pages/Notifications';
import { Toaster } from 'react-hot-toast';
import './App.css';

// Protected Route Component
function ProtectedRoute({ children }: { children: JSX.Element }) {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true';
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <Layout>{children}</Layout>;
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route path="/" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
        <Route path="/audit-logs" element={<ProtectedRoute><AuditLogs /></ProtectedRoute>} />
        
        <Route path="/agencies" element={<ProtectedRoute><Agencies /></ProtectedRoute>} />
        <Route path="/agencies/:id" element={<ProtectedRoute><AgencyProfile /></ProtectedRoute>} />
        <Route path="/brokers" element={<ProtectedRoute><Brokers /></ProtectedRoute>} />
        <Route path="/properties" element={<ProtectedRoute><Properties /></ProtectedRoute>} />
        <Route path="/leads" element={<ProtectedRoute><Leads /></ProtectedRoute>} />
        <Route path="/deals" element={<ProtectedRoute><Deals /></ProtectedRoute>} />
        <Route path="/collaborations" element={<ProtectedRoute><Collaborations /></ProtectedRoute>} />
        
        <Route path="/subscriptions" element={<ProtectedRoute><Subscriptions /></ProtectedRoute>} />
        <Route path="/commissions" element={<ProtectedRoute><Commissions /></ProtectedRoute>} />
        <Route path="/settlements" element={<ProtectedRoute><Settlements /></ProtectedRoute>} />
        
        <Route path="/whatsapp" element={<ProtectedRoute><WhatsApp /></ProtectedRoute>} />
        <Route path="/chat-logs" element={<ProtectedRoute><ChatLogs /></ProtectedRoute>} />
        <Route path="/notifications" element={<ProtectedRoute><Notifications /></ProtectedRoute>} />
        
        <Route path="/gateways" element={<ProtectedRoute><Gateways /></ProtectedRoute>} />
        <Route path="/support" element={<ProtectedRoute><Support /></ProtectedRoute>} />
        <Route path="/settings" element={<ProtectedRoute><Settings /></ProtectedRoute>} />
        
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <Toaster position="top-right" />
    </BrowserRouter>
  );
}

export default App;
