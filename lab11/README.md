# Lab 11 - Deploy microservices lên Render (thay cho Heroku)

Heroku đã bỏ gói miễn phí, nên bài này dùng **[Render](https://render.com)**: free, không cần thẻ tín dụng, deploy từ GitHub, có Postgres free.

## Heroku → Render

| Lab gốc (Heroku) | Làm trên Render |
| --- | --- |
| `heroku login` | Đăng ký render.com bằng tài khoản GitHub |
| `Procfile` (`web: node server.js`) | `startCommand: npm start` trong `render.yaml` |
| `heroku create ...` × 4 | `render.yaml` (Blueprint) tạo cả 4 service một lần |
| `heroku config:set KEY=VALUE` | `envVars` trong `render.yaml`, hoặc tab **Environment** của service |
| `git push heroku main` | `git push origin main` → Render tự deploy |
| `heroku logs --tail` | Tab **Logs** của từng service (xem realtime) |
| Dashboard metrics | Tab **Metrics** (CPU, RAM, HTTP requests, response time) |
| Papertrail / New Relic add-on | Logs + Metrics có sẵn; muốn đẩy log ra ngoài: **Log Streams** → Better Stack (free) |
| `heroku addons:create heroku-postgresql` | Render Postgres free (khai báo trong `render.yaml`) |
| `heroku pg:psql` | Copy **PSQL Command** (External) trong trang database, chạy bằng `psql` |
| `heroku domains:add` + `certs:auto` | Tab **Settings → Custom Domains**, SSL miễn phí tự động |
| GitHub Actions `heroku-deploy` | `.github/workflows/ci-cd.yml` + Auto-Deploy / Deploy Hook |
| `xxx.herokuapp.com` | `xxx.onrender.com` |

## Cấu trúc

```
microservices-lab/             # repo GitHub
├── render.yaml                # Blueprint: 4 web service + 1 Postgres (phải nằm ở gốc repo)
├── .github/workflows/ci-cd.yml
└── lab11/
    ├── docker-compose.yml     # chạy thử local
    ├── test-render.sh / .ps1  # script test (Bước 4)
    ├── user-service/          # Express + PostgreSQL (bản cuối của Bước 9)
    ├── product-service/       # Express, in-memory
    ├── order-service/         # Express + axios gọi user/product service
    └── api-gateway/           # Express + http-proxy-middleware
```

Render chỉ build lại service khi có thay đổi trong `rootDir` của service đó, nên sửa code lab 9/10 không làm redeploy lab 11.

## Bước 0 - Chạy thử trên máy

```powershell
cd D:\microservices-lab\lab11
docker compose up -d          # gateway ở http://localhost:3000
.\test-render.ps1 -Gateway http://localhost:3000
docker compose down -v
```

## Bước 1 - Đưa code lên GitHub

Repo: https://github.com/KhoiTran2905/microservices-lab (toàn bộ thư mục `D:\microservices-lab`).

```powershell
cd D:\microservices-lab
git add .
git commit -m "..."
git push
```

## Bước 2 - Deploy bằng Blueprint

1. Đăng nhập https://dashboard.render.com bằng GitHub.
2. **New → Blueprint** → chọn repo `microservices-lab` → Render đọc `render.yaml` ở gốc repo.
3. Kiểm tra danh sách (1 database + 4 web service) → **Deploy Blueprint**.
4. Chờ 3-5 phút đến khi tất cả có trạng thái **Live**.

**Quan trọng:** mở từng service xem URL thật. Nếu URL khác `https://mslab11-1ic2-<tên>.onrender.com` (do trùng tên, Render thêm hậu tố), sửa lại `USER_SERVICE_URL`, `PRODUCT_SERVICE_URL`, `ORDER_SERVICE_URL` trong tab **Environment** của `order-service` và `api-gateway` (hoặc sửa `render.yaml` rồi push).

## Bước 3 - Test (Bước 4 của lab)

```powershell
.\test-render.ps1                    # PowerShell
```
```bash
./test-render.sh                     # Git Bash (jq không bắt buộc)
```

Hoặc mở trình duyệt: `https://mslab11-1ic2-api-gateway.onrender.com/health`

## Bước 4 - Logging & Monitoring (Bước 5 của lab)

- Dashboard → chọn service → **Logs** (lọc, tìm kiếm, realtime) và **Metrics**.
- Khi tạo order sẽ thấy log `Proxying POST /orders ...` ở gateway, `User verified` / `Stock updated` ở order-service.

## Bước 5 - Environment Variables (Bước 6)

Dashboard → service → **Environment** → thêm/sửa biến → **Save, rebuild, and deploy**.
`NODE_ENV`, `LOG_LEVEL`, `RATE_LIMIT` đã được khai báo sẵn trong `render.yaml`.

## Bước 6 - Custom domain (Bước 7, tuỳ chọn - cần có tên miền)

Service `api-gateway` → **Settings → Custom Domains → Add** `api.yourdomain.com`, rồi thêm bản ghi DNS:
`api.yourdomain.com  CNAME  mslab11-1ic2-api-gateway.onrender.com`. SSL được cấp tự động.

## Bước 7 - CI/CD (Bước 8)

- Push lên `main` → GitHub Actions chạy job `check` (cài dependencies + kiểm tra cú pháp 4 service), song song Render tự deploy.
- Muốn **chỉ deploy khi CI xanh**: với từng service, vào **Settings** → tắt **Auto-Deploy**, copy **Deploy Hook**; vào GitHub repo → **Settings → Secrets and variables → Actions** → tạo secret `RENDER_DEPLOY_HOOKS` chứa 4 URL hook cách nhau bởi dấu cách.

## Bước 8 - Database (Bước 9)

`user-service` đã dùng Postgres (`db.js`), `DATABASE_URL` được Render tự gắn từ database `mslab11-1ic2-user-db`.

- Kiểm tra: `https://mslab11-1ic2-api-gateway.onrender.com/users/health` → `"database": "connected"`.
- Truy vấn trực tiếp: trang database → **Connect → External** → copy lệnh `PSQL Command` (cần cài `psql`), rồi:
  ```sql
  \dt
  SELECT * FROM users;
  SELECT COUNT(*) FROM users;
  ```
  (Lab gốc có `WHERE deleted_at IS NULL` nhưng bảng không có cột này → bỏ đi.)
- Không muốn cài psql: dùng DBeaver hoặc pgAdmin với thông tin kết nối External.

## Lưu ý về gói free của Render

- Service **ngủ sau 15 phút** không có request; request đầu tiên mất 30-60 giây. Gateway và order-service đã được đặt timeout dài (60-90s) cho trường hợp này. Gọi `/health` của gateway trước để đánh thức cả hệ thống.
- Khi service ngủ/khởi động lại, dữ liệu **in-memory** (products, orders) bị reset; users nằm trong Postgres nên giữ lại.
- 750 giờ chạy free/tháng cho cả workspace - dư cho bài lab vì service ngủ khi không dùng.
- Postgres free **hết hạn sau 30 ngày**. Cần lâu hơn thì dùng [Neon](https://neon.tech) (free, không hết hạn): xoá `fromDatabase`, đặt `DATABASE_URL` = connection string của Neon và `DB_SSL=true`.

## Những chỗ đã sửa so với code trong lab11.md

| Vấn đề trong lab gốc | Đã sửa |
| --- | --- |
| `engines: node 16.x` - Node 16 không có `fetch` (gateway dùng `fetch`) và đã hết hỗ trợ | Node 20 (`NODE_VERSION=20`) |
| Gateway gọi `express.json()` trước proxy → body bị đọc hết, POST qua gateway bị treo | Bỏ `express.json()` ở gateway |
| `pathRewrite { '^/users': '' }` → `GET /users` bị chuyển thành `GET /` (trả thông tin service thay vì danh sách user), `/users/1` thành `/1` (404) | Giữ nguyên path, chỉ map `/users/health` → `/health` |
| Health check của gateway báo "healthy" kể cả khi service trả lỗi | Kiểm tra `response.ok`, chạy song song |
| Timeout 5-10s quá ngắn khi service free đang ngủ | 60s (order-service), 90s (gateway) |
