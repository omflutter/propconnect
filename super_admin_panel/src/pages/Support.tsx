import { Search, Filter, MoreVertical, Ticket, Clock, CheckCircle, X, Plus, Loader2 } from 'lucide-react';
import { useState, useEffect } from 'react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';

export function Support() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [agencies, setAgencies] = useState<any[]>([]);

  const [newTicket, setNewTicket] = useState({
    subject: '',
    agency: '',
    user: '',
    priority: 'Medium',
  });

  const [tickets, setTickets] = useState<any[]>(() => {
    try {
      const saved = localStorage.getItem('propconnect_support_tickets');
      if (saved) return JSON.parse(saved);
    } catch (_) {}
    return [];
  });

  useEffect(() => {
    apiFetch<any[]>('/agencies').then((res) => {
      if (res.success && Array.isArray(res.data)) {
        setAgencies(res.data);
        if (res.data.length > 0 && tickets.length === 0) {
          const initialTickets = res.data.slice(0, 3).map((a, idx) => ({
            id: `TKT-100${idx + 1}`,
            subject: idx === 0 ? 'Billing inquiry for SaaS tier' : idx === 1 ? 'Broker onboarding verification query' : 'Property sync API webhook status',
            agency: a.name,
            user: a.contactPerson || 'Agency Admin',
            status: idx === 0 ? 'Open' : idx === 1 ? 'In Progress' : 'Resolved',
            priority: idx === 0 ? 'High' : 'Medium',
            date: a.createdAt ? a.createdAt.substring(0, 10) : new Date().toISOString().substring(0, 10),
          }));
          setTickets(initialTickets);
          try {
            localStorage.setItem('propconnect_support_tickets', JSON.stringify(initialTickets));
          } catch (_) {}
        }
      }
    });
  }, []);

  const handleResolve = (id: string) => {
    const updated = tickets.map(t => t.id === id ? { ...t, status: 'Resolved' } : t);
    setTickets(updated);
    try {
      localStorage.setItem('propconnect_support_tickets', JSON.stringify(updated));
    } catch (_) {}
    toast.success(`Ticket ${id} marked as resolved!`);
  };

  const handleCreateTicket = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTicket.subject.trim()) {
      toast.error('Subject is required');
      return;
    }
    const created = {
      id: `TKT-${1000 + tickets.length + 1}`,
      subject: newTicket.subject,
      agency: newTicket.agency || (agencies[0]?.name || 'Sunrise Properties'),
      user: newTicket.user || 'Agency Admin',
      priority: newTicket.priority,
      status: 'Open',
      date: new Date().toISOString().substring(0, 10),
    };
    const updated = [created, ...tickets];
    setTickets(updated);
    try {
      localStorage.setItem('propconnect_support_tickets', JSON.stringify(updated));
    } catch (_) {}
    setShowCreateModal(false);
    setNewTicket({ subject: '', agency: '', user: '', priority: 'Medium' });
    toast.success(`Ticket ${created.id} created successfully!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Support Tickets</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage help requests and technical issues from agency users.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Exporting tickets')}>Export Tickets</button>
          <button className="btn-primary" onClick={() => setShowCreateModal(true)}>+ Create Ticket</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Tickets ({tickets.length})</button>
            <button className={statusFilter === 'Open' ? 'active' : ''} onClick={() => setStatusFilter('Open')}>Open ({tickets.filter(t => t.status === 'Open').length})</button>
            <button className={statusFilter === 'In Progress' ? 'active' : ''} onClick={() => setStatusFilter('In Progress')}>In Progress ({tickets.filter(t => t.status === 'In Progress').length})</button>
            <button className={statusFilter === 'Resolved' ? 'active' : ''} onClick={() => setStatusFilter('Resolved')}>Resolved ({tickets.filter(t => t.status === 'Resolved').length})</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search tickets..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <button className="btn-secondary filter-btn" onClick={() => setShowFilterModal(true)}>
              <Filter size={16} /> Filters
            </button>
          </div>
        </div>

        <div className="table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                <th>Ticket Info</th>
                <th>Agency & User</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Created Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {tickets
                .filter(t => t.subject.toLowerCase().includes(searchQuery.toLowerCase()) || t.id.toLowerCase().includes(searchQuery.toLowerCase()))
                .filter(t => statusFilter === 'All' ? true : t.status === statusFilter)
                .map((ticket) => (
                <tr key={ticket.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div className="entity-avatar"><Ticket size={20} /></div>
                      <div>
                        <strong>{ticket.subject}</strong>
                        <span className="entity-sub">{ticket.id}</span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                      <span className="agency-tag" style={{ width: 'fit-content' }}>{ticket.agency}</span>
                      <span className="entity-sub">{ticket.user}</span>
                    </div>
                  </td>
                  <td>
                    <span style={{ 
                      color: ticket.priority === 'High' ? 'var(--error)' : ticket.priority === 'Medium' ? 'var(--warning)' : 'var(--text-secondary)',
                      fontWeight: 600, fontSize: 13 
                    }}>
                      {ticket.priority}
                    </span>
                  </td>
                  <td>
                    <span className={`status-badge ${ticket.status.toLowerCase().replace(' ', '-')}`}>
                      {ticket.status}
                    </span>
                  </td>
                  <td>
                    <div className="entity-sub">
                      <Clock size={12} style={{ marginRight: 4 }} />
                      {ticket.date}
                    </div>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Ticket Thread', onClick: () => toast.success(`Viewing thread ${ticket.id}`) },
                          { label: 'Escalate Priority', onClick: () => toast.error('Ticket escalated!') },
                          { label: 'Mark as Resolved', onClick: () => handleResolve(ticket.id), danger: false },
                        ]}
                      />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        <div className="pagination">
          <span className="page-info">Showing results for filter: {statusFilter}</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>

      {showFilterModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Filter Tickets</h2>
              <button className="icon-btn" onClick={() => setShowFilterModal(false)}><X size={20} /></button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <label>Filter by Status</label>
                <select 
                  className="form-select" 
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <option value="All">All Statuses</option>
                  <option value="Open">Open</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Resolved">Resolved</option>
                </select>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-primary" onClick={() => setShowFilterModal(false)}>Apply Filters</button>
            </div>
          </div>
        </div>
      )}

      {showCreateModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Create New Support Ticket</h2>
              <button className="icon-btn" onClick={() => setShowCreateModal(false)}><X size={20} /></button>
            </div>
            <form onSubmit={handleCreateTicket}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <div className="form-group">
                  <label>Subject / Issue Summary</label>
                  <input 
                    className="form-input" 
                    required 
                    placeholder="e.g. Cannot download GST invoice"
                    value={newTicket.subject}
                    onChange={(e) => setNewTicket({ ...newTicket, subject: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Target Agency</label>
                  <select 
                    className="form-select"
                    value={newTicket.agency}
                    onChange={(e) => setNewTicket({ ...newTicket, agency: e.target.value })}
                  >
                    {agencies.map(a => (
                      <option key={a.id} value={a.name}>{a.name}</option>
                    ))}
                    {agencies.length === 0 && <option value="Sunrise Properties">Sunrise Properties</option>}
                  </select>
                </div>
                <div className="form-group">
                  <label>Reporter / Broker Name</label>
                  <input 
                    className="form-input" 
                    placeholder="e.g. Om Shivam"
                    value={newTicket.user}
                    onChange={(e) => setNewTicket({ ...newTicket, user: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Priority</label>
                  <select 
                    className="form-select"
                    value={newTicket.priority}
                    onChange={(e) => setNewTicket({ ...newTicket, priority: e.target.value })}
                  >
                    <option value="Low">Low</option>
                    <option value="Medium">Medium</option>
                    <option value="High">High</option>
                  </select>
                </div>
              </div>
              <div className="modal-footer" style={{ marginTop: 20 }}>
                <button type="button" className="btn-secondary" onClick={() => setShowCreateModal(false)}>Cancel</button>
                <button type="submit" className="btn-primary">Create Ticket</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
