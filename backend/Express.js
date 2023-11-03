// Import required dependencies
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const cors = require('cors');
const app = express();
const port = 3000;
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// Generate a random secret key for JWT
const jwtSecret = crypto.randomBytes(64).toString('hex');
const jwtOptions = {
  expiresIn: '1h', // Token expiration time
};

app.use(express.json());

// Enable CORS to allow requests from any origin and restrict to POST requests
app.use(cors({
  origin: '*', 
  methods: 'POST',
}));

// Create a connection pool to the MySQL database
const db = mysql.createPool({
  host: 'btxppofwkgo3xl10tfwy-mysql.services.clever-cloud.com',
  user: 'ud86jc8auniwbfsm',
  password: 'ER0nIAbQy5qyAeSd4ZCV',
  database: 'btxppofwkgo3xl10tfwy',
});
let server; // Define the server variable at a higher scope

// Function to generate a random salt
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

// Route for user registration
app.post('/register', async (req, res) => {
  const { username, email, firstname, lastname, password } = req.body;

  // Check if the email or username is already in use
  const [existingUser] = await db.query(
    'SELECT * FROM User WHERE email = ? OR username = ?',
    [email, username]
  );

  if (existingUser.length > 0) {
    return res.status(400).json({ message: 'Email or username already in use' });
  }

  try {
    // Generate a random verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Generate a salt, hash the password, and store the user data in the database
    const salt = generateSalt();
    const hashedPassword = await bcrypt.hash(password + salt, 10);

    await db.query('INSERT INTO User (username, email, first_name, last_name, password_hash, salt, created_at, verification_code) VALUES (?,?,?,?,?,?,NOW(), ?)', [
      username,
      email,
      firstname,
      lastname,
      hashedPassword,
      salt,
      verificationCode,
    ]);

    // Send the verification code to the user's ProtonMail address
    sendVerificationEmail(email, verificationCode);

    res.json({ message: 'Registration successful' });
  } catch (error) {
    console.error('Error hashing password:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


// Route for user login
app.post('/login', async (req, res) => {
  const { email, password, verificationCode } = req.body;

  // Check if the user with the provided email exists
  const [user] = await db.query('SELECT * FROM User WHERE email = ?', [email]);

  if (user.length === 0) {
    return res.status(401).json({ message: 'Invalid email or password' });
  }

  // Check if the user's "active" attribute is set to 0
  if (user[0].active === 0) {
    // The account is not yet verified; prompt the user to enter the verification code
    if (verificationCode !== user[0].verification_code) {
      return res.status(401).json({ message: 'Invalid verification code' });
    }

    // Verification code is valid; update the "active" attribute to 1
    await db.query('UPDATE User SET active = 1 WHERE email = ?', [email]);
  }

  // Compare the provided password with the hashed password
  const hashedPassword = user[0].password_hash;
  const salt = user[0].salt;
  const passwordMatch = await bcrypt.compare(password + salt, hashedPassword);

  if (passwordMatch) {
    // Issue a JSON Web Token (JWT) upon successful login
    const token = jwt.sign({ userId: user[0].id }, jwtSecret, jwtOptions);

    // Fetch and include the user's data in the response
    const userData = user[0];

    res.json({ message: 'Login successful', token, user: userData });
  } else {
    res.status(401).json({ message: 'Invalid email or password' });
  }
});


// Route to fetch user profile with JWT authentication
app.get('/user/profile', authenticateToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.user.userId;

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

app.post('/verify', async (req, res) => {
  const { email, verificationCode } = req.body;

  // Check if the user with the provided email and verification code exists
  const [user] = await db.query('SELECT * FROM User WHERE email = ? AND verification_code = ?', [email, verificationCode]);

  if (user.length === 0) {
    return res.status(401).json({ message: 'Invalid verification code' });
  }

  // Check if the user is already active
  if (user[0].active === 1) {
    return res.status(400).json({ message: 'Account is already active' });
  }

  // Update the "active" field to mark the account as verified
  await db.query('UPDATE User SET active = 1 WHERE email = ?', [email]);

  res.json({ message: 'Account verified successfully' });
});

// Route to check the user's active status
app.post('/check-active', async (req, res) => {
  const { email } = req.body;

  // Check if the user with the provided email exists
  const [user] = await db.query('SELECT active FROM User WHERE email = ?', [email]);

  if (user.length === 0) {
    return res.status(404).json({ message: 'User not found' });
  }

  const isActive = user[0].active;

  res.json({ active: isActive });
});


// Route for health check
app.get('/health', (req, res) => {
  res.sendStatus(200); // Send a 200 OK response when the server is healthy
});

// Start the server and handle graceful shutdown on SIGINT signal
server = app.listen(port, () => {
  process.on('SIGINT', () => {
    console.log('Shutting down the server...');
    server.close(() => {
      console.log('Server has been shut down.');
      process.exit(0); // Exit the process gracefully
    });
  });
});

// Middleware to authenticate the user token
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

// Import the required nodemailer library
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'Outlook',
  auth: {
    user: 'payfriendz@outlook.de',
    pass: 'Frankfurt1!'
  }
});

// Define your email sending function
function sendVerificationEmail(to, code) {
  const mailOptions = {
    from: 'Payfriendz App',
    to: to,
    subject: 'Email Verification Code',
    text: `Your verification code is: ${code}`,
  }
  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.error('Error sending email:', error);
    } else {
      console.log('Email sent:', info.response);
    }
  });
}



