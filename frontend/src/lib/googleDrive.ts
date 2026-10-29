// Google Drive Backup & Sync Client for HamPA (هم‌پا)
// Enables persistent cloud backups directly to the user's personal Google Drive

export interface GoogleDriveBackupData {
  version: string;
  timestamp: string;
  appName: string;
  user: unknown;
  tasks: unknown[];
  subjects: unknown[];
  sessions: unknown[];
}

export interface GoogleDriveStatus {
  isConnected: boolean;
  userEmail?: string;
  lastBackupTime?: string;
  backupFileId?: string;
}

const DRIVE_UPLOAD_URL = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';
const DRIVE_API_URL = 'https://www.googleapis.com/drive/v3/files';
const BACKUP_FILE_NAME = 'hampa-workspace-backup.json';
const BACKUP_FOLDER_NAME = 'HamPA Workspaces & Backups';

class GoogleDriveService {
  private accessToken: string | null = null;
  private userEmail: string | null = null;

  constructor() {
    // Check if token exists in session storage
    if (typeof window !== 'undefined') {
      this.accessToken = sessionStorage.getItem('hampa_gdrive_token');
      this.userEmail = sessionStorage.getItem('hampa_gdrive_email');
    }
  }

  public setAccessToken(token: string, email?: string) {
    this.accessToken = token;
    if (typeof window !== 'undefined') {
      sessionStorage.setItem('hampa_gdrive_token', token);
      if (email) {
        this.userEmail = email;
        sessionStorage.setItem('hampa_gdrive_email', email);
      }
    }
  }

  public getAccessToken(): string | null {
    return this.accessToken;
  }

  public isConnected(): boolean {
    return Boolean(this.accessToken);
  }

  public getStatus(): GoogleDriveStatus {
    const lastBackup = typeof window !== 'undefined' ? localStorage.getItem('hampa_last_gdrive_backup') : null;
    const backupFileId = typeof window !== 'undefined' ? localStorage.getItem('hampa_gdrive_file_id') : null;
    return {
      isConnected: this.isConnected(),
      userEmail: this.userEmail || undefined,
      lastBackupTime: lastBackup || undefined,
      backupFileId: backupFileId || undefined,
    };
  }

