import dotenv from "dotenv";
import app from "./app";
import { pool } from "./db";

dotenv.config();
const port = Number(process.env.PORT || 4000);

async function bootstrap() {
await pool.query("SELECT 1");
app.listen(port, () => console.log(`warehouse-server running at http://127.0.0.1:${port}`));
}
bootstrap().catch((e) => {
console.error(e);
process.exit(1);
});
