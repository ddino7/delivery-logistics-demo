const mongoose = require("mongoose");

const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true },
  quantity: { type: Number, required: true }
});

const ShipmentSchema = new mongoose.Schema({
  trackingNumber: { type: String, unique: true, required: true },

  sender: {
    name: String,
    address: String
  },

  recipient: {
    name: String,
    address: String
  },

  weight: Number,

  status: {
    type: String,
    enum: ["CREATED", "WAREHOUSE", "IN_TRANSIT", "DELIVERED"],
    default: "CREATED"
  },

  products: [ProductSchema],

  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model("Shipment", ShipmentSchema);
