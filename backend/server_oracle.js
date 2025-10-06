const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
const bodyParser = require('body-parser');

console.log('Oracle Instant Client 초기화 시도...');
console.log('경로: C:\\oracle\\instantclient_21_13');

try {
  oracledb.initOracleClient({ libDir: 'C:\\oracle\\instantclient_21_13' });
  console.log('✅ Oracle Instant Client (Thick mode) 초기화 성공!');
} catch (err) {
  console.error('❌ initOracleClient 실패:', err.message);
  process.exit(1);
}

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

const dbConfig = {
  user: 'jjh',
  password: '1234',
  connectString: 'localhost:1521/XE'
};

// 게시글 목록 조회
app.get('/api/posts', async (req, res) => {
  let connection;
  try {
    console.log('게시글 조회 요청...');
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(
      `SELECT id, title, 
              DBMS_LOB.SUBSTR(content, 4000, 1) as content,
              author, 
              TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at 
       FROM posts 
       ORDER BY created_at DESC`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    
    // CLOB을 문자열로 변환
    const posts = result.rows.map(row => ({
      id: typeof row.ID === 'number' ? row.ID : parseInt(row.ID),
      title: String(row.TITLE || ''),
      content: String(row.CONTENT || ''),
      author: String(row.AUTHOR || ''),
      created_at: String(row.CREATED_AT || '')
    }));
    
    console.log(`${posts.length}개의 게시글 조회 완료`);
    console.log('첫 번째 게시글:', JSON.stringify(posts[0]));
    res.json(posts);
  } catch (err) {
    console.error('조회 오류:', err.message);
    res.status(500).json({ 
      error: '데이터 조회 실패',
      message: err.message
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
});

// 게시글 작성
app.post('/api/posts', async (req, res) => {
  let connection;
  try {
    const { title, content, author } = req.body;
    
    if (!title || !content || !author) {
      return res.status(400).json({ error: '필수 항목을 입력하세요' });
    }
    
    console.log('게시글 작성:', { title, author });
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(
      `INSERT INTO posts (id, title, content, author) 
       VALUES (posts_seq.NEXTVAL, :title, :content, :author)
       RETURNING id INTO :id`,
      {
        title,
        content,
        author,
        id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
      },
      { autoCommit: true }
    );
    
    const newId = result.outBinds.id[0];
    console.log(`게시글 작성 완료, ID: ${newId}`);
    
    res.status(201).json({ 
      id: newId,
      message: '게시글이 작성되었습니다' 
    });
  } catch (err) {
    console.error('작성 오류:', err.message);
    res.status(500).json({ 
      error: '게시글 작성 실패',
      message: err.message 
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
});

// 게시글 삭제
app.delete('/api/posts/:id', async (req, res) => {
  let connection;
  try {
    const postId = req.params.id;
    console.log(`게시글 삭제 요청, ID: ${postId}`);
    
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(
      `DELETE FROM posts WHERE id = :id`,
      [postId],
      { autoCommit: true }
    );
    
    if (result.rowsAffected === 0) {
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
  } finally {
    if (connection) {
      await connection.close();
    }
  }
});

// 서버 시작
app.listen(PORT, async () => {
  console.log('\n' + '='.repeat(50));
  console.log(`🚀 서버가 포트 ${PORT}에서 실행 중입니다`);
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log('='.repeat(50));
  
  try {
    console.log('\n📊 Oracle DB 연결 테스트 중...');
    const connection = await oracledb.getConnection(dbConfig);
    console.log('✅ Oracle DB 연결 성공!');
    console.log(`   사용자: ${dbConfig.user}`);
    console.log(`   연결: ${dbConfig.connectString}`);
    await connection.close();
    console.log('\n서버 준비 완료!\n');
  } catch (err) {
    console.error('\n❌ DB 연결 실패:', err.message);
  }
});