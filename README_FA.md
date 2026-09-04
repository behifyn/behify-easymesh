# Behify EasyMesh

Behify EasyMesh یک ابزار source-available برای مدیریت شبکه EasyTier و رله اختیاری و ایزوله Dokodemo-Door در لینوکس است.

نسخه `1.0.0-rc.1` یک prerelease candidate برای نخستین نسخه پایدار است. تنها EasyTier `v2.6.4` و معماری‌های Linux `x86_64` و `aarch64` پشتیبانی می‌شوند.

## ارتباط با پروژه اصلی و مجوز

این پروژه مستقیما بر پایه [Easy-Mesh نوشته Musixal](https://github.com/Musixal/Easy-Mesh) ساخته شده است. نام نویسنده و پروژه اصلی ذکر شده و فایل‌های `LICENSE` و `NOTICE` بدون تغییر نگه داشته شده‌اند. Behify EasyMesh مستقل نگهداری می‌شود و پروژه رسمی EasyTier نیست.

EasyTier یک مؤلفه بالادستی جداگانه با مجوز LGPL-3.0 است. Xray-core مورد استفاده در رله اختیاری نیز مؤلفه‌ای جداگانه با مجوز MPL-2.0 است. جزئیات در `THIRD_PARTY_NOTICES.md` و پوشه `licenses/` قرار دارد.

مجوز سفارشی این مخزن OSI open-source نیست و استفاده از نرم‌افزار در محتوای منتشرشده در YouTube یا دیگر پلتفرم‌های اشتراک ویدیو را محدود می‌کند. قبل از استفاده یا توزیع، `LICENSE` را بخوانید.

## سیستم‌های پشتیبانی‌شده

- Linux دارای systemd
- `x86_64` / `amd64`
- `aarch64` / `arm64`
- فقط EasyTier `v2.6.4`

ARMv7 و معماری‌های دیگر پیش از هر تغییر نصب با خطای واضح متوقف می‌شوند.

نصب‌کننده بسته به `bash`، `awk`، `grep`، `sha256sum`، `od`، `mktemp` و ابزارهای پایه نیاز دارد. bootstrap آنلاین به `curl` و `tar` و اعتبارسنجی IP در منوی mesh به `python3` نیاز دارد. نصب‌کننده هیچ وابستگی package-manager را خودکار نصب نمی‌کند.

## نصب آنلاین تاییدشده

bootstrap نسخه‌دار و checksum منتشرشده را دریافت و تایید کنید:

```bash
curl -fLO https://github.com/behifyn/behify-easymesh/releases/download/v1.0.0-rc.1/online-install-v1.0.0-rc.1.sh
curl -fLO https://github.com/behifyn/behify-easymesh/releases/download/v1.0.0-rc.1/SHA256SUMS
grep 'online-install-v1.0.0-rc.1.sh$' SHA256SUMS | sha256sum -c -
sudo bash online-install-v1.0.0-rc.1.sh
```

bootstrap معماری را تشخیص می‌دهد، فقط بسته immutable متناظر با Behify `v1.0.0-rc.1` را می‌گیرد، SHA-256 منتشرشده را قبل از extract بررسی می‌کند و سپس نصب‌کننده آفلاین داخل بسته را اجرا می‌کند. روش اصلی نصب `curl | bash` نیست.

## نصب کاملا آفلاین

روی یک سیستم متصل، فایل مناسب و `SHA256SUMS` را از Release بگیرید:

```text
behify-easymesh-v1.0.0-rc.1-linux-x86_64.tar.gz
behify-easymesh-v1.0.0-rc.1-linux-aarch64.tar.gz
```

پس از انتقال به سرور مقصد:

```bash
grep 'behify-easymesh-v1.0.0-rc.1-linux-x86_64.tar.gz$' SHA256SUMS | sha256sum -c -
tar -xzf behify-easymesh-v1.0.0-rc.1-linux-x86_64.tar.gz
cd behify-easymesh-v1.0.0-rc.1-linux-x86_64
sudo EASYMESH_OFFLINE=1 bash install.sh
```

برای ARM64 نام `aarch64` را جایگزین کنید. هر بسته فقط `easytier-core` و `easytier-cli` همان معماری را دارد. نصب‌کننده در حالت آفلاین هیچ دسترسی شبکه‌ای انجام نمی‌دهد و فایل ناقص، تغییرکرده، با نسخه اشتباه یا معماری اشتباه را پیش از تغییر سیستم رد می‌کند.

فایل خودکار Source code در GitHub نصب‌کننده آفلاین نیست. سورس متناظر دقیق EasyTier v2.6.4 جداگانه با نام `easytier-v2.6.4-source.tar.gz` منتشر می‌شود.

## استفاده

```bash
sudo easymesh
easymesh --version
```

خروجی نسخه:

```text
Behify EasyMesh v1.0.0-rc.1
EasyTier v2.6.4
```

باز کردن منو هیچ دانلود، نصب یا جایگزینی EasyTier انجام نمی‌دهد. گزینه **Connect to the Mesh Network** تنظیمات mesh را ایجاد یا جایگزین می‌کند.

EasyTier ابتدا اتصال مستقیم/P2P را تلاش می‌کند. اگر مسیر مستقیم در دسترس نباشد ممکن است از relay یا multi-hop بین peerها استفاده کند؛ بنابراین مسیری مانند `Iran1 -> Iran2 -> destination` می‌تواند به عنوان fallback رخ دهد. نسخه 1.0.0-rc.1 این رفتار تست‌شده را تغییر نمی‌دهد و نقش endpoint-only یا relay اختصاصی تحمیل نمی‌کند.

## مسیرها و سرویس‌ها

| کاربرد | مسیر یا سرویس |
| --- | --- |
| برنامه | `/opt/behify-easymesh` |
| فرمان عمومی | `/usr/local/bin/easymesh` |
| EasyTier | `/root/easytier/easytier-core` و `/root/easytier/easytier-cli` |
| سرویس mesh | `/etc/systemd/system/easymesh.service` |
| تنظیمات محرمانه mesh | `/etc/behify-easymesh/mesh.env` |
| backup تنظیمات | `/etc/behify-easymesh/backups/` |
| backup نصب | `/opt/behify-easymesh-backups/` |
| watchdog | `easymesh-watchdog.service` |

فایل `mesh.env` با دسترسی `0600` ذخیره می‌شود و secret داخل unit عمومی systemd نوشته نمی‌شود. تنظیمات جدید ابتدا stage و validate می‌شوند و در صورت خطا فایل‌ها و وضعیت قبلی سرویس برگردانده می‌شوند.

## Upgrade و Rollback

پیش از upgrade نصب‌های قدیمی‌تر از v1 فقط مسیرهای legacy زیر را بررسی کنید:

```bash
sudo test ! -e /root/easytier/reset.sh || sudo stat /root/easytier/reset.sh
sudo crontab -l 2>/dev/null | grep -F '/root/easytier/reset.sh' || true
```

اگر این script یا cron متناظر وجود داشته باشد، نصب‌کننده RC پیش از هر تغییر متوقف می‌شود. بدون مجوز عملیاتی جداگانه آن‌ها را اجرا یا حذف نکنید؛ upgrade بدون نظارت برای این نصب‌ها پشتیبانی نمی‌شود.

برای upgrade همان بسته Release تاییدشده را نصب کنید. هر runtime غیر از جفت معتبر v2.6.4 به صورت عمومی unsupported در نظر گرفته می‌شود؛ فایل‌های قبلی backup، هر دو binary جدید stage و validate، و سپس با توقف کنترل‌شده سرویس جایگزین می‌شوند.

وضعیت active/enabled قبلی حفظ می‌شود. نصب‌کننده سرویس inactive را start و سرویس disabled را enable نمی‌کند. خطای activation یا اعتبارسنجی سرویس باعث بازگردانی برنامه، هر دو binary، مسیر command و وضعیت قبلی می‌شود.

## حذف معمولی و Purge

حذف معمولی فایل‌های تاییدشده متعلق به Behify را حذف می‌کند اما تنظیمات، unitها، backupها و رله ایزوله را نگه می‌دارد:

```bash
sudo /opt/behify-easymesh/uninstall.sh
```

Purge نیازمند تایپ `PURGE` است و تنظیمات mesh، unitهای متعلق به Behify و backupهای mesh را نیز حذف می‌کند:

```bash
sudo /opt/behify-easymesh/uninstall.sh --purge
```

فایل ناشناس در `/usr/local/bin/easymesh`، unit ناشناس، EasyTier غیرمتعلق، Xray سیستمی، x-ui/3x-ui و Hiddify حذف نمی‌شوند. رله فقط از منوی خودش حذف می‌شود.

## رله ایزوله

گزینه **Relay / Port Routing** یک Xray Dokodemo-Door اختصاصی را مدیریت می‌کند. کاربر به 3x-ui، x-ui، Hiddify Manager یا Xray از پیش نصب‌شده نیاز ندارد.

- runtime: `/opt/behify-easymesh/relay/`
- تعریف رله‌ها: `/etc/behify-easymesh/relay/relays.json`
- config تولیدشده: `/etc/behify-easymesh/relay/config.json`
- سرویس: `behify-relay.service`
- نام process: `behify-relayd`

برای نمونه UDP/443 می‌تواند به `10.144.144.1:443` روی mesh هدایت شود. حالت‌های TCP، UDP و Both پشتیبانی می‌شوند. تعارض port و دسترسی route قبل از activation بررسی و خطای سرویس rollback می‌شود.

این مؤلفه مسیرهای `/etc/xray`، `/usr/local/etc/xray`، سرویس‌های x-ui/3x-ui، Hiddify، `xray.service` یا processهای Xray نامرتبط را کنترل یا تغییر نمی‌دهد.

## بررسی و رفع اشکال

```bash
/root/easytier/easytier-core --version
/root/easytier/easytier-cli --version
PID=$(systemctl show -p MainPID --value easymesh.service)
sudo /proc/$PID/exe --version
systemctl status easymesh.service
journalctl -u easymesh.service -n 100 --no-pager
```

نمایش Peer و Peer-Center از قالب عادی EasyTier استفاده می‌کند. Routes فقط در صورت پشتیبانی `watch` از حالت no-wrap استفاده می‌کند و در غیر این صورت به wrapping عادی برمی‌گردد.

گزارش‌های smoke-test قبل از v1 برای سابقه در `docs/historical/` قرار دارند و دستور نصب پشتیبانی‌شده نیستند.

برای گزارش خصوصی آسیب‌پذیری، `SECURITY.md` را ببینید و secret یا credential واقعی را در issue عمومی قرار ندهید.
