import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Transaction {
  id: number;
  amount: number;
  timestamp: string;
  description: string;
  is_anomaly: boolean;
}

export interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  extra?: any;
}

export interface LogResponse {
  hits: LogEntry[];
  total: number;
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private baseUrl = 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  listTransactions(limit: number = 100): Observable<Transaction[]> {
    return this.http.get<Transaction[]>(`${this.baseUrl}/transactions?limit=${limit}`);
  }

  getLogs(limit: number = 100): Observable<LogResponse> {
    return this.http.get<LogResponse>(`${this.baseUrl}/logs?limit=${limit}`);
  }
}
