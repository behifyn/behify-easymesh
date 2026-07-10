# Behify EasyMesh

نسخه خصوصی و ویرایش‌شده Behify از EasyMesh برای نصب آفلاین روی سرور و استفاده شخصی/داخلی.

## وضعیت پروژه

این مخزن در حال حاضر یک نسخه خصوصی و تغییر داده‌شده بر پایه پروژه اصلی Easy-Mesh است.

تمرکز فعلی:

- استفاده از نسخه ۲ اسکریپت به عنوان نسخه اصلی
- آماده‌سازی نصب آفلاین
- نگه‌داری فایل‌های EasyTier Core داخل خود پروژه
- تغییر برندینگ نمایشی به Behify
- بهبود مرحله‌ای پایداری و نصب

## نصب

بعد از انتقال پروژه به سرور:

```bash
sudo bash install.sh
sudo easymesh
```

استفاده از EasyTier v2.6.4:

```bash
sudo easymesh 2.6.4
sudo easymesh --core v2.6.4
```

حالت آفلاین سخت‌گیرانه:

```bash
sudo EASYMESH_OFFLINE=1 easymesh
sudo EASYMESH_OFFLINE=1 easymesh 2.6.4
```

بررسی نسخه هسته نصب‌شده/در حال اجرا:

```bash
/root/easytier/easytier-core --version
PID=$(systemctl show -p MainPID --value easymesh.service); sudo /proc/$PID/exe --version
```

تست بسته آفلاین:

```bash
unzip behify-easymesh-test.zip
cd behify-easymesh-test
sudo EASYMESH_OFFLINE=1 easymesh
```

بعد از نصب:
```bash
sudo easymesh
```
هسته آفلاین

فایل‌های هسته EasyTier باید داخل مسیر زیر قرار بگیرند:

core/v2.0.3/

نسخه پیش‌فرض انتخاب‌شده هسته `v2.0.3` است و همین نسخه فعلا smoke-test شده است.

پشتیبانی از `v2.6.4` از طریق `EASYMESH_CORE_VERSION` آماده شده است، اما برای استفاده آفلاین سخت‌گیرانه باید فایل‌های باینری متناظر در مسیر زیر اضافه شوند:

core/v2.6.4/

گزینه‌های پیشرفته زیر فقط برای تست پایداری آینده مستند شده‌اند و به صورت پیش‌فرض فعال نیستند:

```text
--enable-kcp-proxy
--enable-quic-proxy
--compression zstd
--multi-thread
```

## Attribution

Based on Easy-Mesh by Musixal. LICENSE and NOTICE retained.
