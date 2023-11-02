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
let server; // Define the server variable at a higher scope

function generateSalt() {
  const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+{}[]|:;<>,.?/~";
  let salt = "";
  const charsetLength = charset.length;

  for (let i = 0; i < 16; i++) {
    const randomNumber = Math.floor(Math.random() * charsetLength);
    salt += charset.charAt(randomNumber);
  }

  return salt;
}

app.post('/register', async (req, res) => {
  const { username, email,firstname,lastname, password } = req.body;

  const [existingUser] = await db.query(
    'SELECT * FROM User WHERE email = ? OR username = ?',
    [email, username]
  );

  if (existingUser.length > 0) {
    return res.status(400).json({ message: 'Email or username already in use' });
  }

  try {
    const salt = generateSalt()
    const hashedPassword = await bcrypt.hash(password+salt, 10);

    await db.query('INSERT INTO User (username, email, first_name, last_name,password_hash, salt, created_at) VALUES (?,?,?,?,?,?,NOW())', [
      username,
      email,
      firstname,
      lastname,
      hashedPassword,
      salt,
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
  const salt = user[0].salt;

  // Compare the provided password with the hashed password
  const passwordMatch = await bcrypt.compare(password+salt, hashedPassword);

  if (passwordMatch) {
    res.json({ message: 'Login successful' });
  } else {
    res.status(401).json({ message: 'Invalid email or password' });
  }
});

app.get('/health', (req, res) => {
  res.sendStatus(200); // Send a 200 OK response when the server is healthy
});
server = app.listen(port, () => {

// Gracefully shut down the server when SIGINT signal is received (e.g., Ctrl+C)
process.on('SIGINT', () => {
  console.log('Shutting down the server...');
  server.close(() => {
    console.log('Server has been shut down.');
    process.exit(0); // Exit the process gracefully
  });
});
});
