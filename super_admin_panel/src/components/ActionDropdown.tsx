import { useState, useRef, useEffect } from 'react';
import { MoreVertical } from 'lucide-react';
import './ActionDropdown.css';

interface ActionItem {
  label: string;
  onClick: () => void;
  danger?: boolean;
}

interface ActionDropdownProps {
  actions: ActionItem[];
}

export function ActionDropdown({ actions }: ActionDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-dropdown" ref={dropdownRef}>
      <button className="icon-btn" onClick={() => setIsOpen(!isOpen)} title="More Options">
        <MoreVertical size={18} />
      </button>
      
      {isOpen && (
        <div className="dropdown-menu">
          {actions.map((action, index) => (
            <button 
              key={index} 
              className={`dropdown-item ${action.danger ? 'danger' : ''}`}
              onClick={() => {
                action.onClick();
                setIsOpen(false);
              }}
            >
              {action.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
