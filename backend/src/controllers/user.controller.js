const User = require('../models/user.model');
const db = require('../config/db');

const userController = {
  async savePreferences(req, res) {
    try {
      const { language, level, reason, dailyGoal } = req.body;
      const userId = req.user.userId;

      const updatedUser = await User.updatePreferences(userId, {
        language,
        level,
        reason,
        dailyGoal
      });

      res.json({
        message: 'Preferences saved successfully',
        user: updatedUser
      });
    } catch (error) {
      console.error('Save preferences error:', error);
      res.status(500).json({ message: 'Error saving preferences' });
    }
  },

  async getPreferences(req, res) {
    try {
      const userId = req.user.userId;
      const preferences = await User.getPreferences(userId);
      
      if (!preferences) {
        return res.status(404).json({ message: 'No preferences found' });
      }

      res.json(preferences);
    } catch (error) {
      console.error('Get preferences error:', error);
      res.status(500).json({ message: 'Error fetching preferences' });
    }
  },

  async getProfile(req, res) {
    try {
      const user = await User.findById(req.user.userId);
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      res.json(user);
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({ message: 'Error fetching profile' });
    }
  },

  async updateProfile(req, res) {
    try {
      const { name, language, level, reason, dailyGoal } = req.body;
      const userId = req.user.userId;

      // Update user profile with provided fields
      const updatedUser = await User.updatePreferences(userId, {
        name,
        language,
        level,
        reason,
        dailyGoal
      });

      res.json(updatedUser);
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({ message: 'Error updating profile' });
    }
  }
};

module.exports = userController;
