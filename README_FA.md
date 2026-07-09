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
```

نصب آنلاین/با fallback:

```bash
sudo easymesh
```

حالت آفلاین سخت‌گیرانه با هسته تست‌شده پیش‌فرض:

```bash
sudo EASYMESH_OFFLINE=1 easymesh
```

حالت آفلاین سخت‌گیرانه با نسخه مشخص هسته:

```bash
sudo EASYMESH_OFFLINE=1 EASYMESH_CORE_VERSION=v2.0.3 easymesh
```

تست هسته جدید در آینده:

```bash
sudo EASYMESH_OFFLINE=1 EASYMESH_CORE_VERSION=v2.6.4 easymesh
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

## Attribution

Based on Easy-Mesh by Musixal. LICENSE and NOTICE retained.
