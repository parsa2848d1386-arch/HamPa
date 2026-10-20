// ============================================================================
// بخش ۲: خط لوله همگام‌سازی محلی-اول (Local-First Transaction Pipeline)
// تضمین SLA تأخیر زیر ۱۰۰ میلی‌ثانیه، اعمال خوش‌بینانه و تاب‌آوری آفلاین
// ============================================================================

import type { UniversalBlock, SyncTransaction, BlockOperation } from '../../types/schema';

type SubscriberCallback = (block: UniversalBlock) => void;

class LocalRecordCache {
  private cache: Map<string, UniversalBlock> = new Map();
  private subscribers: Map<string, Set<SubscriberCallback>> = new Map();

  public get(id: string): UniversalBlock | undefined {
    return this.cache.get(id);
  }

  public set(block: UniversalBlock): void {
    this.cache.set(block.id, block);
    this.notify(block);
  }

  public remove(id: string): void {
    const existing = this.cache.get(id);
    if (existing) {
      existing.is_deleted = true;
      this.cache.set(id, existing);
      this.notify(existing);
    }
  }

  public subscribe(blockId: string, cb: SubscriberCallback): () => void {
    if (!this.subscribers.has(blockId)) {
      this.subscribers.set(blockId, new Set());
    }
    this.subscribers.get(blockId)!.add(cb);
    return () => {
      this.subscribers.get(blockId)?.delete(cb);
    };
  }

  private notify(block: UniversalBlock): void {
    const subs = this.subscribers.get(block.id);
    if (subs) {
      subs.forEach((cb) => cb(block));
    }
  }

  public getAll(): UniversalBlock[] {
    return Array.from(this.cache.values()).filter((b) => !b.is_deleted);
  }

  public seed(blocks: UniversalBlock[]): void {
    blocks.forEach((b) => this.cache.set(b.id, b));
  }
}

export class LocalFirstSyncPipeline {
  private recordCache: LocalRecordCache = new LocalRecordCache();
  private outboxQueue: SyncTransaction[] = [];
  private isSyncing: boolean = false;
  private isOnline: boolean = navigator.onLine;

  constructor() {
    window.addEventListener('online', () => {
      this.isOnline = true;
      this.processOutbox();
    });
    window.addEventListener('offline', () => {
      this.isOnline = false;
    });
  }

  public getCache(): LocalRecordCache {
    return this.recordCache;
  }

  /**
   * گام ۱ و ۲: ایجاد تراکنش اتمیک و اعمال خوش‌بینانه فوری در کلاینت (<50ms)
   */
  public executeTransaction(
    workspaceId: string,
    userId: string,
    operations: BlockOperation[]
  ): SyncTransaction {
    const txId = `tx-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`;
    const transaction: SyncTransaction = {
      transaction_id: txId,
      client_timestamp: Date.now(),
      workspace_id: workspaceId,
      user_id: userId,
      operations,
      status: 'pending',
      retry_count: 0,
    };

    // گام ۲: Optimistic Local Apply (اعمال فوری روی RecordCache محلی)
    for (const op of operations) {
      this.applyOperationLocally(op);
    }

    // گام ۳: ثبت در صف خروجی آفلاین (TransactionQueue)
    this.outboxQueue.push(transaction);
    this.persistOutboxToStorage();

    // تلاش برای ارسال آنی به سرور
    this.processOutbox();

    return transaction;
  }

  /**
   * اعمال خوش‌بینانه تغییرات روی درخت بلاک در حافظه
   */
  private applyOperationLocally(op: BlockOperation): void {
    const existing = this.recordCache.get(op.block_id);

    if (op.type === 'insert' && op.value) {
      this.recordCache.set(op.value as UniversalBlock);
      return;
    }

    if (!existing) return;

    if (op.type === 'update') {
      const updated: UniversalBlock = {
        ...existing,
        properties: { ...existing.properties, ...(op.value || {}) },
        version: existing.version + 1,
        updated_at: new Date().toISOString(),
      };
      this.recordCache.set(updated);
    } else if (op.type === 'append_child' && typeof op.value === 'string') {
      const updated: UniversalBlock = {
        ...existing,
        content: [...existing.content, op.value],
        version: existing.version + 1,
        updated_at: new Date().toISOString(),
      };
      this.recordCache.set(updated);
    } else if (op.type === 'remove_child' && typeof op.value === 'string') {
      const updated: UniversalBlock = {
        ...existing,
        content: existing.content.filter((id) => id !== op.value),
        version: existing.version + 1,
        updated_at: new Date().toISOString(),
      };
      this.recordCache.set(updated);
    } else if (op.type === 'delete') {
      this.recordCache.remove(op.block_id);
    }
  }

  /**
   * گام ۴: ارسال دسته‌ای تراکنش‌ها به اندپوینت سرور (/api/v1/saveTransactions)
   */
  public async processOutbox(): Promise<void> {
    if (this.isSyncing || !this.isOnline || this.outboxQueue.length === 0) return;

    this.isSyncing = true;
    const batch = [...this.outboxQueue];

    try {
      // شبیه‌سازی درخواست شبکه با قابلیت اتصال به سرور واقعی
      const response = await fetch('/api/v1/saveTransactions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transactions: batch }),
      }).catch(() => null);

      if (response && response.ok) {
        // حذف تراکنش‌های ارسال و تأیید شده
        this.outboxQueue = this.outboxQueue.filter(
          (tx) => !batch.some((b) => b.transaction_id === tx.transaction_id)
        );
        this.persistOutboxToStorage();
      } else {
        // افزایش شمارنده تلاش مجدد در صورت خطای شبکه
        batch.forEach((tx) => tx.retry_count++);
      }
    } catch {
      // آفلاین یا خطا
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * گام ۵: دریافت پیام‌های سرور از طریق وب‌سوکت و سینک مقادیر بدون نظرسنجی
   */
  public handleRemoteWebSocketBroadcast(payload: { block: UniversalBlock }): void {
    const local = this.recordCache.get(payload.block.id);
    // حل تضاد ساده بر اساس نسخه و تایم‌استمپ (Last-Write-Wins / Version vector)
    if (!local || payload.block.version >= local.version) {
      this.recordCache.set(payload.block);
    }
  }

  private persistOutboxToStorage(): void {
    try {
      localStorage.setItem('hampa_outbox_queue', JSON.stringify(this.outboxQueue));
    } catch {
      // لاگ یا کنترل حافظه
    }
  }
}

export const syncPipeline = new LocalFirstSyncPipeline();
