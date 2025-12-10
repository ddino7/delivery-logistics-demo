const express = require("express");
const router = express.Router();
const controller = require("../controllers/shipmentController");

router.post("/", controller.createShipment);
router.get("/:tracking", controller.getShipment);
router.put("/:tracking/status", controller.updateStatus);

module.exports = router;
