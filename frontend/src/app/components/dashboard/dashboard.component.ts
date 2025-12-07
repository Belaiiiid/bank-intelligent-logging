import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ApiService, Transaction } from '../../services/api.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  txs: Transaction[] = [];
  kpis = { total: 0, anomalies: 0, volume: 0, avgAmount: 0 };
  currentUser = '';
  isLoading = true;
  selectedTimeframe = '24h';
  timeframes = ['1h', '24h', '7d', '30d'];

  constructor(private api: ApiService, private router: Router) {}

  ngOnInit(): void {
    this.checkAuth();
    this.loadDashboardData();
  }

  checkAuth() {
    const isAuth = localStorage.getItem('isAuthenticated');
    if (!isAuth) {
      this.router.navigate(['/login']);
      return;
    }
    this.currentUser = localStorage.getItem('user') || 'User';
  }

  loadDashboardData() {
    this.isLoading = true;
    this.api.listTransactions(200).subscribe({
      next: (rows: Transaction[]) => {
        this.txs = rows;
        this.calculateKPIs(rows);
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading transactions:', error);
        this.isLoading = false;
      }
    });
  }

  calculateKPIs(transactions: Transaction[]) {
    this.kpis.total = transactions.length;
    this.kpis.anomalies = transactions.filter(t => t.is_anomaly).length;
    this.kpis.volume = transactions.reduce((sum, t) => sum + Number(t.amount || 0), 0);
    this.kpis.avgAmount = this.kpis.total > 0 ? this.kpis.volume / this.kpis.total : 0;
  }

  onTimeframeChange() {
    // In a real app, this would filter data by timeframe
    this.loadDashboardData();
  }

  logout() {
    localStorage.removeItem('isAuthenticated');
    localStorage.removeItem('user');
    this.router.navigate(['/login']);
  }

  refreshData() {
    this.loadDashboardData();
  }
}