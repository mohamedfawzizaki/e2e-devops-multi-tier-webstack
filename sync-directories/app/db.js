const mysql = require('mysql2/promise');

const baseConfig = {
  host: '192.168.56.12',
  port: 3306,
  user: 'mo',
  password: '29112000',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 20000
};

const dbName = 'backend';

const dbConfig = {
  ...baseConfig,
  database: dbName
};

async function initDb() {
  // Step 1: Connect without specifying a DB to create the DB if needed
  const connection = await mysql.createConnection(baseConfig);
  await connection.execute(`CREATE DATABASE IF NOT EXISTS \`${dbName}\``);
  await connection.end();

  // Step 2: Now connect with the DB specified
  const dbConnection = await mysql.createConnection(dbConfig);
  await dbConnection.execute(`
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(100) NOT NULL UNIQUE
    )
  `);
  await dbConnection.end();
}

async function getUserOrInsert(email = 'johndoe@example.com', name = 'johndoe') {
  const connection = await mysql.createConnection(dbConfig);

  try {
    const [existingUsers] = await connection.execute(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (existingUsers.length === 0) {
      const [insertResult] = await connection.execute(
        'INSERT INTO users (name, email) VALUES (?, ?)',
        [name, email]
      );

      const [newUserRows] = await connection.execute(
        'SELECT * FROM users WHERE id = ?',
        [insertResult.insertId]
      );
      return newUserRows[0];
    } else {
      return existingUsers[0];
    }
  } finally {
    await connection.end();
  }
}

module.exports = { initDb, getUserOrInsert };
