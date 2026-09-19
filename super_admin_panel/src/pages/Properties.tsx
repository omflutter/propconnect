import { useState, useEffect } from 'react';
import { Search, Filter, MoreVertical, Building2, MapPin, Trash2, X, Loader2, ImagePlus, Upload, Eye } from 'lucide-react';
import toast from 'react-hot-toast';
import { ActionDropdown } from '../components/ActionDropdown';
import { apiFetch } from '../services/api';
import './GlobalData.css';

export function Properties() {
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('All');
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [properties, setProperties] = useState<any[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  // New Property Form State
  const [newProp, setNewProp] = useState({
    title: '',
    location: '',
    price: '',
    bhk: '2 BHK',
    type: 'Sale',
    propertyType: 'Apartment',
    areaSqft: '1200',
    status: 'Available',
    description: '',
  });
  const [uploadedPhotos, setUploadedPhotos] = useState<string[]>([]);
  const [selectedPropertyForView, setSelectedPropertyForView] = useState<any | null>(null);
  const [selectedPropertyForEdit, setSelectedPropertyForEdit] = useState<any | null>(null);
  const [isSavingEdit, setIsSavingEdit] = useState(false);

  const loadProperties = async () => {
    setIsLoading(true);
    try {
      const res = await apiFetch<any[]>('/properties');
      if (res.success && Array.isArray(res.data)) {
        setProperties(res.data.map(p => ({
          id: p.propertyCode || `PR-${p.id}`,
          rawId: p.id,
          title: p.title || 'Residential Property',
          location: p.location || 'Mumbai, Maharashtra',
          price: p.priceFormatted || (typeof p.price === 'number' ? `₹${(p.price / 10000000).toFixed(2)} Cr` : (p.price || '₹1.00 Cr')),
          agency: p.agencyName || 'Sunrise Properties',
          type: p.listingType || p.type || 'Sale',
          status: p.status || 'Available',
          images: Array.isArray(p.images) ? p.images : [],
          firstImage: Array.isArray(p.images) && p.images.length > 0 ? p.images[0] : null,
          raw: p,
        })));
      }
    } catch (_) {}
    setIsLoading(false);
  };

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setIsUploading(true);
    const newUploaded: string[] = [];

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      try {
        const reader = new FileReader();
        const b64Promise = new Promise<string>((resolve, reject) => {
          reader.onload = () => resolve(reader.result as string);
          reader.onerror = reject;
          reader.readAsDataURL(file);
        });
        const b64 = await b64Promise;
        const res = await apiFetch('/upload/base64', {
          method: 'POST',
          body: JSON.stringify({ image: b64, filename: file.name }),
        });
        if (res.success && res.data?.url) {
          newUploaded.push(res.data.url);
        }
      } catch (err) {
        console.error('Image upload failed:', err);
      }
    }

    setIsUploading(false);
    if (newUploaded.length > 0) {
      setUploadedPhotos(prev => [...prev, ...newUploaded]);
      toast.success(`${newUploaded.length} real photo(s) uploaded successfully!`);
    } else {
      toast.error('Failed to upload photos.');
    }
  };

  const handleRemovePhoto = (index: number) => {
    setUploadedPhotos(prev => prev.filter((_, idx) => idx !== index));
  };

  const handleCreateProperty = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newProp.title.trim() || !newProp.location.trim() || !newProp.price.trim()) {
      toast.error('Please provide Title, Location, and Price.');
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await apiFetch('/properties', {
        method: 'POST',
        body: JSON.stringify({
          ...newProp,
          images: uploadedPhotos,
          areaSqft: parseFloat(newProp.areaSqft) || 1000,
        }),
      });

      if (res.success) {
        toast.success('Property listing created with real uploaded photos!');
        setShowAddModal(false);
        setNewProp({
          title: '',
          location: '',
          price: '',
          bhk: '2 BHK',
          type: 'Sale',
          propertyType: 'Apartment',
          areaSqft: '1200',
          status: 'Available',
          description: '',
        });
        setUploadedPhotos([]);
        loadProperties();
      } else {
        toast.error(res.message || 'Failed to create property.');
      }
    } catch (err: any) {
      toast.error(err.message || 'Error creating property listing.');
    }
    setIsSubmitting(false);
  };

  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPropertyForEdit) return;

    setIsSavingEdit(true);
    try {
      const res = await apiFetch(`/properties/${selectedPropertyForEdit.rawId || selectedPropertyForEdit.id}`, {
        method: 'PUT',
        body: JSON.stringify({
          status: selectedPropertyForEdit.status,
          price: selectedPropertyForEdit.price,
          type: selectedPropertyForEdit.type,
          isPublic: selectedPropertyForEdit.isPublic,
        }),
      });

      if (res.success) {
        toast.success('Property listing updated successfully!');
        setSelectedPropertyForEdit(null);
        loadProperties();
      } else {
        toast.error(res.message || 'Failed to update property');
      }
    } catch (_) {
      toast.error('Network error updating property');
    } finally {
      setIsSavingEdit(false);
    }
  };

  useEffect(() => {
    loadProperties();
  }, []);

  const handleDelete = async (id: string) => {
    const target = properties.find(p => p.id === id);
    setProperties(properties.filter(p => p.id !== id));

    if (target?.rawId) {
      try {
        await apiFetch(`/properties/${target.rawId}`, { method: 'DELETE' });
      } catch (_) {}
    }
    toast.success(`Property ${id} removed globally.`);
  };

  return (
    <div className="global-page">
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20 }}>Global Inventory</h1>
          <p style={{ fontSize: 13, marginTop: 4 }}>Monitor all public and private property listings across the platform.</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary">Export Data</button>
          <button className="btn-primary" onClick={() => setShowAddModal(true)}>+ Add Global Property</button>
        </div>
      </div>

      <div className="card table-container">
        <div className="table-actions" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <div className="segmented-tabs">
            <button className={statusFilter === 'All' ? 'active' : ''} onClick={() => setStatusFilter('All')}>All Properties</button>
            <button className={statusFilter === 'Available' ? 'active' : ''} onClick={() => setStatusFilter('Available')}>Available</button>
            <button className={statusFilter === 'Under Offer' ? 'active' : ''} onClick={() => setStatusFilter('Under Offer')}>Under Offer</button>
            <button className={statusFilter === 'Sold' ? 'active' : ''} onClick={() => setStatusFilter('Sold')}>Sold</button>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="search-box">
              <Search className="search-icon" size={16} />
              <input 
                type="text" 
                placeholder="Search properties..." 
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
                <th>Property</th>
                <th>Agency</th>
                <th>Type</th>
                <th>Price</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '40px' }}>
                    <Loader2 size={24} className="spin" style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: 8, color: 'var(--primary-blue)' }} />
                    Loading global inventory from PostgreSQL...
                  </td>
                </tr>
              ) : properties.filter(p => p.title.toLowerCase().includes(searchQuery.toLowerCase()) || p.location.toLowerCase().includes(searchQuery.toLowerCase())).length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-secondary)' }}>
                    No properties found in global inventory.
                  </td>
                </tr>
              ) : (
                properties
                  .filter(p => p.title.toLowerCase().includes(searchQuery.toLowerCase()) || p.location.toLowerCase().includes(searchQuery.toLowerCase()))
                  .filter(p => statusFilter === 'All' ? true : p.status === statusFilter)
                  .map((prop) => (
                  <tr key={prop.id}>
                    <td><input type="checkbox" className="table-checkbox" /></td>
                    <td>
                      <div className="entity-info">
                        <div className="entity-avatar" style={{ width: 44, height: 44, borderRadius: 8, overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f1f5f9', border: '1px solid var(--border)' }}>
                          {prop.firstImage ? (
                            <img src={prop.firstImage} alt={prop.title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          ) : (
                            <Building2 size={20} color="var(--primary-blue)" />
                          )}
                        </div>
                        <div>
                          <strong>{prop.title}</strong>
                          <span className="entity-sub">
                            <MapPin size={12} style={{ display: 'inline', marginRight: 4 }} />
                            {prop.location}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className="agency-tag">{prop.agency}</span>
                    </td>
                    <td>{prop.type}</td>
                    <td><strong>{prop.price}</strong></td>
                    <td>
                      <span className={`status-badge ${prop.status.toLowerCase().replace(' ', '-')}`}>
                        {prop.status}
                      </span>
                    </td>
                    <td>
                      <div className="action-buttons">
                        <ActionDropdown 
                          actions={[
                            { label: 'View Property Details', onClick: () => setSelectedPropertyForView(prop) },
                            { label: 'Edit Listing', onClick: () => setSelectedPropertyForEdit({
                              ...prop,
                              status: prop.status || 'Available',
                              price: prop.raw?.price || prop.price,
                              type: prop.type || 'Sale',
                              isPublic: prop.raw?.isPublic ?? true,
                            }) },
                            { label: 'Delete Listing', onClick: () => handleDelete(prop.rawId || prop.id), danger: true },
                          ]}
                        />
                      </div>
                    </td>
                  </tr>
                ))
              )}
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
              <h2>Filter Properties</h2>
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
                  <option value="Available">Available</option>
                  <option value="Under Offer">Under Offer</option>
                  <option value="Sold">Sold</option>
                </select>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-primary" onClick={() => setShowFilterModal(false)}>Apply Filters</button>
            </div>
          </div>
        </div>
      )}

      {showAddModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: 620, maxHeight: '90vh', overflowY: 'auto' }}>
            <div className="modal-header">
              <h2>+ Add Global Property Listing</h2>
              <button className="icon-btn" onClick={() => setShowAddModal(false)}><X size={20} /></button>
            </div>
            <form onSubmit={handleCreateProperty}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div className="form-group">
                  <label>Property Title *</label>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="e.g. Sea Face Luxury Penthouse"
                    required
                    value={newProp.title}
                    onChange={(e) => setNewProp({ ...newProp, title: e.target.value })}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div className="form-group">
                    <label>Location / City *</label>
                    <input
                      type="text"
                      className="form-input"
                      placeholder="e.g. Bandra West, Mumbai"
                      required
                      value={newProp.location}
                      onChange={(e) => setNewProp({ ...newProp, location: e.target.value })}
                    />
                  </div>
                  <div className="form-group">
                    <label>Price *</label>
                    <input
                      type="text"
                      className="form-input"
                      placeholder="e.g. ₹4.50 Cr"
                      required
                      value={newProp.price}
                      onChange={(e) => setNewProp({ ...newProp, price: e.target.value })}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
                  <div className="form-group">
                    <label>BHK</label>
                    <select
                      className="form-select"
                      value={newProp.bhk}
                      onChange={(e) => setNewProp({ ...newProp, bhk: e.target.value })}
                    >
                      <option value="1 RK">1 RK</option>
                      <option value="1 BHK">1 BHK</option>
                      <option value="2 BHK">2 BHK</option>
                      <option value="3 BHK">3 BHK</option>
                      <option value="4 BHK">4 BHK</option>
                      <option value="5+ BHK">5+ BHK</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Type</label>
                    <select
                      className="form-select"
                      value={newProp.type}
                      onChange={(e) => setNewProp({ ...newProp, type: e.target.value })}
                    >
                      <option value="Sale">Sale</option>
                      <option value="Rent">Rent</option>
                      <option value="Lease">Lease</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Area (Sqft)</label>
                    <input
                      type="number"
                      className="form-input"
                      placeholder="1200"
                      value={newProp.areaSqft}
                      onChange={(e) => setNewProp({ ...newProp, areaSqft: e.target.value })}
                    />
                  </div>
                </div>

                {/* Real Image File Upload Section */}
                <div className="form-group">
                  <label style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span>Property Photos ({uploadedPhotos.length})</span>
                    <span style={{ fontSize: 11.5, color: 'var(--text-secondary)' }}>Upload real image files from your computer</span>
                  </label>

                  <input
                    type="file"
                    id="real-property-files"
                    multiple
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={handlePhotoUpload}
                  />

                  <div
                    style={{
                      border: '2px dashed #cbd5e1',
                      borderRadius: 10,
                      padding: '20px 16px',
                      textAlign: 'center',
                      background: '#f8fafc',
                      cursor: 'pointer',
                      marginTop: 6,
                    }}
                    onClick={() => document.getElementById('real-property-files')?.click()}
                  >
                    {isUploading ? (
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, color: 'var(--primary-blue)' }}>
                        <Loader2 size={20} className="spin" />
                        <span style={{ fontSize: 13, fontWeight: 600 }}>Uploading image files to Hostinger VPS...</span>
                      </div>
                    ) : (
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                        <div style={{ width: 38, height: 38, borderRadius: 8, background: '#e0f2fe', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0284c7' }}>
                          <Upload size={20} />
                        </div>
                        <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>
                          Click to select real property photos
                        </span>
                        <span style={{ fontSize: 11.5, color: 'var(--text-secondary)' }}>
                          PNG, JPG, WEBP supported
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Uploaded Thumbnails Preview */}
                  {uploadedPhotos.length > 0 && (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10, marginTop: 12 }}>
                      {uploadedPhotos.map((imgUrl, idx) => (
                        <div
                          key={idx}
                          style={{
                            position: 'relative',
                            height: 75,
                            borderRadius: 8,
                            overflow: 'hidden',
                            border: '1px solid var(--border)',
                          }}
                        >
                          <img src={imgUrl} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              handleRemovePhoto(idx);
                            }}
                            style={{
                              position: 'absolute',
                              top: 4,
                              right: 4,
                              background: 'rgba(0,0,0,0.65)',
                              color: 'white',
                              border: 'none',
                              borderRadius: '50%',
                              width: 22,
                              height: 22,
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              cursor: 'pointer',
                            }}
                          >
                            ✕
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
                <button type="button" className="btn-secondary" onClick={() => setShowAddModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn-primary" disabled={isSubmitting || isUploading}>
                  {isSubmitting ? (
                    <>
                      <Loader2 size={16} className="spin" /> Creating...
                    </>
                  ) : (
                    `Create Property Listing (${uploadedPhotos.length} Photos)`
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Property Details Modal */}
      {selectedPropertyForView && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: 700, maxHeight: '90vh', overflowY: 'auto' }}>
            <div className="modal-header">
              <div>
                <h2>{selectedPropertyForView.title}</h2>
                <span className="entity-sub" style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
                  Code: <strong>{selectedPropertyForView.id}</strong> • Agency: <strong>{selectedPropertyForView.agency}</strong>
                </span>
              </div>
              <button className="icon-btn" onClick={() => setSelectedPropertyForView(null)}>
                <X size={20} />
              </button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              {/* Image Gallery */}
              {selectedPropertyForView.images && selectedPropertyForView.images.length > 0 ? (
                <div>
                  <label style={{ fontWeight: 600, fontSize: 13, marginBottom: 8, display: 'block' }}>
                    Property Gallery ({selectedPropertyForView.images.length} Photos)
                  </label>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(130px, 1fr))', gap: 10 }}>
                    {selectedPropertyForView.images.map((imgUrl: string, idx: number) => (
                      <a
                        key={idx}
                        href={imgUrl}
                        target="_blank"
                        rel="noreferrer"
                        style={{
                          display: 'block',
                          height: 95,
                          borderRadius: 8,
                          overflow: 'hidden',
                          border: '1px solid var(--border)',
                          position: 'relative',
                        }}
                      >
                        <img src={imgUrl} alt="Property" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        <div style={{
                          position: 'absolute',
                          bottom: 4,
                          right: 4,
                          background: 'rgba(0,0,0,0.6)',
                          color: '#fff',
                          borderRadius: 4,
                          padding: '2px 5px',
                          fontSize: 10,
                          display: 'flex',
                          alignItems: 'center',
                          gap: 3,
                        }}>
                          <Eye size={10} /> View
                        </div>
                      </a>
                    ))}
                  </div>
                </div>
              ) : (
                <div style={{ padding: 16, textAlign: 'center', background: 'var(--bg-secondary)', borderRadius: 8, color: 'var(--text-secondary)', fontSize: 13 }}>
                  No photos uploaded for this property listing.
                </div>
              )}

              {/* Key Specs & Price */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, background: 'var(--bg-secondary)', padding: 14, borderRadius: 8 }}>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Asking Price</div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--primary)' }}>{selectedPropertyForView.price}</div>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Listing Type</div>
                  <div style={{ fontSize: 15, fontWeight: 600 }}>{selectedPropertyForView.type}</div>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Status</div>
                  <div>
                    <span className={`status-badge ${selectedPropertyForView.status.toLowerCase().replace(' ', '-')}`}>
                      {selectedPropertyForView.status}
                    </span>
                  </div>
                </div>
              </div>

              {/* Location & Specs */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div className="form-group">
                  <label>Location</label>
                  <div style={{ padding: '8px 12px', background: 'var(--bg-secondary)', borderRadius: 6, fontSize: 13 }}>
                    <MapPin size={13} style={{ display: 'inline', marginRight: 4, verticalAlign: 'middle' }} />
                    {selectedPropertyForView.location}
                  </div>
                </div>
                <div className="form-group">
                  <label>Built-up Area / Configuration</label>
                  <div style={{ padding: '8px 12px', background: 'var(--bg-secondary)', borderRadius: 6, fontSize: 13 }}>
                    {selectedPropertyForView.raw?.areaSqft ? `${selectedPropertyForView.raw.areaSqft} sq.ft` : '1,200 sq.ft'} • {selectedPropertyForView.raw?.bhk || '2 BHK'}
                  </div>
                </div>
              </div>

              {/* Description */}
              <div className="form-group">
                <label>Description</label>
                <div style={{ padding: '10px 12px', background: 'var(--bg-secondary)', borderRadius: 6, fontSize: 13, minHeight: 60, whiteSpace: 'pre-wrap' }}>
                  {selectedPropertyForView.raw?.description || 'No detailed description provided for this listing.'}
                </div>
              </div>

              {/* Privacy Notice */}
              <div style={{ padding: '10px 14px', background: 'rgba(59, 130, 246, 0.08)', borderRadius: 6, border: '1px solid rgba(59, 130, 246, 0.2)', fontSize: 12, color: 'var(--text-secondary)' }}>
                🔒 <strong>Lead & Owner Privacy (PRD Section 6):</strong> Owner contacts and direct client identifiers are strictly masked across agencies. Only the listing agency has permission to unlock direct communication.
              </div>
            </div>
            <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <button className="btn-secondary" onClick={() => setSelectedPropertyForView(null)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Property Listing Modal */}
      {selectedPropertyForEdit && (
        <div className="modal-overlay" style={{ zIndex: 1100 }}>
          <div className="modal-content" style={{ maxWidth: 520 }}>
            <div className="modal-header">
              <div>
                <h2>Edit Listing</h2>
                <span className="entity-sub" style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
                  {selectedPropertyForEdit.title} ({selectedPropertyForEdit.id})
                </span>
              </div>
              <button className="icon-btn" onClick={() => setSelectedPropertyForEdit(null)}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSaveEdit}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div className="form-group">
                  <label>Listing Status *</label>
                  <select
                    className="form-select"
                    value={selectedPropertyForEdit.status}
                    onChange={(e) => setSelectedPropertyForEdit({ ...selectedPropertyForEdit, status: e.target.value })}
                  >
                    <option value="Available">Available</option>
                    <option value="Under Offer">Under Offer</option>
                    <option value="Sold">Sold</option>
                    <option value="Off-Market">Off-Market</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>Listing Type *</label>
                  <select
                    className="form-select"
                    value={selectedPropertyForEdit.type}
                    onChange={(e) => setSelectedPropertyForEdit({ ...selectedPropertyForEdit, type: e.target.value })}
                  >
                    <option value="Sale">Sale</option>
                    <option value="Rent">Rent</option>
                    <option value="Lease">Lease</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>Price *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={selectedPropertyForEdit.price}
                    onChange={(e) => setSelectedPropertyForEdit({ ...selectedPropertyForEdit, price: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                  <input
                    type="checkbox"
                    id="isPublicCheck"
                    checked={Boolean(selectedPropertyForEdit.isPublic)}
                    onChange={(e) => setSelectedPropertyForEdit({ ...selectedPropertyForEdit, isPublic: e.target.checked })}
                    style={{ width: 16, height: 16, cursor: 'pointer' }}
                  />
                  <label htmlFor="isPublicCheck" style={{ cursor: 'pointer', margin: 0, fontWeight: 500 }}>
                    Publicly Visible on Collaboration Exchange (PRD Section 4.5)
                  </label>
                </div>
              </div>

              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
                <button type="button" className="btn-secondary" onClick={() => setSelectedPropertyForEdit(null)}>
                  Cancel
                </button>
                <button type="submit" className="btn-primary" disabled={isSavingEdit}>
                  {isSavingEdit ? (
                    <>
                      <Loader2 size={16} className="spin" /> Updating...
                    </>
                  ) : (
                    'Save Changes'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
