const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(express.json());

// Allow requests from any origin and restrict to POST requests
app.use(cors({
  origin: '*', 
  methods: 'POST',
}));

const db = mysql.createPool({
  host: 'btxppofwkgo3xl10tfwy-mysql.services.clever-cloud.com',
  user: 'ud86jc8auniwbfsm',
  password: 'ER0nIAbQy5qyAeSd4ZCV',
  database: 'btxppofwkgo3xl10tfwy',
});

app.post('/register', async (req, res) => {
  const { username, email, password } = req.body;

  const [existingUser] = await db.query(
    'SELECT * FROM User WHERE email = ? OR username = ?',
    [email, username]
  );

  if (existingUser.length > 0) {
    return res.status(400).json({ message: 'Email or username already in use' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    await db.query('INSERT INTO User (username, email, password_hash, created_at) VALUES (?, ?, ?, NOW())', [
      username,
      email,
      hashedPassword,
    ]);

    res.json({ message: 'Registration successful' });
  } catch (error) {
    console.error('Error hashing password:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  // Check if the user with the provided email exists
  const [user] = await db.query('SELECT * FROM User WHERE email = ?', [email]);

  if (user.length === 0) {
    return res.status(401).json({ message: 'Invalid email or password' });
  }

  const hashedPassword = user[0].password_hash;

  // Compare the provided password with the hashed password
  const passwordMatch = await bcrypt.compare(password, hashedPassword);

  if (passwordMatch) {
    res.json({ message: 'Login successful' });
  } else {
    res.status(401).json({ message: 'Invalid email or password' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
