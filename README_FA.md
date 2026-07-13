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

## انتخاب امن هسته بر اساس معماری

بسته محلی هسته بر اساس معماری شناسایی‌شده سیستم انتخاب می‌شود:

- `x86_64` یا `amd64`: `easytier-linux-x86_64`
- `aarch64` یا `arm64`: `easytier-linux-aarch64`

پشتیبانی موجود ARMv7 در صورت وجود باینری محلی متناظر حفظ شده است. معماری ناشناخته با خطای امن متوقف می‌شود و هرگز به بسته x86_64 هدایت نمی‌شود.

اگر نسخه دیگری نصب باشد، اجرای `sudo easymesh 2.6.4` ارتقای فقط هسته را پیشنهاد می‌دهد. پیش از توقف سرویس، هر دو باینری کاندیدا در فایل‌های موقت کپی و برای تطبیق معماری و نسخه اجرا می‌شوند. پس از تأیید، اسکریپت فقط `easytier-core` و `easytier-cli` را پشتیبان‌گیری و جایگزین می‌کند؛ فایل موجود `easymesh.service`، مقدار `ExecStart` و تنظیمات شبکه بدون تغییر می‌مانند. در صورت شکست نصب یا راه‌اندازی سرویس، نسخه پشتیبان به‌صورت خودکار بازیابی می‌شود.

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

بسته‌های محلی `v2.6.4` برای x86_64 و aarch64 در مسیر زیر قرار دارند:

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
