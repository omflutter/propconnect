import { useState } from 'react';
import { Search, MessageSquare, Shield, Clock, Eye, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import './GlobalData.css';

export function ChatLogs() {
  const [searchQuery, setSearchQuery] = useState('');

  const [chats] = useState([
    {
      id: 'CHAT-101',
      type: 'Deal Chat (DL-501)',
      participants: 'Om Shivam (Sunrise) <-> Rajesh Kumar (Metro)',
      lastMessage: 'Site visit confirmed for 4:00 PM today with buyer.',
      msgCount: '48 Messages',
      attachments: '2 PDF Floorplans',
      updatedAt: '2026-08-01 12:40'
    },
    {
      id: 'CHAT-102',
      type: '1-to-1 Direct Chat',
      participants: 'Priya Sharma (Bangalore) <-> Amit Patel (Apex)',
      lastMessage: 'Can you send seller negotiable price quote?',
      msgCount: '19 Messages',
      attachments: 'None',
      updatedAt: '2026-08-01 11:22'
    },
    {
      id: 'CHAT-103',
      type: 'Property Chat (PR-106)',
      participants: 'Om Shivam (Sunrise) <-> Priya Sharma (Bangalore)',
      lastMessage: 'Is the title deed verification clear from RERA?',
      msgCount: '32 Messages',
      attachments: '1 Title Certificate',
      updatedAt: '2026-07-31 16:05'
    }
  ]);

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
