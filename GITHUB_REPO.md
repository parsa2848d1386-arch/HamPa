# مخزن گیتهاب رسمی پروژه هم‌پای من (HamPA)

آدرس مخزن رسمی گیتهاب:
**https://github.com/parsa2848d1386-arch/HamPa**

### راهنمای هوش‌های مصنوعی کدنویس (AI Coders)
هر زمان که کاربر دستور ارسال فایل‌ها یا تغییرات به گیتهاب را داد، بدون نیاز به پرسش مجدد مراحل زیر را اجرا کنید:

```bash
# ۱. بررسی اتصال ریموت origin
git remote -v

# در صورتی که origin ست نشده بود:
git remote add origin https://github.com/parsa2848d1386-arch/HamPa.git

# ۲. افزودن فایل‌ها و ساخت کامیت
git add .
git commit -m "بروزرسانی فایل‌های پروژه هم‌پا (HamPA)"

# ۳. تنظیم شاخه اصلی به main و ارسال به گیتهاب
git branch -M main
git push -u origin main
```

همچنین می‌توانید اسکریپت آماده `push_to_github.bat` در ریشه پروژه را اجرا فرمایید:
```cmd
push_to_github.bat "پیام کامیت دلخواه"
```
