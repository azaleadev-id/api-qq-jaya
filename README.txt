# QQ Jaya Cell API

Backend REST API untuk aplikasi QQ Jaya Cell, mencakup produk, stok, penjualan, servis HP, jual-beli HP, pengeluaran, dashboard, dan rekap.

## Requirements

- PHP 8+
- MySQL / MariaDB
- Apache dengan `mod_rewrite`
- PDO MySQL

## Configuration

Konfigurasi sensitif tidak disimpan di repository. Set environment berikut pada server:

```env
APP_ENV=production
APP_DEBUG=false
APP_API_KEY=replace_with_a_long_random_secret

DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=qq_jaya_cell
DB_USERNAME=your_database_user
DB_PASSWORD=your_database_password
```

`APP_API_KEY` wajib diisi. API tidak memiliki default key publik.

Import schema dari `database/qq_jaya_cell_schema.sql`.

## Authentication

Semua endpoint bisnis membutuhkan API key melalui salah satu header:

```http
X-API-Key: <your-api-key>
```

atau:

```http
Authorization: Bearer <your-api-key>
```

Endpoint `/` dan `/api/health` tidak membutuhkan API key.

## Main Endpoints

### Products
- `GET /api/products`
- `POST /api/products`
- `GET /api/products/{uuid}`
- `PUT|PATCH /api/products/{uuid}`
- `DELETE /api/products/{uuid}`

### Stock
- `GET /api/stock-movements`
- `GET /api/stock/low`
- `POST /api/stock/in`

### Sales
- `GET /api/sales`
- `POST /api/sales`
- `GET /api/sales/{uuid}`
- `PUT|PATCH /api/sales/{uuid}`
- `DELETE /api/sales/{uuid}`

### Services
- `GET /api/services`
- `POST /api/services`
- `GET /api/services/{uuid}`
- `PUT|PATCH /api/services/{uuid}`
- `DELETE /api/services/{uuid}`
- `PATCH /api/services/{uuid}/status`
- `POST /api/services/{uuid}/payments`
- `GET /api/service-presets`

### Phones
- `GET /api/phones`
- `POST /api/phones/purchases`
- `POST /api/phones/direct-sale`
- `POST /api/phones/{uuid}/sell`
- `GET /api/phones/{uuid}`
- `PUT|PATCH /api/phones/{uuid}`
- `DELETE /api/phones/{uuid}`

### Expenses
- `GET /api/expenses`
- `POST /api/expenses`
- `GET /api/expenses/{uuid}`
- `PUT|PATCH /api/expenses/{uuid}`
- `DELETE /api/expenses/{uuid}`

### Dashboard & Recaps
- `GET /api/dashboard`
- `GET /api/recaps/overall`
- `GET /api/recaps/products`
- `GET /api/recaps/services`
- `GET /api/recaps/phones`
- `GET /api/recaps/expenses`
- `GET /api/recaps/payments`

Endpoint rekap mendukung query `from` dan `to` dalam format `YYYY-MM-DD`.

## Security

Repository ini adalah versi source untuk portfolio. Credential database, API key production, data transaksi/customer production, dan konfigurasi hosting private tidak disimpan di repository.

Untuk deployment production:
- gunakan API key acak yang panjang;
- set `APP_DEBUG=false`;
- gunakan HTTPS;
- batasi CORS ke origin aplikasi yang diperlukan bila API digunakan dari browser;
- jangan commit dump database production atau file konfigurasi hosting yang berisi credential.
