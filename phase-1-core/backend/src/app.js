const express = require("express");
const mongoose = require("mongoose");
const shipmentRoutes = require("./routes/shipmentRoutes");

const app = express();
app.use(express.json());

const MONGO_URL =
  process.env.MONGO_URL || "mongodb://localhost:27017/delivery";

mongoose
  .connect(MONGO_URL)
  .then(() => console.log("Connected to MongoDB"))
  .catch(err => console.error(err));

app.use("/shipments", shipmentRoutes);

app.get("/health", (req, res) => {
  res.send("OK");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
});
