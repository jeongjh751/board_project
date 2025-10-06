require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'jjh',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'board_db',
  password: process.env.DB_PASSWORD || '1234',
  port: process.env.DB_PORT || 5432,
});

// 연결 테스트
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ PostgreSQL 연결 실패:', err);
  } else {
    console.log('✅ PostgreSQL 연결 성공!');
  }
});

module.exports = pool;