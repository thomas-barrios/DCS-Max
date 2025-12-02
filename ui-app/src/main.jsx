import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

// Hide the loading placeholder once React mounts
const loadingPlaceholder = document.getElementById('loading-placeholder');
if (loadingPlaceholder) {
  loadingPlaceholder.classList.add('hidden');
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
