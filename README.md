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

1. Register user
2. Login user (ได้ JWT)
3. Login admin (ได้ JWT)
4. Forgot Password User -> email เข้า Inbox Gmail จริง
5. Reset Password User (code ใช้ครั้งเดียว)
6. Forgot Password Admin -> email เข้า Inbox Gmail จริง
7. Reset Password Admin (token ใช้ครั้งเดียว)
8. Profile user / admin
9-12. CRUD content types: students / teachers / subjects / mappings

> Reset-password token เป็น **single-use** ถ้ายิงขั้น 5/7 แล้วได้ 400
> ให้ไปรันขั้น 4/6 ใหม่ token ล่าสุดจะเข้า inbox ของ `real922548@gmail.com`
> (token ใน DB (`reset_password_token`) คือค่าที่ email ส่งไป เอามาใส่ขั้น 5/7 ได้)

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

> ทดสอบ single-use ได้จาก api.http: ยิงข้อ 5 (หรือ 7) ครั้งแรกได้ 200, ยิงซ้ำด้วย code เดิมได้ 400

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