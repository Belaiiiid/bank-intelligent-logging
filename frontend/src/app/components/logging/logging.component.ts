import { Component, OnDestroy, OnInit } from '@angular/core';
import { ApiService, LogEntry } from '../../services/api.service';
import { WebsocketService, LogMessage } from '../../services/websocket.service';

@Component({
  selector: 'app-logging',
  templateUrl: './logging.component.html',
  styleUrls: ['./logging.component.css']
})
export class LoggingComponent implements OnInit, OnDestroy {
  logs: LogEntry[] = [];
  filter = { q: '', level: '' };

  constructor(private api: ApiService, private ws: WebsocketService) {}

  ngOnInit(): void {
    this.refresh();
    this.ws.connect((msg: LogMessage) => {
      this.logs = [msg, ...this.logs].slice(0, 200);
    });
  }

  ngOnDestroy(): void {
    this.ws.disconnect();
  }

  refresh() {
    this.api.getLogs(100)
      .subscribe((res: any) => { this.logs = res.hits; });
  }
}