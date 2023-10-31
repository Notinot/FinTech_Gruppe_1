const express = require('express');
const mysql = require('mysql2/promise'); // Import mysql2
const bcrypt = require('bcrypt');


const app = express();
const port = 3000;

// Parse JSON request bodies
app.use(express.json());

//allows client to access server resources (to display dishes etc.)
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', 'http://localhost:3000');
    next();
  });

  //apparently needed for post requests
app.use(cors());

// Configure the database connection
const db = mysql.createPool({
  host: 'https://btxppofwkgo3xl10tfwy-mysql.services.clever-cloud.com',
  user: 'ud86jc8auniwbfsm',
  password: 'ER0nIAbQy5qyAeSd4ZCV',
  database: 'btxppofwkgo3xl10tfwy',
});

app.post('/register', async (req, res) => {
    const { username, email, password } = req.body;
  
    // Check if the email and username are unique in the database
    const [existingUser] = await db.query(
      'SELECT * FROM users WHERE email = ? OR username = ?',
      [email, username]
    );
  
    if (existingUser.length > 0) {
      return res.status(400).json({ message: 'Email or username already in use' });
    }
  
    try {
      // Hash the user's password securely
      const hashedPassword = await bcrypt.hash(password, 10);
  
      // Insert the new user into the database
      await db.query('INSERT INTO users (username, email, password) VALUES (?, ?, ?)', [
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
