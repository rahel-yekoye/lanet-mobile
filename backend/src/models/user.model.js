const bcrypt = require('bcryptjs');
const db = require('../config/db');

const User = {
  async create({ name, email, password, language, level, reason, dailyGoal }) {
    try {
      console.log('Hashing password...');
      const hashedPassword = await bcrypt.hash(password, 10);
      console.log('Password hashed, creating user...');
      
      const result = await db.query(
        'INSERT INTO users (name, email, password_hash, language, level, reason, daily_goal) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, name, email, language, level, reason, daily_goal, created_at',
        [name, email, hashedPassword, language, level, reason, dailyGoal]
      );
      
      console.log('User created successfully:', result.rows[0]);
      return result.rows[0];
    } catch (error) {
      console.error('Error in User.create:', error);
      throw error;
    }
  },

  async findByEmail(email) {
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    return result.rows[0];
  },

  async findById(id) {
    const result = await db.query('SELECT id, name, email, language, level, reason, daily_goal, created_at FROM users WHERE id = $1', [id]);
    return result.rows[0];
  },

  async updatePreferences(id, { language, level, reason, dailyGoal, name }) {
    const result = await db.query(
      `UPDATE users SET 
        name = COALESCE($1, name),
        language = COALESCE($2, language), 
        level = COALESCE($3, level), 
        reason = COALESCE($4, reason), 
        daily_goal = COALESCE($5, daily_goal)
      WHERE id = $6 
      RETURNING id, name, email, language, level, reason, daily_goal, created_at`,
      [name, language, level, reason, dailyGoal, id]
    );
    return result.rows[0];
  }
};

module.exports = User;