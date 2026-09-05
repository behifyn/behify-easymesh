<div dir="rtl">

# Behify EasyMesh

Behify EasyMesh ابزاری source-available برای مدیریت شبکه EasyTier و رله اختیاری و ایزوله Dokodemo-Door روی لینوکس است. نسخه `1.0.0` نسخه پایدار فعلی است، از EasyTier `v2.6.4` استفاده می‌کند و معماری‌های `x86_64` و `aarch64` را پشتیبانی می‌کند.

## ارتباط با پروژه اصلی و مجوز

این پروژه بر پایه [Easy-Mesh نوشته Musixal](https://github.com/Musixal/Easy-Mesh) ساخته شده است. فایل‌های `LICENSE` و `NOTICE` بدون تغییر حفظ شده‌اند. [EasyTier](https://github.com/EasyTier/EasyTier) و Xray-core رله، پروژه‌های بالادستی جداگانه‌اند؛ جزئیات در [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) آمده است.

مجوز سفارشی این مخزن source-available است و مجوز متن‌باز مورد تایید OSI نیست. طبق همین مجوز، استفاده از نرم‌افزار برای ساخت یا قرار دادن آن در محتوای منتشرشده در YouTube یا هر پلتفرم اشتراک ویدیو ممنوع است. پیش از استفاده یا بازنشر، [LICENSE](LICENSE) را بخوانید.

## پیش‌نیازها

- لینوکس دارای systemd
- معماری `x86_64` / `amd64` یا `aarch64` / `arm64`
- `bash`، OpenSSL، Python 3 و ابزارهای استاندارد GNU
- برای نصب آنلاین: `curl`، گواهی‌های CA و `tar`

نصب‌کننده بسته‌های سیستم‌عامل را خودکار نصب نمی‌کند. `iperf3` فقط برای آزمون دستی سرعت اختیاری است.

## نصب

برای نسخه پایدار، نصب با یک فرمان انجام می‌شود:

</div>

```bash
curl -fsSL https://github.com/behifyn/behify-easymesh/releases/latest/download/install.sh | sudo bash
```

<div dir="rtl">

این نشانی آخرین نسخه پایدار GitHub را هدف می‌گیرد. نصب‌کننده در پایان `Run: sudo easymesh` را نشان می‌دهد و منو را خودکار باز نمی‌کند.

برای نصب و سپس اجرای نسخه پایدار در یک فرمان:

</div>

```bash
curl -fsSL https://github.com/behifyn/behify-easymesh/releases/latest/download/install.sh -o /tmp/behify-install.sh && sudo bash /tmp/behify-install.sh && sudo easymesh
```

<div dir="rtl">

نصب مستقیم نسخه دقیق v1.0.0 نیز با این فرمان ممکن است:

</div>

```bash
curl -fsSL https://github.com/behifyn/behify-easymesh/releases/download/v1.0.0/install.sh | sudo bash
```

<div dir="rtl">

فرمان‌های pipe کوتاه‌اند، اما خود bootstrap را جداگانه بررسی نمی‌کنند. روش پیشنهادی نسخه پایدار، دریافت و بررسی فایل پیش از اجراست:

</div>

```bash
version=v1.0.0
curl -fLO "https://github.com/behifyn/behify-easymesh/releases/download/$version/install.sh"
curl -fLO "https://github.com/behifyn/behify-easymesh/releases/download/$version/SHA256SUMS"
grep ' install.sh$' SHA256SUMS | sha256sum -c -
sudo bash install.sh
```

<div dir="rtl">

فایل نسخه‌دار `online-install-v1.0.0.sh` از نظر بایت با `install.sh` یکسان است. هر دو معماری را تشخیص می‌دهند، بسته ثابت همان معماری را می‌گیرند، SHA-256 و مسیرهای archive را بررسی می‌کنند و سپس نصب‌کننده آفلاین داخل بسته را اجرا می‌کنند.

برای نصب کاملا آفلاین، بسته مناسب و `SHA256SUMS` را به سرور منتقل کنید:

</div>

```bash
grep 'behify-easymesh-v1.0.0-linux-x86_64.tar.gz$' SHA256SUMS | sha256sum -c -
tar -xzf behify-easymesh-v1.0.0-linux-x86_64.tar.gz
cd behify-easymesh-v1.0.0-linux-x86_64
sudo EASYMESH_OFFLINE=1 bash install.sh
```

<div dir="rtl">

روی ARM64 نام `aarch64` را جایگزین کنید. فایل‌های Source code خودکار GitHub نصب‌کننده آفلاین نیستند.

## استفاده

</div>

```bash
sudo easymesh
easymesh --version
```

<div dir="rtl">

باز کردن منو هیچ دانلود یا جایگزینی EasyTier انجام نمی‌دهد. گزینه **Connect to the Mesh Network** تنظیمات mesh را ایجاد یا جایگزین می‌کند. تنظیمات پیش‌فرض عمومی شامل رمزنگاری فعال، multi-thread غیرفعال و IPv6 فعال مطابق رفتار قبلی است. secret تصادفی ۳۲ نویسه‌ای یک بار و به‌شکل برجسته در ترمینال تعاملی نمایش داده می‌شود؛ Enter همان مقدار را می‌پذیرد، یا می‌توان secret سفارشی را به‌صورت قابل مشاهده تایپ و پیش از Enter اصلاح کرد. برنامه مقدار سفارشی را پس از ورود دوباره چاپ نمی‌کند.

فایل‌های `/etc/behify-easymesh/mesh.env` و `/etc/behify-easymesh/easytier.toml` فقط برای root و با سطح دسترسی `0600` هستند. سرویس مدیریت‌شده secret را از config خصوصی می‌خواند، آن را وارد آرگومان process نمی‌کند و برای جلوگیری از ثبت effective config در سطح INFO، گزارش کنسول را روی WARN می‌گذارد. گزینه ۵ منو فقط با درخواست مستقیم کاربر secret ذخیره‌شده را نشان می‌دهد.

برای جزئیات به [تنظیمات](docs/configuration.md) و [عملیات و نگهداری](docs/operations.md) مراجعه کنید.

## نکات اتصال

می‌توان آدرس سرور دوم را فقط روی یک node وارد کرد و در node شنونده یا reverse، فیلد peer را خالی گذاشت. اگر اتصال از A به B برقرار نشد، جهت B به A را امتحان کنید و دسترسی UDP، فایروال سیستم، فایروال ارائه‌دهنده، NAT و پروتکل پشتیبانی‌شده دیگری را بررسی کنید. ممکن است پس از شروع اتصال از یک سمت، مسیر مستقیم P2P شکل بگیرد. Behify به صورت خودکار peer معکوس اضافه نمی‌کند و routing خود EasyTier را تغییر نمی‌دهد.

نمایش Peer و Peer-Center از قالب ترمینالی EasyTier استفاده می‌کند. Routes در صورت پشتیبانی `watch` از حالت no-wrap استفاده می‌کند و در غیر این صورت به wrapping عادی برمی‌گردد.

## امنیت

آسیب‌پذیری‌ها را طبق [SECURITY.md](SECURITY.md) به صورت خصوصی گزارش کنید. secret واقعی mesh یا اطلاعات ورود سرور را در گزارش عمومی قرار ندهید.

نسخه منتشرشده RC3 همه مرحله‌های CI شامل validate-and-build، اجرای native روی x86_64 و aarch64، بررسی package، نصب strict-offline و آزمون real-systemd را با موفقیت گذراند. این نسخه همچنین روی دو سرور واقعی x86_64 نصب شد؛ هر دو سرویس active و enabled بودند، مسیر DIRECT/P2P برقرار شد و ping دوطرفه با ۰٪ packet loss موفق بود. نسخه پایدار v1.0.0 همان runtime و رفتار آزموده‌شده را بدون تغییر در شبکه یا سرویس‌ها ارتقا می‌دهد.

</div>
