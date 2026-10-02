USE qq_jaya_cell;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS schema_versions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(30) NOT NULL UNIQUE,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS api_clients (
    id CHAR(36) PRIMARY KEY,
    device_name VARCHAR(120) NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    last_used_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value TEXT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(100) NULL,
    cost_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    selling_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    track_stock TINYINT(1) NOT NULL DEFAULT 1,
    stock_quantity INT NOT NULL DEFAULT 0,
    minimum_stock INT NOT NULL DEFAULT 0,
    unit VARCHAR(30) NULL,
    barcode VARCHAR(150) NULL,
    qr_code VARCHAR(150) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    UNIQUE KEY uq_products_barcode (barcode),
    UNIQUE KEY uq_products_qr_code (qr_code),
    KEY idx_products_name (name),
    KEY idx_products_category (category),
    KEY idx_products_active (is_active),
    KEY idx_products_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stock_movements (
    id CHAR(36) PRIMARY KEY,
    product_id CHAR(36) NOT NULL,
    movement_type ENUM('in','sale','adjustment','correction') NOT NULL,
    quantity_change INT NOT NULL,
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    latest_cost_price DECIMAL(15,2) NULL,
    reference_type VARCHAR(40) NULL,
    reference_id CHAR(36) NULL,
    notes VARCHAR(255) NULL,
    occurred_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    CONSTRAINT fk_stock_product FOREIGN KEY (product_id) REFERENCES products(id),
    KEY idx_stock_product_date (product_id, occurred_at),
    KEY idx_stock_reference (reference_type, reference_id),
    KEY idx_stock_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sales (
    id CHAR(36) PRIMARY KEY,
    transaction_number VARCHAR(50) NOT NULL UNIQUE,
    subtotal DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_profit DECIMAL(15,2) NOT NULL DEFAULT 0,
    payment_method ENUM('cash','transfer','qris') NOT NULL,
    paid_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    change_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    notes VARCHAR(255) NULL,
    sold_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    KEY idx_sales_date (sold_at),
    KEY idx_sales_payment (payment_method),
    KEY idx_sales_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sale_items (
    id CHAR(36) PRIMARY KEY,
    sale_id CHAR(36) NOT NULL,
    product_id CHAR(36) NULL,
    product_name VARCHAR(180) NOT NULL,
    quantity INT NOT NULL,
    unit_cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    unit_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    line_cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    line_total DECIMAL(15,2) NOT NULL DEFAULT 0,
    line_profit DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    CONSTRAINT fk_sale_items_sale FOREIGN KEY (sale_id) REFERENCES sales(id),
    CONSTRAINT fk_sale_items_product FOREIGN KEY (product_id) REFERENCES products(id),
    KEY idx_sale_items_sale (sale_id),
    KEY idx_sale_items_product (product_id),
    KEY idx_sale_items_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_presets (
    id CHAR(36) PRIMARY KEY,
    device_name VARCHAR(180) NOT NULL,
    service_name VARCHAR(180) NOT NULL,
    service_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    parts_cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    default_warranty_value INT NULL,
    default_warranty_unit ENUM('hour','day') NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    UNIQUE KEY uq_service_preset (device_name, service_name),
    KEY idx_service_preset_device (device_name),
    KEY idx_service_preset_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS services (
    id CHAR(36) PRIMARY KEY,
    service_number VARCHAR(50) NOT NULL UNIQUE,
    customer_name VARCHAR(150) NULL,
    customer_whatsapp VARCHAR(30) NULL,
    customer_address TEXT NULL,
    device_name VARCHAR(180) NOT NULL,
    service_name VARCHAR(180) NOT NULL,
    color VARCHAR(60) NULL,
    accessories VARCHAR(255) NULL,
    service_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    parts_cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    delivery_cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_cost DECIMAL(15,2) NOT NULL DEFAULT 0,
    profit DECIMAL(15,2) NOT NULL DEFAULT 0,
    service_status ENUM('in','waiting','working','completed') NOT NULL DEFAULT 'in',
    payment_status ENUM('unpaid','down_payment','paid') NOT NULL DEFAULT 'unpaid',
    total_paid DECIMAL(15,2) NOT NULL DEFAULT 0,
    remaining_payment DECIMAL(15,2) NOT NULL DEFAULT 0,
    warranty_value INT NULL,
    warranty_unit ENUM('hour','day') NULL,
    warranty_started_at DATETIME NULL,
    warranty_ends_at DATETIME NULL,
    received_at DATETIME NOT NULL,
    completed_at DATETIME NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    KEY idx_services_status (service_status),
    KEY idx_services_payment (payment_status),
    KEY idx_services_device (device_name),
    KEY idx_services_received (received_at),
    KEY idx_services_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_payments (
    id CHAR(36) PRIMARY KEY,
    service_id CHAR(36) NOT NULL,
    payment_type ENUM('full','down_payment','settlement') NOT NULL,
    payment_method ENUM('cash','transfer','qris') NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    paid_at DATETIME NOT NULL,
    notes VARCHAR(255) NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    CONSTRAINT fk_service_payment_service FOREIGN KEY (service_id) REFERENCES services(id),
    KEY idx_service_payments_service (service_id),
    KEY idx_service_payments_date (paid_at),
    KEY idx_service_payments_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_status_history (
    id CHAR(36) PRIMARY KEY,
    service_id CHAR(36) NOT NULL,
    previous_status ENUM('in','waiting','working','completed') NULL,
    new_status ENUM('in','waiting','working','completed') NOT NULL,
    changed_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    CONSTRAINT fk_service_status_service FOREIGN KEY (service_id) REFERENCES services(id),
    KEY idx_service_status_history (service_id, changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS phones (
    id CHAR(36) PRIMARY KEY,
    phone_code VARCHAR(50) NOT NULL UNIQUE,
    device_name VARCHAR(180) NOT NULL,
    acquisition_type ENUM('stock','direct') NOT NULL,
    phone_status ENUM('available','sold') NOT NULL DEFAULT 'available',
    purchase_price DECIMAL(15,2) NOT NULL DEFAULT 0,
    selling_price DECIMAL(15,2) NULL,
    profit DECIMAL(15,2) NULL,
    condition_notes VARCHAR(255) NULL,
    accessories VARCHAR(255) NULL,
    seller_name VARCHAR(150) NULL,
    source_name VARCHAR(150) NULL,
    purchase_date DATETIME NOT NULL,
    sale_date DATETIME NULL,
    payment_method ENUM('cash','transfer','qris') NULL,
    warranty_value INT NULL,
    warranty_unit ENUM('hour','day') NULL,
    warranty_started_at DATETIME NULL,
    warranty_ends_at DATETIME NULL,
    notes VARCHAR(255) NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    KEY idx_phones_status (phone_status),
    KEY idx_phones_device (device_name),
    KEY idx_phones_purchase_date (purchase_date),
    KEY idx_phones_sale_date (sale_date),
    KEY idx_phones_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS expenses (
    id CHAR(36) PRIMARY KEY,
    expense_name VARCHAR(180) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    expense_date DATETIME NOT NULL,
    notes VARCHAR(255) NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME NULL,
    KEY idx_expenses_date (expense_date),
    KEY idx_expenses_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_requests (
    id CHAR(36) PRIMARY KEY,
    device_id CHAR(36) NULL,
    request_key VARCHAR(120) NOT NULL UNIQUE,
    entity_type VARCHAR(50) NOT NULL,
    entity_id CHAR(36) NOT NULL,
    operation ENUM('create','update','delete') NOT NULL,
    processed_at DATETIME NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_sync_entity (entity_type, entity_id),
    KEY idx_sync_processed (processed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO schema_versions (version) VALUES ('1.0.0');

SET FOREIGN_KEY_CHECKS = 1;
