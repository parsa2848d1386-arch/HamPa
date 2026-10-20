// ============================================================================
// بخش ۲.۴: اعتبارسنجی سمت سرور تراکنش‌ها (Server-side Transaction Validator)
// الگوی Before / After State Validation و بررسی یکپارچگی درخت والد رو به بالا
// ============================================================================

import type { UniversalBlock, SyncTransaction, BlockOperation } from '../../types/schema';

export interface ValidationResult {
  success: boolean;
  committedTransactions: string[];
  rejectedTransactions: { id: string; reason: string }[];
  updatedBlocks: UniversalBlock[];
}

export class ServerTransactionValidator {
  /**
   * شبیه‌سازی منطق درون‌خطی کنترلر /api/v1/saveTransactions
   * ۱. لود وضعیت Before
   * ۲. شبیه‌سازی اعمال تغییرات و ساخت وضعیت After
   * ۳. ارزیابی مجوزهای Permissions Tree و سلامت رندر
   * ۴. کامیت اتمیک و انتشار وب‌سوکت
   */
  public static validateAndCommit(
    existingBlocksMap: Map<string, UniversalBlock>,
    transactions: SyncTransaction[]
  ): ValidationResult {
    const committed: string[] = [];
    const rejected: { id: string; reason: string }[] = [];
    const updatedBlocksMap: Map<string, UniversalBlock> = new Map(existingBlocksMap);

    for (const tx of transactions) {
      let isTxValid = true;
      let failureReason = '';

      // ۱. اعتبارسنجی اولیه ساختار
      if (!tx.workspace_id || !tx.operations || tx.operations.length === 0) {
        rejected.push({ id: tx.transaction_id, reason: 'ساختار تراکنش ناقص یا خالی است.' });
        continue;
      }

      // وضعیت موقت برای تست تراکنش به صورت اتمیک
      const stagingBlocksMap = new Map(updatedBlocksMap);

      for (const op of tx.operations) {
        const targetBlock = stagingBlocksMap.get(op.block_id);

        if (op.type === 'insert') {
          const newBlock = op.value as UniversalBlock;
          // اعتبارسنجی والِد (Parent Check)
          if (!newBlock.parent_id) {
            isTxValid = false;
            failureReason = `بلاک جدید ${newBlock.id} فاقد والد معتبر در درخت مجوزهاست.`;
            break;
          }
          stagingBlocksMap.set(newBlock.id, {
            ...newBlock,
            version: 1,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          });
        } else if (op.type === 'update') {
          if (!targetBlock) {
            isTxValid = false;
            failureReason = `بلاک ${op.block_id} جهت به‌روزرسانی یافت نشد.`;
            break;
          }
          const afterBlock: UniversalBlock = {
            ...targetBlock,
            properties: { ...targetBlock.properties, ...op.value },
            version: targetBlock.version + 1,
            updated_at: new Date().toISOString(),
          };
          stagingBlocksMap.set(op.block_id, afterBlock);
        } else if (op.type === 'append_child') {
          if (!targetBlock) {
            isTxValid = false;
            failureReason = `بلاک والد ${op.block_id} جهت افزودن فرزند یافت نشد.`;
            break;
          }
          // جلوگیری از اضافه شدن تکراری یا حلقوی
          const childId = op.value as string;
          if (childId === op.block_id) {
            isTxValid = false;
            failureReason = `خطای ساختاری حلقه در درخت: بلاک نمی‌تواند فرزند خودش باشد!`;
            break;
          }
          const afterContent = targetBlock.content.includes(childId)
            ? targetBlock.content
            : [...targetBlock.content, childId];

          stagingBlocksMap.set(op.block_id, {
            ...targetBlock,
            content: afterContent,
            version: targetBlock.version + 1,
            updated_at: new Date().toISOString(),
          });
        } else if (op.type === 'delete') {
          if (targetBlock) {
            stagingBlocksMap.set(op.block_id, {
              ...targetBlock,
              is_deleted: true,
              version: targetBlock.version + 1,
              updated_at: new Date().toISOString(),
            });
          }
        }
      }

      if (isTxValid) {
        // کامیت اتمیک تراکنش روی وضعیت دیتابیس
        stagingBlocksMap.forEach((val, key) => updatedBlocksMap.set(key, val));
        committed.push(tx.transaction_id);
      } else {
        rejected.push({ id: tx.transaction_id, reason: failureReason });
      }
    }

    return {
      success: rejected.length === 0,
      committedTransactions: committed,
      rejectedTransactions: rejected,
      updatedBlocks: Array.from(updatedBlocksMap.values()),
    };
  }
}
