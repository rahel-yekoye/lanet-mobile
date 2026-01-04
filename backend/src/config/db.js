// backend/src/config/db.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Test the database connection
const connectToDatabase = async () => {
  try {
    const client = await pool.connect();
    console.log('Successfully connected to the database');
    client.release();
    return pool;
  } catch (error) {
    console.error('Error connecting to the database:', error);
    throw error;
  }
};

module.exports = {
  pool,
  connectToDatabase,
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(),
};