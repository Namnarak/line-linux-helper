# LINE Linux Helper — คู่มือภาษาไทย

โปรเจกต์นี้เป็น **community compatibility/setup helper แบบไม่เป็นทางการ** สำหรับช่วยรัน LINE Desktop รุ่น Windows บน Linux ผ่าน Wine

> **สำคัญ:** โปรเจกต์นี้ไม่ใช่ผลิตภัณฑ์หรือ installer อย่างเป็นทางการของ LINE/LY Corporation
>
> Repo ไม่มีการ bundle, mirror, patch, decode, decompile หรือ reverse-engineer ตัว LINE โปรแกรมจะดาวน์โหลด `LineInst.exe` จาก CDN ทางการของ LINE (`desktop.line-scdn.net`) โดยตรง

## v0.3 เปลี่ยนอะไร

v0.3 รื้อ runtime/graphics path ใหม่เพื่อเน้นความเสถียรของ desktop app:

```text
Runtime:   Wine Staging 11.16
Build:     Kron4ek amd64-wow64
Display:   X11 / XWayland
Graphics:  WineD3D
Renderer:  OpenGL
DXVK:      ไม่ได้ติดตั้ง/จัดการ
Wayland:   native Wine Wayland ยังไม่ใช้ใน stable profile
```

รุ่นก่อนใช้ Proton-derived runner แต่ LINE ไม่ใช่เกม จึงย้ายมา Wine Staging ตรงๆ เพื่อให้ runtime เรียบขึ้นและ debug ง่ายกว่า

เลือก build แบบ WoW64 เพื่อช่วยลดการพึ่ง 32-bit libraries ฝั่ง Linux host แต่ยังต้องมี dependency 64-bit ปกติของ Wine

## ติดตั้ง

```bash
git clone https://github.com/Namnarak/line-linux-helper.git
cd line-linux-helper
./install.sh
```

หลังติดตั้ง:

```bash
line-linux launch
line-linux doctor
line-linux graphics
```

## ระบบ compatibility ทำอะไร

LINE Desktop บางรุ่นอาจปฏิเสธ Wine system DLL ด้วยข้อความลักษณะ:

```text
File: C:\windows\system32\CRYPT32.dll
Reason: NO_SIGNATURE
```

helper จะ:

1. สร้าง Wine prefix แยกเฉพาะ LINE
2. ใช้ Wine Staging ที่ pin เวอร์ชันและตรวจ SHA256
3. ตั้ง graphics profile เป็น WineD3D/OpenGL ผ่าน X11/XWayland
4. ตั้งฟอนต์ Noto/Thai/CJK และ font smoothing
5. สร้าง certificate แบบ self-signed ภายในเครื่อง
6. ใส่ compatibility signature ให้ Wine DLL เฉพาะใน prefix นี้
7. ดาวน์โหลด LINE installer จาก CDN ทางการของ LINE
8. ให้ installer ของ LINE ติดตั้ง/อัปเดตตัวแอปเอง

Certificate ที่สร้าง **ไม่ได้ออกโดย Microsoft**

## การย้าย prefix จาก runtime เก่า

v0.3 จะไม่เอา Wine ใหม่ไปเปิด prefix เก่าเฉยๆ

ถ้าตรวจพบว่า runtime เปลี่ยน helper จะ:

```text
wineboot -u
→ invalidate signing marker เก่า
→ ลง graphics/font profile ใหม่
→ sign Wine DLL ใหม่
```

เพราะการเปลี่ยน runtime สามารถแทนที่ DLL และทำให้ signature workaround เดิมใช้ไม่ได้

## ตรวจระบบ

ตรวจทั้งหมด:

```bash
line-linux doctor
```

ตรวจ graphics โดยเฉพาะ:

```bash
line-linux graphics
```

ถ้ามี `glxinfo` จะเห็น renderer จริงของ Linux host และตรวจ software fallback เช่น `llvmpipe` ได้

ตัวอย่าง:

```text
Managed display:         xwayland
Managed graphics:        wined3d
WineD3D renderer:        gl
Host OpenGL renderer:    Mesa Intel(R) Graphics
Hardware acceleration:   appears available
Wine host libraries:     OK
```

## Repair

ซ่อมทั้งหมด:

```bash
line-linux repair
```

ซ่อมเฉพาะส่วน:

```bash
line-linux repair --fonts
line-linux repair --graphics
line-linux repair --signatures
```

ถ้าระหว่าง targeted repair พบว่าต้อง migrate Wine runtime ระบบจะยกระดับเป็น full repair อัตโนมัติ เพราะซ่อมเฉพาะจุดไม่ปลอดภัยพอในกรณี DLL เปลี่ยน

## ฟอนต์

profile ปัจจุบันใช้:

- Noto Sans
- Noto Sans Thai
- CJK fallback ผ่าน Winetricks
- RGB subpixel smoothing
- gamma 1400
- DPI 96
- mapping ฟอนต์ Windows UI ที่ไม่มีบน Linux ไปยัง Noto/Liberation

Repo ไม่เก็บหรือแจกไฟล์ฟอนต์

## Distro ที่มี auto dependency path

- Arch Linux / CachyOS / Manjaro / EndeavourOS
- Debian / Ubuntu / Linux Mint / Pop!_OS
- Fedora / Nobara
- openSUSE Tumbleweed / Leap

ระบบ immutable/OSTree จะไม่ถูกแก้ package database อัตโนมัติ

Distro อื่นใช้:

```bash
./install.sh --no-packages
```

หลังติดตั้ง dependency เอง

## ถอนการติดตั้ง

```bash
line-linux uninstall
```

ข้อมูลหลักอยู่ที่:

```text
~/.local/share/line-linux-helper/
```

และ diagnostic state อยู่ใต้ XDG state directory ของผู้ใช้

ไม่แตะ Wine prefix อื่นของเครื่อง

## ข้อจำกัด

stable profile v0.3 ยังจงใจไม่ทำ:

- DXVK
- WineD3D Vulkan renderer
- native Wine Wayland
- การ patch `LINE.exe`

แนวคิดคือทำเส้นทางที่เรียบและตรวจสอบง่ายให้เสถียรก่อน แล้วค่อยเพิ่ม renderer/backend อื่นเป็น optional profile หลังมีผลทดสอบจริง
