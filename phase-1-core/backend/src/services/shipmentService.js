const Shipment = require("../models/Shipment");
const { v4: uuidv4 } = require("uuid");

async function createShipment(data) {
  const trackingNumber = uuidv4();

  const shipment = new Shipment({
    trackingNumber,
    sender: data.sender,
    recipient: data.recipient,
    weight: data.weight,
    products: data.products
  });

  return await shipment.save();
}

async function getShipmentByTracking(trackingNumber) {
  return await Shipment.findOne({ trackingNumber });
}

async function updateShipmentStatus(trackingNumber, status) {
  return await Shipment.findOneAndUpdate(
    { trackingNumber },
    { status },
    { new: true }
  );
}

module.exports = {
  createShipment,
  getShipmentByTracking,
  updateShipmentStatus
};