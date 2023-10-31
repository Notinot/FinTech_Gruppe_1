const express = require('express');
const mysql = require('mysql2/promise'); // Import mysql2
const bcrypt = require('bcrypt');
const cors = require('cors'); // Import the CORS middleware

const app = express();
const port = 3001; // Update the port number

// Parse JSON request bodies
app.use(express.json());

// Allow requests from your Flutter app (Change the origin to the correct URL)
app.use(cors({
  origin: 'http://localhost:3000', // Change this to the URL of your Flutter app
  methods: 'POST',
}));

// Configure the database connection
const db = mysql.createPool({
  host: 'btxppofwkgo3xl10tfwy-mysql.services.clever-cloud.com',
  user: 'ud86jc8auniwbfsm',
  password: 'ER0nIAbQy5qyAeSd4ZCV',
  database: 'btxppofwkgo3xl10tfwy',
});

app.post('/register', async (req, res) => {
    const { username, email, password } = req.body;
  
    // Check if the email and username are unique in the database
    const [existingUser] = await db.query(
      'SELECT * FROM User WHERE email = ? OR username = ?',
      [email, username]
    );
  
    if (existingUser.length > 0) {
      return res.status(400).json({ message: 'Email or username already in use' });
    }
  
    try {
      // Hash the user's password securely
      const hashedPassword = await bcrypt.hash(password, 10);
  
      // Insert the new user into the User table
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
  

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
