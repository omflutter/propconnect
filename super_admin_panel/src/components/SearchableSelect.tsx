import React, { useState, useRef, useEffect } from 'react';
import { Search, ChevronDown, Check, Building2, X } from 'lucide-react';
import './SearchableSelect.css';

export interface SelectOption {
  value: string;
  label: string;
  subLabel?: string;
}

export interface SearchableSelectProps {
  options: SelectOption[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  searchPlaceholder?: string;
  icon?: React.ReactNode;
  style?: React.CSSProperties;
}

export const SearchableSelect: React.FC<SearchableSelectProps> = ({
  options,
  value,
  onChange,
  placeholder = 'Select option...',
  searchPlaceholder = 'Search agencies...',
  icon = <Building2 size={16} color="var(--primary-blue)" />,
  style,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const wrapperRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const selectedOption = options.find((opt) => opt.value === value);

  const filteredOptions = options.filter(
    (opt) =>
      opt.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (opt.subLabel && opt.subLabel.toLowerCase().includes(searchTerm.toLowerCase()))
  );

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

  const handleSelect = (optValue: string) => {
    onChange(optValue);
    setIsOpen(false);
    setSearchTerm('');
  };

  return (
    <div className="searchable-select-wrapper" ref={wrapperRef} style={style}>
      <button
        type="button"
        className={`searchable-select-trigger ${isOpen ? 'active' : ''}`}
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className="trigger-left">
          {icon}
          <span className="trigger-label">
            {selectedOption ? selectedOption.label : placeholder}
          </span>
          {selectedOption && selectedOption.subLabel && (
            <span className="trigger-sublabel">({selectedOption.subLabel})</span>
          )}
        </span>
        <ChevronDown size={16} className={`chevron-icon ${isOpen ? 'rotated' : ''}`} />
      </button>

      {isOpen && (
        <div className="searchable-select-popover">
          <div className="popover-search-box">
            <Search size={14} className="popover-search-icon" />
            <input
              ref={inputRef}
              type="text"
              className="popover-search-input"
              placeholder={searchPlaceholder}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            {searchTerm && (
              <button
                type="button"
                className="popover-clear-btn"
                onClick={() => setSearchTerm('')}
              >
                <X size={14} />
              </button>
            )}
          </div>

          <div className="popover-options-list">
            {filteredOptions.length === 0 ? (
              <div className="popover-no-results">No agencies found matching "{searchTerm}"</div>
            ) : (
              filteredOptions.map((opt) => {
                const isSelected = opt.value === value;
                return (
                  <button
                    key={opt.value}
                    type="button"
                    className={`popover-option-item ${isSelected ? 'selected' : ''}`}
                    onClick={() => handleSelect(opt.value)}
                  >
                    <div className="option-text-group">
                      <span className="option-main-label">{opt.label}</span>
                      {opt.subLabel && <span className="option-badge">{opt.subLabel}</span>}
                    </div>
                    {isSelected && <Check size={16} className="check-icon" />}
                  </button>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
};
