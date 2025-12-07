import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

export interface LogMessage {
  timestamp: string;
  level: string;
  message: string;
  extra?: any;
}

@Injectable({
  providedIn: 'root'
})
export class WebsocketService {
  private socket: WebSocket | null = null;
  private messageSubject = new Subject<LogMessage>();

  public messages$ = this.messageSubject.asObservable();

  connect(callback?: (message: LogMessage) => void): void {
    this.socket = new WebSocket('ws://localhost:8000/ws/logs');
    
    this.socket.onopen = () => {
      console.log('WebSocket connected');
    };

    this.socket.onmessage = (event) => {
      try {
        const message: LogMessage = JSON.parse(event.data);
        this.messageSubject.next(message);
        if (callback) {
          callback(message);
        }
      } catch (error) {
        console.error('Error parsing WebSocket message:', error);
      }
    };

    this.socket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    this.socket.onclose = () => {
      console.log('WebSocket disconnected');
    };
  }

  disconnect(): void {
    if (this.socket) {
      this.socket.close();
      this.socket = null;
    }
  }

  send(message: string): void {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(message);
    }
  }
}
