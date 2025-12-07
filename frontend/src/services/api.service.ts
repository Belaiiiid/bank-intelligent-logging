import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);
  private base = '/api';

  createTransaction(tx: any) {
    return this.http.post<any>(`${this.base}/transactions`, tx);
  }

  listTransactions(limit = 100) {
    return this.http.get<any[]>(`${this.base}/transactions?limit=${limit}`);
  }

  searchLogs(payload: { q?: string; level?: string; size?: number }) {
    return this.http.post<{ hits: any[] }>(`${this.base}/logs/search`, payload);
  }
}