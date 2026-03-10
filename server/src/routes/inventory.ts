import { Router } from "express";
import { pool } from "../db";
const router = Router();

router.get("/", async (_req, res) => {
const [rows] = await pool.query("SELECT id, sku, name, stock FROM products ORDER BY id DESC");
res.json(rows);
});

router.post("/in", async (req, res) => {
const { sku, qty } = req.body as { sku: string; qty: number };
if (!sku || !qty || qty <= 0) return res.status(400).json({ message: "bad params" });
const [result]: any = await pool.query("UPDATE products SET stock = stock + ? WHERE sku = ?", [qty, sku]);
if (result.affectedRows === 0) return res.status(404).json({ message: "not found" });
res.json({ ok: true });
});

router.post("/out", async (req, res) => {
const { sku, qty } = req.body as { sku: string; qty: number };
if (!sku || !qty || qty <= 0) return res.status(400).json({ message: "bad params" });
const [rows]: any = await pool.query("SELECT stock FROM products WHERE sku = ?", [sku]);
if (!rows.length) return res.status(404).json({ message: "not found" });
if (rows[0].stock < qty) return res.status(400).json({ message: "insufficient" });
await pool.query("UPDATE products SET stock = stock - ? WHERE sku = ?", [qty, sku]);
res.json({ ok: true });
});

export default router;
