const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const cors = require('cors');
const app = express();
const port = 3000;
const jwt = require('jsonwebtoken');
const jwtSecret = 'your-secret-key'; // Replace with your secret key
const jwtOptions = {
  expiresIn: '1h', // Token expiration time
};

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
    const token = jwt.sign({ userId: user[0].id }, jwtSecret, jwtOptions);

    // Fetch and include the user's data in the response
    const userData = user[0];

    res.json({ message: 'Login successful', token, user: userData });
  } else {
    res.status(401).json({ message: 'Invalid email or password' });
  }
});

app.get('/user/profile', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId; // Get the user ID from the authenticated token
    // Fetch the user's profile data from the database based on the user ID
    const [userData] = await db.query('SELECT * FROM User WHERE id = ?', [userId]);

    if (userData.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Send the user's profile data as the response
    res.json({ user: userData[0] });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ message: 'Internal server error' });
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
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Unauthorized' });
  }

  jwt.verify(token, jwtSecret, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Forbidden' });
    }
    req.user = user;
    next();
  });
}
