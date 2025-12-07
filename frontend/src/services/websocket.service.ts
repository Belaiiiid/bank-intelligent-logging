import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class WebsocketService {
  private ws?: WebSocket;

  connect(onMessage: (data: any) => void) {
    const proto = location.protocol === 'https:' ? 'wss' : 'ws';
    this.ws = new WebSocket(`${proto}://${location.host}/ws/logs`);
    this.ws.onmessage = (evt) => {
      try { onMessage(JSON.parse(evt.data)); } catch {}
    };
    this.ws.onopen = () => this.ws?.send('ping');
    this.ws.onclose = () => {};
  }

  disconnect() {
    this.ws?.close();
  }
}