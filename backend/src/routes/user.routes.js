const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const { authenticateToken } = require('../middleware/auth');

// All routes are protected with JWT authentication
router.use(authenticateToken);

// User profile routes
router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);

// User preferences
router.post('/preferences', userController.savePreferences);
router.get('/preferences', userController.getPreferences);

module.exports = router;
