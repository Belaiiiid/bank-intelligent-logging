import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  credentials = {
    username: '',
    password: ''
  };
  isLoading = false;
  errorMessage = '';

  constructor(private router: Router) {}

  onLogin() {
    this.isLoading = true;
    this.errorMessage = '';
    
    // Simulate authentication (replace with real API call)
    setTimeout(() => {
      if (this.credentials.username === 'admin' && this.credentials.password === 'admin') {
        localStorage.setItem('isAuthenticated', 'true');
        localStorage.setItem('user', this.credentials.username);
        this.router.navigate(['/dashboard']);
      } else {
        this.errorMessage = 'Invalid credentials. Try admin/admin';
      }
      this.isLoading = false;
    }, 1000);
  }
}
