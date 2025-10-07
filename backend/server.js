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

// 게시글 목록 조회 (페이지네이션 추가)
app.get('/api/posts', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    console.log(`게시글 조회 요청... (페이지: ${page}, 개수: ${limit})`);

    // 전체 게시글 수 조회  
    const countResult = await pool.query('SELECT COUNT(*) FROM posts');
    const totalPosts = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(totalPosts / limit);

    // 페이지별 게시글 조회
    const result = await pool.query(
      `SELECT id, title, content, author, 
              TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at 
       FROM posts 
       ORDER BY created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    
    console.log(`${result.rows.length}개의 게시글 조회 완료 (전체: ${totalPosts})`);
    
    res.json({
      posts: result.rows,
      pagination: {
        currentPage: page,
        totalPages: totalPages,
        totalPosts: totalPosts,
        postsPerPage: limit,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1
      }
    });
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

// 게시글 수정 (본인만 가능)
app.put('/api/posts/:id', authMiddleware, async (req, res) => {
  try {
    const { title, content } = req.body;
    const { id } = req.params;
    const username = req.user.username; // 토큰에서 가져온 사용자명
    
    if (!title || !content) {
      return res.status(400).json({ error: '제목과 내용을 입력하세요' });
    }
    
    // 게시글 작성자 확인
    const postCheck = await pool.query(
      'SELECT author FROM posts WHERE id = $1',
      [id]
    );
    
    if (postCheck.rows.length === 0) {
      return res.status(404).json({ error: '게시글을 찾을 수 없습니다' });
    }
    
    // 작성자와 현재 사용자가 같은지 확인
    if (postCheck.rows[0].author !== username) {
      return res.status(403).json({ error: '자신의 게시글만 수정할 수 있습니다' });
    }
    
    console.log(`게시글 수정 요청, ID: ${id}, 작성자: ${username}`);
    const result = await pool.query(
      'UPDATE posts SET title = $1, content = $2 WHERE id = $3 RETURNING *',
      [title, content, id]
    );
    
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

// 게시글 삭제 (본인만 가능)
app.delete('/api/posts/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const username = req.user.username; // 토큰에서 가져온 사용자명
    
    // 게시글 작성자 확인
    const postCheck = await pool.query(
      'SELECT author FROM posts WHERE id = $1',
      [id]
    );
    
    if (postCheck.rows.length === 0) {
      return res.status(404).json({ error: '게시글을 찾을 수 없습니다' });
    }
    
    // 작성자와 현재 사용자가 같은지 확인
    if (postCheck.rows[0].author !== username) {
      return res.status(403).json({ error: '자신의 게시글만 삭제할 수 있습니다' });
    }
    
    console.log(`게시글 삭제 요청, ID: ${id}, 작성자: ${username}`);
    await pool.query('DELETE FROM posts WHERE id = $1', [id]);
    
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