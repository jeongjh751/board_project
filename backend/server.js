require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pool = require('./config/database');
const authRoutes = require('./routes/authRoutes');
const authMiddleware = require('./middleware/authMiddleware');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// 인증 라우트
app.use('/api/auth', authRoutes);

// 게시글 목록 조회 (인증 필요 없음)
app.get('/api/posts', async (req, res) => {
  try {
    console.log('게시글 조회 요청...');
    const result = await pool.query(
      `SELECT id, title, content, author, 
              TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at 
       FROM posts 
       ORDER BY created_at DESC`
    );
    
    console.log(`${result.rows.length}개의 게시글 조회 완료`);
    res.json(result.rows);
  } catch (err) {
    console.error('조회 오류:', err.message);
    res.status(500).json({ 
      error: '데이터 조회 실패',
      message: err.message 
    });
  }
});

// 게시글 작성 (인증 필요)
app.post('/api/posts', authMiddleware, async (req, res) => {
  try {
    const { title, content } = req.body;
    const author = req.user.username; // 토큰에서 가져온 사용자명
    
    if (!title || !content) {
      return res.status(400).json({ error: '제목과 내용을 입력하세요' });
    }
    
    console.log('게시글 작성:', { title, author });
    const result = await pool.query(
      `INSERT INTO posts (title, content, author) 
       VALUES ($1, $2, $3) 
       RETURNING id`,
      [title, content, author]
    );
    
    console.log(`게시글 작성 완료, ID: ${result.rows[0].id}`);
    res.status(201).json({ 
      id: result.rows[0].id,
      message: '게시글이 작성되었습니다' 
    });
  } catch (err) {
    console.error('작성 오류:', err.message);
    res.status(500).json({ 
      error: '게시글 작성 실패',
      message: err.message 
    });
  }
});

// 게시글 수정 (인증 필요)
app.put('/api/posts/:id', authMiddleware, async (req, res) => {
  try {
    const { title, content } = req.body;
    const { id } = req.params;
    
    if (!title || !content) {
      return res.status(400).json({ error: '제목과 내용을 입력하세요' });
    }
    
    console.log(`게시글 수정 요청, ID: ${id}`);
    const result = await pool.query(
      'UPDATE posts SET title = $1, content = $2 WHERE id = $3 RETURNING *',
      [title, content, id]
    );
    
    if (result.rowCount === 0) {
      return res.status(404).json({ error: '게시글을 찾을 수 없습니다' });
    }
    
    console.log('게시글 수정 완료');
    res.json({ 
      message: '게시글이 수정되었습니다',
      post: result.rows[0]
    });
  } catch (err) {
    console.error('수정 오류:', err.message);
    res.status(500).json({ 
      error: '게시글 수정 실패',
      message: err.message 
    });
  }
});

// 게시글 삭제 (인증 필요)
app.delete('/api/posts/:id', authMiddleware, async (req, res) => {
  try {
    console.log(`게시글 삭제 요청, ID: ${req.params.id}`);
    const result = await pool.query(
      'DELETE FROM posts WHERE id = $1',
      [req.params.id]
    );
    
    if (result.rowCount === 0) {
      return res.status(404).json({ error: '게시글을 찾을 수 없습니다' });
    }
    
    console.log('게시글 삭제 완료');
    res.json({ message: '게시글이 삭제되었습니다' });
  } catch (err) {
    console.error('삭제 오류:', err.message);
    res.status(500).json({ 
      error: '게시글 삭제 실패',
      message: err.message 
    });
  }
});

// 서버 시작
app.listen(PORT, () => {
  console.log('\n' + '='.repeat(50));
  console.log(`🚀 서버가 포트 ${PORT}에서 실행 중입니다`);
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log('='.repeat(50) + '\n');
});