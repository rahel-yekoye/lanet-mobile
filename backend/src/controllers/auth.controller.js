const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const { JWT_SECRET, JWT_EXPIRES_IN } = process.env;

// Helper function to handle errors
const handleError = (res, error, context) => {
  console.error(`[${new Date().toISOString()}] Error in ${context}:`, error);
  
  const errorResponse = {
    message: `Error ${context}`,
    error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
  };

  if (error.name === 'ValidationError') {
    return res.status(400).json({ 
      ...errorResponse,
      message: 'Validation Error',
      details: error.errors 
    });
  }

  if (error.code === '23505') { // Unique violation
    return res.status(400).json({ 
      ...errorResponse,
      message: 'Email already exists' 
    });
  }

  res.status(500).json(errorResponse);
};

const authController = {
  async register(req, res) {
    try {
      console.log('Registration request:', { body: req.body });
      const { name, email, password } = req.body;

      // Input validation
      if (!name || !email || !password) {
        return res.status(400).json({ message: 'Name, email, and password are required' });
      }

      if (password.length < 6) {
        return res.status(400).json({ message: 'Password must be at least 6 characters' });
      }

      // Check if user exists
      const existingUser = await User.findByEmail(email);
      if (existingUser) {
        console.log('Registration failed: Email already in use', { email });
        return res.status(409).json({ message: 'Email already in use' });
      }

      // Create user
      const user = await User.create({ name, email, password, language: req.body.language, level: req.body.level, reason: req.body.reason, dailyGoal: req.body.dailyGoal });
      console.log('User created:', { userId: user.id, email: user.email });

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );

      // Don't send password hash in response
      const userResponse = {
        id: user.id,
        name: user.name,
        email: user.email,
        language: user.language,
        level: user.level,
        reason: user.reason,
        daily_goal: user.daily_goal,
        created_at: user.created_at
      };

      console.log('Registration successful:', { userId: user.id });
      res.status(201).json({
        message: 'User registered successfully',
        token,
        user: userResponse
      });

    } catch (error) {
      handleError(res, error, 'registering user');
    }
  },

  async login(req, res) {
    try {
      console.log('Login attempt:', { email: req.body.email });
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
      }

      const user = await User.findByEmail(email);
      if (!user) {
        console.log('Login failed: User not found', { email });
        return res.status(401).json({ message: 'Invalid credentials' });
      }

   // In the login function, update the password comparison:
const validPassword = await bcrypt.compare(password, user.password_hash);
if (!validPassword) {
  console.log('Login failed: Invalid password', { email });
  return res.status(401).json({ message: 'Invalid credentials' });
}
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );

      const userResponse = {
        id: user.id,
        name: user.name,
        email: user.email
      };

      console.log('Login successful:', { userId: user.id });
      res.json({
        message: 'Login successful',
        token,
        user: userResponse
      });

    } catch (error) {
      handleError(res, error, 'logging in');
    }
  },

  async getProfile(req, res) {
    try {
      console.log('Fetching profile:', { userId: req.user.userId });
      const user = await User.findById(req.user.userId);
      
      if (!user) {
        console.log('Profile not found:', { userId: req.user.userId });
        return res.status(404).json({ message: 'User not found' });
      }

      const userResponse = {
        id: user.id,
        name: user.name,
        email: user.email,
        language: user.language,
        level: user.level,
        reason: user.reason,
        daily_goal: user.daily_goal,
        created_at: user.created_at
      };

      res.json(userResponse);

    } catch (error) {
      handleError(res, error, 'fetching profile');
    }
  }
};

module.exports = authController;