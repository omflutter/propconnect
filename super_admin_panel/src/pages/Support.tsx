import { Search, Filter, MoreVertical, Ticket, Clock, CheckCircle, X } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';

export function Support() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [tickets, setTickets] = useState([
    { id: 'TKT-1001', subject: 'Cannot add new property', agency: 'Sunrise Properties', user: 'Om Shivam', status: 'Open', priority: 'High', date: '2026-07-23' },
    { id: 'TKT-1002', subject: 'Billing issue with Pro plan', agency: 'Metro Reality India', user: 'Rajesh Kumar', status: 'In Progress', priority: 'Medium', date: '2026-07-22' },
    { id: 'TKT-1003', subject: 'How to export deals?', agency: 'Bangalore Estates', user: 'Priya Sharma', status: 'Resolved', priority: 'Low', date: '2026-07-20' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');

  const handleResolve = (id: string) => {
    setTickets(tickets.map(t => t.id === id ? { ...t, status: 'Resolved' } : t));
    toast.success(`Ticket ${id} marked as resolved!`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Support Tickets</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Manage help requests and technical issues from agency users.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary">Export Tickets</button>
          <button className="btn-primary">Create Ticket</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Tickets</button>
            <button className={statusFilter === 'Open' ? 'active' : ''} onClick={() => setStatusFilter('Open')}>Open</button>
            <button className={statusFilter === 'In Progress' ? 'active' : ''} onClick={() => setStatusFilter('In Progress')}>In Progress</button>
            <button className={statusFilter === 'Resolved' ? 'active' : ''} onClick={() => setStatusFilter('Resolved')}>Resolved</button>
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
    </div>
  );
}
