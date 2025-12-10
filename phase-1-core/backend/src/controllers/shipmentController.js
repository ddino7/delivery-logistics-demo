const shipmentService = require("../services/shipmentService");

async function createShipment(req, res) {
  try {
    const shipment = await shipmentService.createShipment(req.body);
    res.status(201).json(shipment);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function getShipment(req, res) {
  try {
    const shipment = await shipmentService.getShipmentByTracking(
      req.params.tracking
    );

    if (!shipment) {
      return res.status(404).json({ message: "Shipment not found" });
    }

    res.json(shipment);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function updateStatus(req, res) {
  try {
    const { status } = req.body;

    const shipment = await shipmentService.updateShipmentStatus(
      req.params.tracking,
      status
    );

    if (!shipment) {
      return res.status(404).json({ message: "Shipment not found" });
    }

    res.json(shipment);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  createShipment,
  getShipment,
  updateStatus
};