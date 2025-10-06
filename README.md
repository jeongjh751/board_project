# 게시판 프로젝트

Flutter + Node.js + PostgreSQL로 만든 게시판 앱

## 기능
- 회원가입 / 로그인 (JWT 인증)
- 게시글 작성, 수정, 삭제
- 게시글 목록 조회

## 기술 스택
**백엔드:**
- Node.js + Express
- PostgreSQL
- JWT 인증
- bcrypt 비밀번호 암호화

**프론트엔드:**
- Flutter

## 설치 및 실행

### 1. 환경 설정
`.env.example`을 참고해서 `.env` 파일을 만드세요.

### 2. 데이터베이스 설정
PostgreSQL에서 데이터베이스와 테이블을 생성하세요.
```sql
CREATE DATABASE board_db;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);