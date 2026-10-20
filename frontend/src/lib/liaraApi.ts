// Liara (Iran Cloud) API & Proxy Integration Client
// Provides connectivity to Iranian endpoints (SMS OTP, Iranian storage, backup sync)

export interface LiaraConfig {
  endpoint: string;
  apiKey?: string;
  isCustomServer: boolean;
}

const DEFAULT_LIARA_ENDPOINT = import.meta.env.VITE_LIARA_API_URL || 'https://api.hampa-study.liara.run';

class LiaraClient {
  private endpoint: string;

  constructor() {
    this.endpoint = DEFAULT_LIARA_ENDPOINT;
  }

  public setEndpoint(url: string) {
    this.endpoint = url;
  }

  public async checkHealth(): Promise<boolean> {
    try {
      const res = await fetch(`${this.endpoint}/health`, { method: 'GET' });
      return res.ok;
    } catch {
      return false;
    }
  }

  public async syncBackup(payload: Record<string, unknown>): Promise<boolean> {
    try {
      const res = await fetch(`${this.endpoint}/api/v1/sync/backup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      return res.ok;
    } catch {
      return false;
    }
  }
}

export const liaraClient = new LiaraClient();