  public disconnect() {
    this.accessToken = null;
    this.userEmail = null;
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem('hampa_gdrive_token');
      sessionStorage.removeItem('hampa_gdrive_email');
    }
  }

  /**
   * Finds or creates the dedicated HamPA folder in Google Drive
   */
  private async getOrCreateFolder(): Promise<string> {
    if (!this.accessToken) throw new Error('Google Drive not authenticated');

    // 1. Search for existing folder
    const query = encodeURIComponent(`name = '${BACKUP_FOLDER_NAME}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false`);
    const searchRes = await fetch(`${DRIVE_API_URL}?q=${query}&fields=files(id,name)`, {
      headers: { Authorization: `Bearer ${this.accessToken}` }
    });

    if (searchRes.ok) {
      const data = await searchRes.json();
      if (data.files && data.files.length > 0) {
        return data.files[0].id;
      }
    }

    // 2. Create folder if not found
    const createRes = await fetch(DRIVE_API_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: BACKUP_FOLDER_NAME,
        mimeType: 'application/vnd.google-apps.folder',
      })
    });

    if (!createRes.ok) {
      throw new Error('Failed to create backup folder in Google Drive');
    }

    const folder = await createRes.json();
    return folder.id;
  }

  /**
   * Uploads workspace data to Google Drive
   */
  public async uploadBackup(data: GoogleDriveBackupData): Promise<{ success: boolean; fileId?: string; error?: string }> {
    try {
      if (!this.accessToken) {
        return { success: false, error: 'ابتدا به حساب گوگل درایو متصل شوید.' };
      }

      const folderId = await this.getOrCreateFolder();

      // Check if backup file already exists in folder
      const query = encodeURIComponent(`name = '${BACKUP_FILE_NAME}' and '${folderId}' in parents and trashed = false`);
      const searchRes = await fetch(`${DRIVE_API_URL}?q=${query}&fields=files(id,name)`, {
        headers: { Authorization: `Bearer ${this.accessToken}` }
      });

      let existingFileId: string | null = null;
      if (searchRes.ok) {
        const searchData = await searchRes.json();
        if (searchData.files && searchData.files.length > 0) {
          existingFileId = searchData.files[0].id;
        }
      }

      const fileContent = JSON.stringify(data, null, 2);
      const metadata = {
        name: BACKUP_FILE_NAME,
        mimeType: 'application/json',
        parents: existingFileId ? undefined : [folderId]
      };

      const boundary = '-------314159265358979323846';
      const delimiter = `\r\n--${boundary}\r\n`;
      const closeDelim = `\r\n--${boundary}--`;

      const multipartRequestBody =
        delimiter +
        'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
        JSON.stringify(metadata) +
        delimiter +
        'Content-Type: application/json\r\n\r\n' +
        fileContent +
        closeDelim;

      let uploadRes: Response;
      if (existingFileId) {
        // Update existing file
        uploadRes = await fetch(`https://www.googleapis.com/upload/drive/v3/files/${existingFileId}?uploadType=multipart`, {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            'Content-Type': `multipart/related; boundary=${boundary}`,
          },
          body: multipartRequestBody
        });
      } else {
        // Create new file
        uploadRes = await fetch(DRIVE_UPLOAD_URL, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            'Content-Type': `multipart/related; boundary=${boundary}`,
          },
          body: multipartRequestBody
        });
      }

      if (!uploadRes.ok) {
        const errJson = await uploadRes.json().catch(() => ({}));
        throw new Error(errJson.error?.message || `Google Drive upload error (${uploadRes.status})`);
      }

      const result = await uploadRes.json();
      const nowIso = new Date().toISOString();
      if (typeof window !== 'undefined') {
        localStorage.setItem('hampa_last_gdrive_backup', nowIso);
        localStorage.setItem('hampa_gdrive_file_id', result.id);
      }

      return { success: true, fileId: result.id };
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      return { success: false, error: msg };
    }
  }

  /**
   * Downloads and restores the latest workspace backup from Google Drive
   */
  public async downloadLatestBackup(): Promise<{ success: boolean; data?: GoogleDriveBackupData; error?: string }> {
    try {
      if (!this.accessToken) {
        return { success: false, error: 'ابتدا به گوگل درایو متصل شوید.' };
      }

      const folderId = await this.getOrCreateFolder();
      const query = encodeURIComponent(`name = '${BACKUP_FILE_NAME}' and '${folderId}' in parents and trashed = false`);
      const searchRes = await fetch(`${DRIVE_API_URL}?q=${query}&fields=files(id,name,modifiedTime)`, {
        headers: { Authorization: `Bearer ${this.accessToken}` }
      });

      if (!searchRes.ok) {
        throw new Error('خطا در جستجوی فایل در گوگل درایو');
      }

      const searchData = await searchRes.json();
      if (!searchData.files || searchData.files.length === 0) {
        return { success: false, error: 'هیچ فایل پشتیبانی از هم‌پا در گوگل درایو شما یافت نشد.' };
      }

      const fileId = searchData.files[0].id;
      const downloadRes = await fetch(`${DRIVE_API_URL}/${fileId}?alt=media`, {
        headers: { Authorization: `Bearer ${this.accessToken}` }
      });

      if (!downloadRes.ok) {
        throw new Error('خطا در دریافت محتوای فایل پشتیبان');
      }

      const backupData = await downloadRes.json() as GoogleDriveBackupData;
      return { success: true, data: backupData };
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      return { success: false, error: msg };
    }
  }
}

export const googleDriveService = new GoogleDriveService();
