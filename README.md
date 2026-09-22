# Cyber Security

Strapi v4 (REST API) + PostgreSQL + pgAdmin — รันด้วย Docker Compose ใช้ทำการบ้านวิชา Cyber Security

## Stack

| Service  | Container  | Port          | หน้าที่                        |
| -------- | ---------- | ------------- | ------------------------------ |
| Strapi   | 69-s1-app  | http://localhost:9091 | REST API + Admin Panel |
| Postgres | 69-s1-db   | 54327          | ฐานข้อมูล                       |
| pgAdmin  | 69-s1-admin| http://localhost:8081 | จัดการฐานข้อมูล              |

Email forgot-password ส่งผ่าน SMTP จริง (**Gmail**: `smtp.gmail.com:465` TLS) ไปที่ `real922548@gmail.com`

## เริ่มใช้งาน

```powershell
docker compose up -d
```

Admin เข้า `http://localhost:9091/admin` (email/password อยู่ใน `.env`)
User ใช้ `POST /api/auth/local` login

## API Flow (อยู่ใน api.http)

เรียงตามเทมเพลต — login / register / forgot / reset / profile:

1. Login admin (ได้ JWT) — รหัสปัจจุบัน `Tonkla25488`
2. Register admin (`/admin/register-admin`) — ได้ 200 เฉพาะตอน DB ยังไม่มี admin (มีแล้ว Strapi `register-admin` คืน 400 เสมอ)
3. Forgot Password Admin -> สร้าง token ใหม่เข้าอีเมลจริง + DB (`admin_users.reset_password_token`), ตอบ `204`
4. Reset Password Admin (token ในไฟล์ต้องตรงกับ DB — seed ผ่าน `scripts/seed-reset-tokens.ps1`)
5. Profile admin
6. Login user (ได้ JWT)
7. Register user (username/email สุ่มด้วย `{{$guid}}` -> ได้ 200 เสมอ)
8. Forgot Password User -> สร้าง code ใหม่เข้าอีเมลจริง + DB (`up_users.reset_password_token`)
9. Reset Password User (code ในไฟล์ต้องตรงกับ DB)
10. Profile user
11-14. CRUD content types: students / teachers / subjects / mappings

> **ข้อจำกัด reset (ขั้น 4/9):** token เป็น single-use — ถ้ากด forgot (ขั้น 3/8) ก่อน token ในไฟล์จะกลายเป็นค่าเก่า → reset ได้ 400 (รหัสไม่เปลี่ยน)
> วิธีทำให้ reset เป็น 200:
> - กด reset ตรง ๆ (DB ถูก seed ไว้ตรงไฟล์แล้ว) หรือ
> - รัน `scripts/seed-reset-tokens.ps1` ก่อนกด reset
> - ต้องการ demo "forgot → reset เปลี่ยนรหัสจริง" ทั้ง flow: รัน `powershell -ExecutionPolicy Bypass -File scripts/reset-demo.ps1` (จบ flow ได้ 200 + login ยืนยันได้ 200)

## Forgot / Reset Password Flow (Single-Use Token)

```
POST /api/auth/forgot-password {"email"}          -> สร้าง token สุ่ม 64 bytes -> ส่ง email + ?code=<token> (SMTP Gmail จริง)
POST /api/auth/reset-password  {"code","password","passwordConfirmation"} -> รีเซ็ต + ล้าง token (single-use)
POST /admin/forgot-password    {"email"}          -> เช่นเดียวกับ user (admin_users)
POST /admin/reset-password     {"resetPasswordToken","password"}            -> เช่นเดียวกับ user (admin_users)
```

**Security ของ flow นี้ (มาจาก Strapi users-permissions plugin):**
1. Token สุ่มด้วย `crypto.randomBytes(64).toString('hex')` (128 ตัวอักษร) — เดายาก
2. เก็บ token ไว้ทีละตัวใน `up_users.resetPasswordToken` / `admin_users.resetPasswordToken`
3. เปิดด้วย `code` ต้องตรงเป๊ะ ถึงจะ reset ได้
4. **ใช้ได้ครั้งเดียว** — หลัง reset แล้ว Strapi เซต `resetPasswordToken = null` ทำให้ code เดิมใช้ซ้ำไม่ได้ (ได้ 400 `Incorrect code provided`) ต้องไปยิง `forgot-password` ใหม่เพื่อขอ token ใหม่ทุกครั้ง
5. จัด timeline: ใครขอ email ถ้าเราไม่ได้เป็นเจ้าของ email ก็ไม่มีทางได้ token (เป็นสิ่งที่ควรอธิบายเรื่อง single-use + token เป็น secret แบบ session)

> ทดสอบ single-use ได้จาก api.http: กด reset ครั้งแรกได้ 200, กดซ้ำด้วย code เดิมได้ 400 `Incorrect code provided`
> อยากให้ได้ 200 ซ้ำได้หลายรอบ -> รัน `powershell -ExecutionPolicy Bypass -File scripts/seed-reset-tokens.ps1` (เขียน token ใน api.http ลง DB ให้ตรงกันทุกครั้งก่อนกด demo)

## Content-Type

- **student**: name, mobile (hash MD5 อัตโนมัติใน `beforeCreate`), cardId
- **teacher**: name, mappings (1-N)
- **subject**: name (unique)
- **mapping**: subjects (1-N) + teacher (N-1)

เปิดสิทธิ์ CRUD ใน Admin: `Users & Permissions Plugin -> Roles -> Authenticated`
แล้วใช้ JWT ของ user เรียก `/api/students`, `/api/teachers`, `/api/subjects`, `/api/mappings`

## My Information

* Sanchai Tangjai
* รหัสนักศึกษา: 0568604050XXX
* ความคาดหวังของวิชานี้อยากได้อะไร: อยากเรียนรู้และหาความรู้เพิ่มเติมกับวิชานี้ครับ อยากเก่งขึ้น