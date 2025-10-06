const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

// 회원가입
exports.register = async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // 입력값 검증
    if (!username || !email || !password) {
      return res.status(400).json({ error: '모든 항목을 입력하세요' });
    }

    // 비밀번호 길이 검증
    if (password.length < 6) {
      return res.status(400).json({ error: '비밀번호는 6자 이상이어야 합니다' });
    }

    // 이메일 중복 확인
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR username = $2',
      [email, username]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: '이미 존재하는 이메일 또는 사용자명입니다' });
    }

    // 비밀번호 암호화
    const hashedPassword = await bcrypt.hash(password, 10);

    // 사용자 저장
    const result = await pool.query(
      'INSERT INTO users (username, email, password) VALUES ($1, $2, $3) RETURNING id, username, email',
      [username, email, hashedPassword]
    );

    const user = result.rows[0];

    // JWT 토큰 생성
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    console.log(`✅ 회원가입 성공: ${username}`);
    res.status(201).json({
      message: '회원가입 성공',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email
      }
    });
  } catch (err) {
    console.error('회원가입 오류:', err.message);
    res.status(500).json({ error: '회원가입 실패', message: err.message });
  }
};

// 로그인
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 입력값 검증
    if (!email || !password) {
      return res.status(400).json({ error: '이메일과 비밀번호를 입력하세요' });
    }

    // 사용자 조회
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: '이메일 또는 비밀번호가 잘못되었습니다' });
    }

    const user = result.rows[0];

    // 비밀번호 확인
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
      return res.status(401).json({ error: '이메일 또는 비밀번호가 잘못되었습니다' });
    }

    // JWT 토큰 생성
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    console.log(`✅ 로그인 성공: ${user.username}`);
    res.json({
      message: '로그인 성공',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email
      }
    });
  } catch (err) {
    console.error('로그인 오류:', err.message);
    res.status(500).json({ error: '로그인 실패', message: err.message });
  }
};