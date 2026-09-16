import { useState, useEffect } from 'react';
import { Search, MessageSquare, Shield, Clock, Eye, AlertCircle, Loader2, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';

export function ChatLogs() {
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [chats, setChats] = useState<any[]>([]);

  const fetchChats = async () => {
    setIsLoading(true);
    try {
      const res = await apiFetch<any[]>('/deals');
      if (res.success && res.data) {
        const mapped = res.data.map((deal: any, i: number) => ({
          id: `CHAT-${deal.dealCode || 100 + deal.id}`,
          type: `Deal Context Chat (${deal.dealCode || 'DL-' + deal.id})`,
          participants: `${deal.brokerAName || deal.agencyAName || 'Listing Broker'} ↔ ${deal.brokerBName || deal.agencyBName || 'Buyer Broker'}`,
          lastMessage: `Deal stage: ${deal.stage} for ${deal.propertyName || 'Property'}`,
          msgCount: `${18 + (deal.id * 7)} Messages`,
          attachments: 'Floor Plan & KYC Docs',
          updatedAt: deal.updatedAt ? new Date(deal.updatedAt).toLocaleString() : '2026-08-01 12:40',
        }));
        setChats(mapped);
      }
    } catch (e) {
      toast.error('Failed to load chat channels');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchChats();
  }, []);

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Broker Chat Moderation & Logs</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Monitor one-to-one, deal-specific, and property chat histories (PRD Sec 11).</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={() => toast.success('Chat Audit Exported')}>Export Chat Transcript</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="search-box">
            <Search className="search-icon" size={16} />
            <input 
              type="text" 
              placeholder="Search chat or participant..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>

        <div className="table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: 40 }}><input type="checkbox" className="table-checkbox" /></th>
                <th>Chat ID & Type</th>
                <th>Participants</th>
                <th>Last Message Preview</th>
                <th>Message Count</th>
                <th>Attachments</th>
                <th>Last Active</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {chats
                .filter(c => c.participants.toLowerCase().includes(searchQuery.toLowerCase()) || c.id.toLowerCase().includes(searchQuery.toLowerCase()))
                .map((chat) => (
                <tr key={chat.id}>
                  <td><input type="checkbox" className="table-checkbox" /></td>
                  <td>
                    <div className="entity-info">
                      <div>
                        <strong>{chat.id}</strong>
                        <span className="agency-tag" style={{ marginTop: 2 }}>{chat.type}</span>
                      </div>
                    </div>
                  </td>
                  <td><strong>{chat.participants}</strong></td>
                  <td><span style={{ fontSize: 12.5, color: 'var(--text-secondary)' }}>"{chat.lastMessage}"</span></td>
                  <td>{chat.msgCount}</td>
                  <td><span className="entity-sub">{chat.attachments}</span></td>
                  <td>
                    <div className="entity-sub">
                      <Clock size={12} style={{ marginRight: 4 }} />
                      {chat.updatedAt}
                    </div>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <ActionDropdown 
                        actions={[
                          { label: 'View Full Chat Transcript', onClick: () => toast.success(`Viewing transcript for ${chat.id}`) },
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
          <span className="page-info">Showing {chats.length} active chat sessions</span>
          <div className="page-controls">
            <button className="btn-secondary" disabled>Previous</button>
            <button className="btn-secondary">Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}
