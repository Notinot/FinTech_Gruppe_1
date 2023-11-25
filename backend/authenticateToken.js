// authenticateToken.js

const jwt = require('jsonwebtoken');
const config = require('./config');

const jwtSecret = config.jwtSecret;

function authenticateToken(req, res, next) {
  // Extract the token from the Authorization header
  const authHeader = req.headers['authorization'];

  // Check if the token is provided
  if (!authHeader) {
    return res.status(401).json({ message: 'Authorization header missing' });
  }

  const token = authHeader.split(' ')[1];

  // Verify the token
  jwt.verify(token, jwtSecret, (err, decoded) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid token' });
    }
    // Set the user ID in the request object
    req.user = { userId: decoded.userId }; // Fix the property name
    console.log('Token Authenticated - User: ', req.user); // Log the user information
    next();
  });
}

module.exports = authenticateToken;
