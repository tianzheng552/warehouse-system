-- Warehouse system database schema
-- Execute in MySQL (8.0+ recommended)

CREATE DATABASE IF NOT EXISTS warehouse_db DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE warehouse_db;

-- 1. Product categories
CREATE TABLE IF NOT EXISTS product_categories (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(100) NOT NULL,
  parent_id   BIGINT UNSIGNED NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_product_categories_parent
    FOREIGN KEY (parent_id) REFERENCES product_categories(id)
    ON DELETE SET NULL
);

-- 2. Products
CREATE TABLE IF NOT EXISTS products (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sku          VARCHAR(64) NOT NULL,
  name         VARCHAR(255) NOT NULL,
  barcode      VARCHAR(128) NULL,
  spec         VARCHAR(255) NULL,
  unit         VARCHAR(32)  NULL,
  category_id  BIGINT UNSIGNED NULL,
  enabled      TINYINT(1) NOT NULL DEFAULT 1,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_products_sku (sku),
  KEY idx_products_category (category_id),
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES product_categories(id)
    ON DELETE SET NULL
);

-- 3. Warehouses
CREATE TABLE IF NOT EXISTS warehouses (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code        VARCHAR(64) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  address     VARCHAR(255) NULL,
  enabled     TINYINT(1) NOT NULL DEFAULT 1,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_warehouses_code (code)
);

-- 4. Locations
CREATE TABLE IF NOT EXISTS locations (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  code         VARCHAR(64) NOT NULL,
  type         VARCHAR(32) NOT NULL DEFAULT 'STORAGE',
  enabled      TINYINT(1) NOT NULL DEFAULT 1,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_locations_wh_code (warehouse_id, code),
  KEY idx_locations_warehouse (warehouse_id),
  CONSTRAINT fk_locations_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
    ON DELETE CASCADE
);

-- 5. Users
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  username      VARCHAR(64) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name          VARCHAR(100) NULL,
  role          VARCHAR(32) NOT NULL DEFAULT 'OPERATOR',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_users_username (username)
);

-- 6. Inventory
CREATE TABLE IF NOT EXISTS inventory (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  product_id    BIGINT UNSIGNED NOT NULL,
  warehouse_id  BIGINT UNSIGNED NOT NULL,
  location_id   BIGINT UNSIGNED NOT NULL,
  qty_on_hand   DECIMAL(18,3) NOT NULL DEFAULT 0,
  qty_reserved  DECIMAL(18,3) NOT NULL DEFAULT 0,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_inventory_product_location (product_id, location_id),
  KEY idx_inventory_warehouse (warehouse_id),
  CONSTRAINT fk_inventory_product
    FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_inventory_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_inventory_location
    FOREIGN KEY (location_id) REFERENCES locations(id)
);

