import { Router } from "express";
import { pool } from "../db";

const router = Router();

async function getDefaultWarehouseAndLocation() {
  const [whRows]: any = await pool.query(
    "SELECT id FROM warehouses WHERE code = 'DEFAULT' LIMIT 1"
  );
  let warehouseId: number;

  if (whRows.length) {
    warehouseId = whRows[0].id;
  } else {
    const [result]: any = await pool.query(
      "INSERT INTO warehouses (code, name, enabled) VALUES ('DEFAULT', '默认仓库', 1)"
    );
    warehouseId = result.insertId;
  }

  const [locRows]: any = await pool.query(
    "SELECT id FROM locations WHERE warehouse_id = ? AND code = 'DEFAULT' LIMIT 1",
    [warehouseId]
  );
  let locationId: number;

  if (locRows.length) {
    locationId = locRows[0].id;
  } else {
    const [result]: any = await pool.query(
      "INSERT INTO locations (warehouse_id, code, type, enabled) VALUES (?, 'DEFAULT', 'STORAGE', 1)",
      [warehouseId]
    );
    locationId = result.insertId;
  }

  return { warehouseId, locationId };
}

router.get("/", async (_req, res) => {
  const [rows]: any = await pool.query(
    `SELECT p.id,
            p.sku,
            p.name,
            IFNULL(SUM(i.qty_on_hand), 0) AS stock
     FROM products p
     LEFT JOIN inventory i ON i.product_id = p.id
     GROUP BY p.id, p.sku, p.name
     ORDER BY p.id DESC`
  );
  res.json(rows);
});

router.post("/in", async (req, res) => {
  const { sku, qty } = req.body as { sku: string; qty: number };
  if (!sku || !qty || qty <= 0)
    return res.status(400).json({ message: "bad params" });

  const [productRows]: any = await pool.query(
    "SELECT id FROM products WHERE sku = ?",
    [sku]
  );
  if (!productRows.length)
    return res.status(404).json({ message: "not found" });

  const productId = productRows[0].id;
  const { warehouseId, locationId } = await getDefaultWarehouseAndLocation();

  const [invRows]: any = await pool.query(
    "SELECT id, qty_on_hand FROM inventory WHERE product_id = ? AND location_id = ?",
    [productId, locationId]
  );

  let beforeQty = 0;
  let afterQty = 0;

  if (invRows.length) {
    beforeQty = Number(invRows[0].qty_on_hand);
    afterQty = beforeQty + qty;
    await pool.query(
      "UPDATE inventory SET qty_on_hand = ? WHERE id = ?",
      [afterQty, invRows[0].id]
    );
  } else {
    beforeQty = 0;
    afterQty = qty;
    const [result]: any = await pool.query(
      "INSERT INTO inventory (product_id, warehouse_id, location_id, qty_on_hand, qty_reserved) VALUES (?, ?, ?, ?, 0)",
      [productId, warehouseId, locationId, afterQty]
    );
  }

  await pool.query(
    `INSERT INTO inventory_movements
     (product_id, warehouse_id, location_id, movement_type, direction, qty, before_qty, after_qty, ref_type, ref_id, remark)
     VALUES (?, ?, ?, 'IN', 1, ?, ?, ?, 'MANUAL', NULL, '手工入库')`,
    [productId, warehouseId, locationId, qty, beforeQty, afterQty]
  );

  res.json({ ok: true });
});

router.post("/out", async (req, res) => {
  const { sku, qty } = req.body as { sku: string; qty: number };
  if (!sku || !qty || qty <= 0)
    return res.status(400).json({ message: "bad params" });

  const [productRows]: any = await pool.query(
    "SELECT id FROM products WHERE sku = ?",
    [sku]
  );
  if (!productRows.length)
    return res.status(404).json({ message: "not found" });

  const productId = productRows[0].id;
  const { warehouseId, locationId } = await getDefaultWarehouseAndLocation();

  const [invRows]: any = await pool.query(
    "SELECT id, qty_on_hand FROM inventory WHERE product_id = ? AND location_id = ?",
    [productId, locationId]
  );

  if (!invRows.length || Number(invRows[0].qty_on_hand) < qty)
    return res.status(400).json({ message: "insufficient" });

  const beforeQty = Number(invRows[0].qty_on_hand);
  const afterQty = beforeQty - qty;

  await pool.query(
    "UPDATE inventory SET qty_on_hand = ? WHERE id = ?",
    [afterQty, invRows[0].id]
  );

  await pool.query(
    `INSERT INTO inventory_movements
     (product_id, warehouse_id, location_id, movement_type, direction, qty, before_qty, after_qty, ref_type, ref_id, remark)
     VALUES (?, ?, ?, 'OUT', -1, ?, ?, ?, 'MANUAL', NULL, '手工出库')`,
    [productId, warehouseId, locationId, qty, beforeQty, afterQty]
  );

  res.json({ ok: true });
});

router.get("/movements", async (_req, res) => {
  const [rows]: any = await pool.query(
    `SELECT m.id,
            m.created_at,
            m.movement_type,
            m.direction,
            m.qty,
            m.before_qty,
            m.after_qty,
            p.sku,
            p.name AS product_name,
            w.name AS warehouse_name,
            l.code AS location_code
     FROM inventory_movements m
     JOIN products p ON p.id = m.product_id
     JOIN warehouses w ON w.id = m.warehouse_id
     JOIN locations l ON l.id = m.location_id
     ORDER BY m.id DESC
     LIMIT 100`
  );
  res.json(rows);
});

export default router;
