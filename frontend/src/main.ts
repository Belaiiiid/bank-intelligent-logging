import 'zone.js';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

// Ensure Zone.js is loaded before bootstrapping
if (typeof window !== 'undefined') {
  (window as any).Zone = (window as any).Zone || {};
}

platformBrowserDynamic()
  .bootstrapModule(AppModule)
  .catch(err => {
    console.error('Error starting application:', err);
    document.body.innerHTML = '<h1>Application Error</h1><p>Failed to start Angular application. Check console for details.</p>';
  });