-- 7. Inventory movements
CREATE TABLE IF NOT EXISTS inventory_movements (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  product_id    BIGINT UNSIGNED NOT NULL,
  warehouse_id  BIGINT UNSIGNED NOT NULL,
  location_id   BIGINT UNSIGNED NOT NULL,
  movement_type VARCHAR(16) NOT NULL,
  direction     TINYINT NOT NULL,
  qty           DECIMAL(18,3) NOT NULL,
  before_qty    DECIMAL(18,3) NULL,
  after_qty     DECIMAL(18,3) NULL,
  ref_type      VARCHAR(32) NULL,
  ref_id        BIGINT UNSIGNED NULL,
  remark        VARCHAR(255) NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by    BIGINT UNSIGNED NULL,
  KEY idx_movements_product (product_id),
  KEY idx_movements_ref (ref_type, ref_id),
  KEY idx_movements_created_at (created_at),
  CONSTRAINT fk_movements_product
    FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_movements_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_movements_location
    FOREIGN KEY (location_id) REFERENCES locations(id),
  CONSTRAINT fk_movements_user
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- 8. Suppliers
CREATE TABLE IF NOT EXISTS suppliers (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code        VARCHAR(64) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  contact     VARCHAR(100) NULL,
  phone       VARCHAR(50)  NULL,
  address     VARCHAR(255) NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_suppliers_code (code)
);

-- 9. Purchase orders
CREATE TABLE IF NOT EXISTS purchase_orders (
  id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  po_number     VARCHAR(64) NOT NULL,
  supplier_id   BIGINT UNSIGNED NOT NULL,
  warehouse_id  BIGINT UNSIGNED NOT NULL,
  status        VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  expected_date DATE NULL,
  total_amount  DECIMAL(18,2) NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by    BIGINT UNSIGNED NULL,
  UNIQUE KEY uk_pos_number (po_number),
  KEY idx_pos_supplier (supplier_id),
  CONSTRAINT fk_pos_supplier
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CONSTRAINT fk_pos_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_pos_user
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  product_id        BIGINT UNSIGNED NOT NULL,
  qty_ordered       DECIMAL(18,3) NOT NULL,
  qty_received      DECIMAL(18,3) NOT NULL DEFAULT 0,
  price             DECIMAL(18,3) NOT NULL DEFAULT 0,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_poi_po (purchase_order_id),
  KEY idx_poi_product (product_id),
  CONSTRAINT fk_poi_po
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_poi_product
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- 10. Receipts (inbound)
CREATE TABLE IF NOT EXISTS receipts (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  receipt_number   VARCHAR(64) NOT NULL,
  purchase_order_id BIGINT UNSIGNED NULL,
  warehouse_id     BIGINT UNSIGNED NOT NULL,
  status           VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by       BIGINT UNSIGNED NULL,
  UNIQUE KEY uk_receipts_number (receipt_number),
  KEY idx_receipts_po (purchase_order_id),
  CONSTRAINT fk_receipts_po
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  CONSTRAINT fk_receipts_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_receipts_user
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS receipt_items (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  receipt_id   BIGINT UNSIGNED NOT NULL,
  product_id   BIGINT UNSIGNED NOT NULL,
  location_id  BIGINT UNSIGNED NOT NULL,
  qty          DECIMAL(18,3) NOT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ri_receipt (receipt_id),
  KEY idx_ri_product (product_id),
  CONSTRAINT fk_ri_receipt
    FOREIGN KEY (receipt_id) REFERENCES receipts(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_ri_product
    FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_ri_location
    FOREIGN KEY (location_id) REFERENCES locations(id)
);

-- 11. Customers
CREATE TABLE IF NOT EXISTS customers (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code        VARCHAR(64) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  contact     VARCHAR(100) NULL,
  phone       VARCHAR(50)  NULL,
  address     VARCHAR(255) NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_customers_code (code)
);

-- 12. Sales orders
CREATE TABLE IF NOT EXISTS sales_orders (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  so_number    VARCHAR(64) NOT NULL,
  customer_id  BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  status       VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  total_amount DECIMAL(18,2) NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by   BIGINT UNSIGNED NULL,
  UNIQUE KEY uk_sos_number (so_number),
  KEY idx_sos_customer (customer_id),
  CONSTRAINT fk_sos_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_sos_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_sos_user
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS sales_order_items (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  product_id     BIGINT UNSIGNED NOT NULL,
  qty_ordered    DECIMAL(18,3) NOT NULL,
  qty_allocated  DECIMAL(18,3) NOT NULL DEFAULT 0,
  qty_shipped    DECIMAL(18,3) NOT NULL DEFAULT 0,
  price          DECIMAL(18,3) NOT NULL DEFAULT 0,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_soi_so (sales_order_id),
  KEY idx_soi_product (product_id),
  CONSTRAINT fk_soi_so
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_soi_product
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- 13. Shipments (outbound)
CREATE TABLE IF NOT EXISTS shipments (
  id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  shipment_number VARCHAR(64) NOT NULL,
  sales_order_id  BIGINT UNSIGNED NULL,
  warehouse_id    BIGINT UNSIGNED NOT NULL,
  status          VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by      BIGINT UNSIGNED NULL,
  UNIQUE KEY uk_shipments_number (shipment_number),
  KEY idx_shipments_so (sales_order_id),
  CONSTRAINT fk_shipments_so
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_shipments_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_shipments_user
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS shipment_items (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  shipment_id  BIGINT UNSIGNED NOT NULL,
  product_id   BIGINT UNSIGNED NOT NULL,
  location_id  BIGINT UNSIGNED NOT NULL,
  qty          DECIMAL(18,3) NOT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_si_shipment (shipment_id),
  KEY idx_si_product (product_id),
  CONSTRAINT fk_si_shipment
    FOREIGN KEY (shipment_id) REFERENCES shipments(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_si_product
    FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_si_location
    FOREIGN KEY (location_id) REFERENCES locations(id)
);

-- 14. Stock counts (optional)
CREATE TABLE IF NOT EXISTS stock_counts (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  count_number VARCHAR(64) NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  status       VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by   BIGINT UNSIGNED NULL,
  UNIQUE KEY uk_stock_counts_number (count_number),
  CONSTRAINT fk_stock_counts_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_stock_counts_user
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS stock_count_items (
  id                     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  stock_count_id         BIGINT UNSIGNED NOT NULL,
  product_id             BIGINT UNSIGNED NOT NULL,
  location_id            BIGINT UNSIGNED NOT NULL,
  qty_system             DECIMAL(18,3) NOT NULL,
  qty_counted            DECIMAL(18,3) NOT NULL,
  qty_diff               DECIMAL(18,3) NOT NULL,
  adjustment_movement_id BIGINT UNSIGNED NULL,
  created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sci_count
    FOREIGN KEY (stock_count_id) REFERENCES stock_counts(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_sci_product
    FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_sci_location
    FOREIGN KEY (location_id) REFERENCES locations(id),
  CONSTRAINT fk_sci_movement
    FOREIGN KEY (adjustment_movement_id) REFERENCES inventory_movements(id)
);

