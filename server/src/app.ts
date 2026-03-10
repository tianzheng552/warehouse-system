import express from "express";
import cors from "cors";
import healthRouter from "./routes/health";
import inventoryRouter from "./routes/inventory";

const app = express();
app.use(cors());
app.use(express.json());
app.use("/health", healthRouter);
app.use("/inventory", inventoryRouter);

export default app;
