const bcrypt = require('bcryptjs');
const db = require('../config/db');

const User = {
  async create({ name, email, password }) {
    try {
      console.log('Hashing password...');
      const hashedPassword = await bcrypt.hash(password, 10);
      console.log('Password hashed, creating user...');
      
      const result = await db.query(
        'INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING id, name, email, created_at',
        [name, email, hashedPassword]
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
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    return result.rows[0];
  }
};

module.exports = User;