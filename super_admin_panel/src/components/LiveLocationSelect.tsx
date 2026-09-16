import React, { useState, useRef, useEffect } from 'react';
import { Search, MapPin, ChevronDown, Check, Loader2, X } from 'lucide-react';
import './SearchableSelect.css';

export interface LiveLocationSelectProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  searchPlaceholder?: string;
  style?: React.CSSProperties;
}

export const LiveLocationSelect: React.FC<LiveLocationSelectProps> = ({
  value,
  onChange,
  placeholder = 'Search & select location...',
  searchPlaceholder = 'Type city, locality, district or PIN code...',
  style,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [apiResults, setApiResults] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const debounceTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Popular Indian cities fallback when search input is empty
  const defaultPopular = [
    'Mumbai (MMR), Maharashtra',
    'Delhi NCR (Delhi, Gurugram, Noida)',
    'Bengaluru, Karnataka',
    'Hyderabad, Telangana',
    'Pune, Maharashtra',
    'Chennai, Tamil Nadu',
    'Kolkata, West Bengal',
    'Ahmedabad, Gujarat',
    'Jaipur, Rajasthan',
    'Surat, Gujarat',
    'Chandigarh Tri-City',
    'Lucknow, Uttar Pradesh',
  ];

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus();
    }
  }, [isOpen]);

  const handleSearchChange = (query: string) => {
    setSearchTerm(query);

    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    if (query.trim().length < 2) {
      setApiResults([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);

    debounceTimerRef.current = setTimeout(async () => {
      try {
        const response = await fetch(
          `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&addressdetails=1&countrycodes=in&limit=10`,
          {
            headers: {
              'User-Agent': 'PropConnectAdminPanel/1.0',
            },
          }
        );

        if (response.ok) {
          const data = await response.json();
          const results = data
            .map((item: any) => item.display_name)
            .filter((name: string) => Boolean(name));
          setApiResults(results);
        }
      } catch (err) {
        console.error('OpenStreetMap API error:', err);
      } finally {
        setIsLoading(false);
      }
    }, 350);
  };

  const handleSelect = (locName: string) => {
    onChange(locName);
    setIsOpen(false);
    setSearchTerm('');
    setApiResults([]);
  };

  const filteredPopular = defaultPopular.filter((loc) =>
    loc.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="searchable-select-wrapper" ref={wrapperRef} style={style}>
      <button
        type="button"
        className={`searchable-select-trigger ${isOpen ? 'active' : ''}`}
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className="trigger-left">
          <MapPin size={16} color="var(--primary-blue)" />
          <span className="trigger-label" style={{ color: value ? 'var(--text-main)' : 'var(--text-muted)' }}>
            {value || placeholder}
          </span>
        </span>
        <ChevronDown size={16} className={`chevron-icon ${isOpen ? 'rotated' : ''}`} />
      </button>

      {isOpen && (
        <div className="searchable-select-popover" style={{ width: '100%', minWidth: 320 }}>
          <div className="popover-search-box">
            <Search size={14} className="popover-search-icon" />
            <input
              ref={inputRef}
              type="text"
              className="popover-search-input"
              placeholder={searchPlaceholder}
              value={searchTerm}
              onChange={(e) => handleSearchChange(e.target.value)}
            />
            {isLoading ? (
              <Loader2 size={14} className="animate-spin" style={{ color: 'var(--primary-blue)', marginRight: 8 }} />
            ) : searchTerm ? (
              <button
                type="button"
                className="popover-clear-btn"
                onClick={() => {
                  setSearchTerm('');
                  setApiResults([]);
                }}
              >
                <X size={14} />
              </button>
            ) : null}
          </div>

          <div className="popover-options-list" style={{ maxHeight: 260, overflowY: 'auto' }}>
            {searchTerm.trim().length >= 2 && apiResults.length > 0 ? (
              <>
                <div style={{ padding: '6px 12px', fontSize: 11, fontWeight: 700, color: 'var(--primary-blue)', textTransform: 'uppercase' }}>
                  Live OpenStreetMap Results
                </div>
                {apiResults.map((loc, idx) => {
                  const isSelected = value === loc;
                  return (
                    <button
                      key={idx}
                      type="button"
                      className={`popover-option-item ${isSelected ? 'selected' : ''}`}
                      onClick={() => handleSelect(loc)}
                    >
                      <div className="option-text-group">
                        <span className="option-main-label" style={{ fontSize: 13, lineHeight: '1.4' }}>{loc}</span>
                      </div>
                      {isSelected && <Check size={16} className="check-icon" />}
                    </button>
                  );
                })}
              </>
            ) : null}

            {searchTerm.trim().length >= 2 && (
              <button
                type="button"
                className="popover-option-item"
                onClick={() => handleSelect(searchTerm.trim())}
                style={{ background: '#f0fdf4', borderTop: '1px solid var(--border)' }}
              >
                <div className="option-text-group">
                  <span className="option-main-label" style={{ color: '#15803d', fontWeight: 600 }}>
                    Use custom location "{searchTerm.trim()}"
                  </span>
                </div>
              </button>
            )}

            {(!searchTerm || (searchTerm.trim().length < 2 && apiResults.length === 0)) && (
              <>
                <div style={{ padding: '6px 12px', fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                  Popular Real Estate Hubs
                </div>
                {filteredPopular.map((loc, idx) => {
                  const isSelected = value === loc;
                  return (
                    <button
                      key={idx}
                      type="button"
                      className={`popover-option-item ${isSelected ? 'selected' : ''}`}
                      onClick={() => handleSelect(loc)}
                    >
                      <div className="option-text-group">
                        <span className="option-main-label">{loc}</span>
                      </div>
                      {isSelected && <Check size={16} className="check-icon" />}
                    </button>
                  );
                })}
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
