const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    // Authorization 헤더에서 토큰 가져오기
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: '인증 토큰이 없습니다' });
    }

    const token = authHeader.split(' ')[1];

    // 토큰 검증
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');

    // 사용자 정보를 req 객체에 추가
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: '토큰이 만료되었습니다' });
    }
    return res.status(401).json({ error: '유효하지 않은 토큰입니다' });
  }
};

module.exports = authMiddleware;