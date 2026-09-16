import React from 'react';
import { AlertTriangle, ShieldAlert, CheckCircle2, Loader2, X } from 'lucide-react';
import './ConfirmModal.css';

export interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  message: string;
  type?: 'danger' | 'warning' | 'success';
  confirmText?: string;
  cancelText?: string;
  isLoading?: boolean;
  onConfirm: () => void | Promise<void>;
  onCancel: () => void;
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  title,
  message,
  type = 'warning',
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  isLoading = false,
  onConfirm,
  onCancel,
}) => {
  if (!isOpen) return null;

  return (
    <div className="global-modal-overlay">
      <div className="global-modal-content">
        <button className="global-modal-close" onClick={onCancel} disabled={isLoading}>
          <X size={18} />
        </button>
        <div className="global-confirm-dialog">
          <div className={`global-confirm-icon-wrapper ${type}`}>
            {type === 'danger' && <AlertTriangle size={30} />}
            {type === 'warning' && <ShieldAlert size={30} />}
            {type === 'success' && <CheckCircle2 size={30} />}
          </div>
          <h3 className="global-confirm-title">{title}</h3>
          <p className="global-confirm-message">{message}</p>
          <div className="global-confirm-actions">
            <button
              className="global-btn-secondary"
              onClick={onCancel}
              disabled={isLoading}
            >
              {cancelText}
            </button>
            <button
              className={type === 'danger' ? 'global-btn-danger' : 'global-btn-primary'}
              onClick={onConfirm}
              disabled={isLoading}
            >
              {isLoading ? <Loader2 size={16} className="animate-spin" /> : confirmText}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
