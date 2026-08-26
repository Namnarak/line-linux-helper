# LINE Linux Helper — คู่มือภาษาไทย

โปรเจกต์นี้เป็น **community helper แบบไม่เป็นทางการ** สำหรับช่วยติดตั้ง LINE Desktop รุ่น Windows บน Linux ผ่าน Wine

> **สำคัญ:** นี่ **ไม่ใช่ LINE Installer อย่างเป็นทางการ** และไม่มีความเกี่ยวข้อง/รับรองโดย LY Corporation หรือ LINE
>
> Repo นี้ **ไม่มีการ bundle ไฟล์ LINE**, ไม่ mirror, ไม่แจก EXE/DLL ของ LINE, ไม่ decode, ไม่ decompile, ไม่ reverse-engineer และไม่ patch ตัว `LINE.exe`
>
> ตอนติดตั้ง helper จะดาวน์โหลด Windows bootstrap installer จาก **CDN ทางการของ LINE (`desktop.line-scdn.net`) โดยตรง** แล้วให้ installer ของ LINE จัดการตัวแอปเอง

## ติดตั้ง — คำสั่งเดียว

เปิด Terminal ใน Desktop session แล้วรันแค่นี้:

```bash
curl -fsSL https://raw.githubusercontent.com/Namnarak/line-linux-helper/main/bootstrap.sh | bash
```

ตัว helper จะจัดการให้อัตโนมัติเท่าที่ distro รองรับ:

1. ตรวจ distro และ architecture
2. ติดตั้ง dependency ที่จำเป็น
3. ดาวน์โหลดและตรวจ SHA-256 ของ Wine runner
4. สร้าง Wine prefix แยกสำหรับ LINE
5. ตั้งค่าฟอนต์และ compatibility signature
6. ดาวน์โหลด LINE จาก CDN ทางการของ LINE
7. ติดตั้ง desktop launcher
8. รัน health check
9. เปิด LINE ให้อัตโนมัติ

ถ้าต้องการติดตั้งอย่างเดียวแต่ยังไม่เปิด LINE:

```bash
curl -fsSL https://raw.githubusercontent.com/Namnarak/line-linux-helper/main/bootstrap.sh | bash -s -- --no-launch
```

หรือถ้าต้องการ clone source มาตรวจก่อน:

```bash
git clone https://github.com/Namnarak/line-linux-helper.git
cd line-linux-helper
./install.sh
```

หลังติดตั้งยังใช้คำสั่งเหล่านี้ได้ตามปกติ:

```bash
line-linux launch
line-linux doctor
line-linux repair
line-linux update
```

## มันแก้อะไร?

LINE Desktop รุ่นใหม่บางรุ่นตรวจ signature ของ system DLL แล้ว Wine อาจโดน:

```text
File: C:\windows\system32\CRYPT32.dll
Reason: NO_SIGNATURE
```

helper จะสร้าง Wine prefix แยกสำหรับ LINE โดยเฉพาะ แล้วใส่ Authenticode self-signature ให้ DLL ของ Wineภายใน prefix นั้น

Certificate ที่สร้างขึ้น **เป็น self-signed certificate ที่เครื่องผู้ใช้สร้างเอง ไม่ได้ออกโดย Microsoft** ถึงแม้ metadata ของ certificate จะตั้งให้เข้ากับ workaround ปัจจุบันก็ตาม

## รองรับค่ายไหน?

มี auto dependency path สำหรับ:

- Arch Linux / CachyOS / Manjaro / EndeavourOS
- Debian / Ubuntu / Linux Mint / Pop!_OS
- Fedora / Nobara
- openSUSE Tumbleweed / Leap

Distro อื่นสามารถใช้ได้ถ้ามี dependency ครบ แล้วรัน:

```bash
./install.sh --no-packages
```

ระบบ immutable/OSTree จะไม่ถูกสคริปต์แก้ package database ให้อัตโนมัติ

## ตรวจสอบก่อนติดตั้ง

```bash
./install.sh --dry-run
```

## ซ่อมหลัง Wine update

ถ้า `NO_SIGNATURE` กลับมา:

```bash
line-linux repair
```

## ถอนการติดตั้ง

```bash
line-linux uninstall
```

จะลบเฉพาะ Wine prefix และข้อมูลของ helper ที่อยู่ใน:

```text
~/.local/share/line-linux-helper/
```

ไม่แตะ Wine prefix อื่นของเครื่อง

## Disclaimer สั้นสำหรับแชร์โพสต์

> LINE Linux Helper เป็น community compatibility/setup helper ที่ไม่เป็นทางการ ไม่ได้เป็นผลิตภัณฑ์หรือ installer ของ LINE/LY Corporation และไม่มีการ bundle, mirror, decode, decompile, reverse-engineer หรือ patch ตัว LINE โปรแกรมจะดาวน์โหลด LINE Windows Installer จาก CDN ทางการของ LINE โดยตรงขณะติดตั้ง ส่วน workaround ทั้งหมดทำเฉพาะใน Wine prefix แยกของผู้ใช้

## แก้ฟอนต์/การเรนเดอร์ตัวอักษร

ถ้า LINE เปิดได้แต่ตัวอักษรบาง แตก หรือภาษาไทย fallback ไม่สวย ให้รัน:

```bash
line-linux repair --fonts
```

คำสั่งนี้ตั้งค่า RGB font smoothing, gamma 1400, DPI 96 และใช้ Noto Sans / Noto Sans Thai เป็น fallback โดยไม่เก็บหรือแจกไฟล์ฟอนต์ไว้ใน repository
