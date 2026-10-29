@echo off
chcp 65001 >nul
echo ==========================================
echo  ارسال تغییرات پروژه هم‌پا (HamPA) به گیتهاب
echo  https://github.com/parsa2848d1386-arch/HamPa
echo ==========================================

set COMMIT_MSG=%~1
if "%COMMIT_MSG%"=="" set COMMIT_MSG=بروزرسانی فایل‌ها و دیزاین هم‌پا (HamPA)

git config http.sslVerify false

echo [1/3] مرحله‌بندی فایل‌ها...
git add .

echo [2/3] ثبت کامیت با پیام: "%COMMIT_MSG%"...
git commit -m "%COMMIT_MSG%"

echo [3/3] ارسال به مخزن اصلی گیتهاب (شاخه main)...
git branch -M main
git push -u origin main

echo ==========================================
echo عملیات با موفقیت انجام شد!
echo ==========================================
pause
