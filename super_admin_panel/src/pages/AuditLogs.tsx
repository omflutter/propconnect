import { useState, useEffect } from 'react';
import { Search, Filter, Shield, Clock, Terminal, Loader2, Download, RefreshCw, X, Copy, Calendar } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';
import './AuditLogs.css';

export interface AuditLogItem {
  id: number;
  logCode: string;
  actorName: string;
  actorRole: string;
  action: string;
  target: string;
  ipAddress: string;
  status: 'Success' | 'Warning' | 'Error';
  details?: Record<string, any>;
  createdAt: string;
}

export function AuditLogs() {
  const [statusFilter, setStatusFilter] = useState('All');
  const [dateFilter, setDateFilter] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isAutoPolling, setIsAutoPolling] = useState(true);
  const [logs, setLogs] = useState<AuditLogItem[]>([]);
  const [inspectingLog, setInspectingLog] = useState<AuditLogItem | null>(null);

  const fetchAuditLogs = async (silent = false) => {
    if (!silent) setIsLoading(true);
    let url = '/audit-logs';
    const queryParams: string[] = [];

    if (statusFilter !== 'All') queryParams.push(`status=${statusFilter}`);
    if (dateFilter) queryParams.push(`date=${dateFilter}`);
    if (searchQuery) queryParams.push(`search=${encodeURIComponent(searchQuery)}`);

    if (queryParams.length > 0) {
      url += `?${queryParams.join('&')}`;
    }

    const res = await apiFetch<AuditLogItem[]>(url);
    if (!silent) setIsLoading(false);

    if (res.success && res.data) {
      setLogs(res.data);
    } else if (!silent) {
      toast.error(res.message || 'Failed to fetch audit logs');
    }
  };

  useEffect(() => {
    fetchAuditLogs();
  }, [statusFilter, dateFilter]);

  // Real-Time 5-Second Auto Refresh Polling
  useEffect(() => {
    let interval: ReturnType<typeof setInterval>;
    if (isAutoPolling) {
      interval = setInterval(() => {
        fetchAuditLogs(true);
      }, 5000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isAutoPolling, statusFilter, dateFilter, searchQuery]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchAuditLogs();
  };

  const setQuickDate = (type: 'today' | 'yesterday' | 'clear') => {
    const now = new Date();
    if (type === 'today') {
      const dateStr = now.toISOString().split('T')[0];
      setDateFilter(dateStr);
      toast.success(`Filtered logs for Today (${dateStr})`);
    } else if (type === 'yesterday') {
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const dateStr = yesterday.toISOString().split('T')[0];
      setDateFilter(dateStr);
      toast.success(`Filtered logs for Yesterday (${dateStr})`);
    } else {
      setDateFilter('');
      toast.success('Cleared day filter (All Time)');
    }
  };

  const handleExportJSON = () => {
    if (!logs || logs.length === 0) {
      toast.error('No audit log entries available to export.');
      return;
    }

    const jsonContent = JSON.stringify(logs, null, 2);
    const blob = new Blob([jsonContent], { type: 'application/json;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    const dateStr = dateFilter || new Date().toISOString().split('T')[0];
    link.setAttribute('href', url);
    link.setAttribute('download', `PropConnect_Audit_Logs_${dateStr}.json`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success(`Exported ${logs.length} audit logs to JSON file!`);
  };

  const handleExportCSV = () => {
    if (!logs || logs.length === 0) {
      toast.error('No audit log entries available to export.');
      return;
    }

    const headers = ['Log ID', 'Timestamp', 'Actor Name', 'Actor Role', 'Action', 'Target Resource', 'Client IP', 'Status'];

    const escapeCSV = (value: any) => {
      if (value === null || value === undefined) return '""';
      const str = String(value).replace(/"/g, '""');
      return `"${str}"`;
    };

    const csvRows = [
      headers.join(','),
      ...logs.map((log) =>
        [
          escapeCSV(log.logCode),
          escapeCSV(new Date(log.createdAt).toLocaleString()),
          escapeCSV(log.actorName),
          escapeCSV(log.actorRole),
          escapeCSV(log.action),
          escapeCSV(log.target),
          escapeCSV(log.ipAddress),
          escapeCSV(log.status),
        ].join(',')
      ),
    ];

    const csvContent = '\uFEFF' + csvRows.join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    const dateStr = dateFilter || new Date().toISOString().split('T')[0];
    link.setAttribute('href', url);
    link.setAttribute('download', `PropConnect_Audit_Logs_${dateStr}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success(`Exported ${logs.length} audit logs to CSV file!`);
  };

  const handleCopyJSONPayload = () => {
    if (!inspectingLog) return;
    navigator.clipboard.writeText(JSON.stringify(inspectingLog, null, 2));
    toast.success('Audit log JSON copied to clipboard!');
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Platform Audit Logs & Trail</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Complete tamper-proof audit trail for every action across all tenant agencies in MySQL database.</p>
        </div>
        <div className="header-actions">
          <button 
            className={`live-poll-btn ${isAutoPolling ? 'active' : ''}`}
            onClick={() => {
              setIsAutoPolling(!isAutoPolling);
              toast.success(`Real-time polling ${!isAutoPolling ? 'enabled' : 'paused'}`);
            }}
          >
            <span className="pulse-dot"></span>
            {isAutoPolling ? 'Live Refresh Active (5s)' : 'Live Refresh Paused'}
          </button>
          <button className="btn-secondary" onClick={handleExportCSV}>
            <Download size={14} style={{ marginRight: 6 }} /> CSV
          </button>
          <button className="btn-primary" onClick={handleExportJSON}>
            <Download size={14} style={{ marginRight: 6 }} /> Export JSON
          </button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)', flexWrap: 'wrap', gap: 12, alignItems: 'center' }}>
          {/* Status Tabs */}
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Events</button>
            <button className={statusFilter === 'Success' ? 'active' : ''} onClick={() => setStatusFilter('Success')}>Success</button>
            <button className={statusFilter === 'Warning' ? 'active' : ''} onClick={() => setStatusFilter('Warning')}>Warnings</button>
            <button className={statusFilter === 'Error' ? 'active' : ''} onClick={() => setStatusFilter('Error')}>Errors</button>
          </div>

          {/* Day / Date Filter Controls */}
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, backgroundColor: 'var(--background)', padding: '4px 10px', borderRadius: 8, border: '1px solid var(--border)' }}>
              <Calendar size={15} color="var(--primary-blue)" />
              <input 
                type="date"
                style={{ border: 'none', background: 'transparent', color: 'var(--text-primary)', fontSize: 13, outline: 'none' }}
                value={dateFilter}
                onChange={(e) => setDateFilter(e.target.value)}
                title="Filter by specific day"
              />
              {dateFilter && (
                <button 
                  type="button" 
                  style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', padding: 2 }}
                  onClick={() => setQuickDate('clear')}
                  title="Clear date filter"
                >
                  <X size={14} />
                </button>
              )}
            </div>

            <div style={{ display: 'flex', gap: 4 }}>
              <button 
                className={`btn-secondary ${!dateFilter ? 'active' : ''}`}
                style={{ padding: '6px 10px', fontSize: 12 }}
                onClick={() => setQuickDate('clear')}
              >
                All Time
              </button>
              <button 
                className="btn-secondary" 
                style={{ padding: '6px 10px', fontSize: 12 }}
                onClick={() => setQuickDate('today')}
              >
                Today
              </button>
              <button 
                className="btn-secondary" 
                style={{ padding: '6px 10px', fontSize: 12 }}
                onClick={() => setQuickDate('yesterday')}
              >
                Yesterday
              </button>
            </div>

            {/* Search Box */}
            <form onSubmit={handleSearchSubmit} style={{ display: 'flex', gap: 12 }}>
              <div className="search-box">
                <Search className="search-icon" size={16} />
                <input 
                  type="text" 
                  placeholder="Search action or actor..." 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <button type="button" className="btn-secondary" onClick={() => fetchAuditLogs()}>
                <RefreshCw size={14} /> Refresh
              </button>
            </form>
          </div>
        </div>

        <div className="table-wrapper">
          {isLoading ? (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', padding: 40, gap: 12 }}>
              <Loader2 className="animate-spin" size={24} color="var(--primary-blue)" />
              <span>Loading audit trail from MySQL database...</span>
            </div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                  <th>Log ID & Time</th>
                  <th>Actor Name & Role</th>
                  <th>Action Type</th>
                  <th>Target Resource</th>
                  <th>Client IP</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {logs.length === 0 ? (
                  <tr>
                    <td colSpan={8} style={{ textAlign: 'center', padding: 30, color: 'var(--text-secondary)' }}>
                      No audit log events found {dateFilter ? `for date ${dateFilter}` : ''}.
                    </td>
                  </tr>
                ) : (
                  logs.map((log) => (
                    <tr key={log.id}>
                      <td><input type="checkbox" className="table-checkbox" /></td>
                      <td>
                        <div className="entity-info">
                          <div>
                            <strong>{log.logCode}</strong>
                            <span className="entity-sub">{new Date(log.createdAt).toLocaleString()}</span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="audit-actor">
                          <strong>{log.actorName}</strong>
                          <span className="entity-sub">{log.actorRole}</span>
                        </div>
                      </td>
                      <td>
                        <span className="audit-action-tag">{log.action}</span>
                      </td>
                      <td>{log.target}</td>
                      <td><span style={{ fontFamily: 'monospace', fontSize: 12 }}>{log.ipAddress}</span></td>
                      <td>
                        <span className={`status-badge ${log.status === 'Success' ? 'closed' : log.status === 'Warning' ? 'negotiation' : 'dropped'}`}>
                          {log.status}
                        </span>
                      </td>
                      <td>
                        <div className="action-buttons">
                          <ActionDropdown 
                            actions={[
                              { label: 'Inspect Payload / Context', onClick: () => setInspectingLog(log) },
                            ]}
                          />
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          )}
        </div>

        <div className="pagination">
          <span className="page-info">Total Logged System Events {dateFilter ? `(Date: ${dateFilter})` : ''}: {logs.length}</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>

      {/* Code Payload Inspector Modal */}
      {inspectingLog && (
        <div className="modal-overlay">
          <div className="modal-content large" style={{ maxWidth: 680 }}>
            <div className="modal-header">
              <h2>Inspect Audit Payload: {inspectingLog.logCode}</h2>
              <button className="icon-btn" onClick={() => setInspectingLog(null)}><X size={20} /></button>
            </div>
            
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, fontSize: 13 }}>
                <div><strong>Actor:</strong> {inspectingLog.actorName} ({inspectingLog.actorRole})</div>
                <div><strong>Client IP:</strong> <code style={{ color: 'var(--primary-blue)' }}>{inspectingLog.ipAddress}</code></div>
                <div><strong>Action:</strong> {inspectingLog.action}</div>
                <div><strong>Timestamp:</strong> {new Date(inspectingLog.createdAt).toLocaleString()}</div>
              </div>

              <div className="code-inspector-container">
                <div className="code-inspector-header">
                  <span>RAW EVENT JSON & PAYLOAD METADATA</span>
                  <button className="icon-btn" style={{ color: '#94a3b8' }} onClick={handleCopyJSONPayload} title="Copy JSON">
                    <Copy size={16} />
                  </button>
                </div>
                <div className="code-inspector-body">
                  <pre>{JSON.stringify(inspectingLog, null, 2)}</pre>
                </div>
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setInspectingLog(null)}>Close</button>
              <button className="btn-primary" onClick={handleCopyJSONPayload}>
                <Copy size={14} style={{ marginRight: 6 }} /> Copy Payload JSON
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
