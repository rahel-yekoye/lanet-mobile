const User = require('../models/user.model');

const userController = {
  async savePreferences(req, res) {
    try {
      const { language, level, reason, dailyGoal } = req.body;
      const userId = req.user.userId;

      const preferences = await User.savePreferences(userId, {
        language,
        level,
        reason,
        dailyGoal
      });

      res.json({
        message: 'Preferences saved successfully',
        preferences
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
  }
};

module.exports = userController;
