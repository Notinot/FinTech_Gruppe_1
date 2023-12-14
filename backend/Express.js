// Import required dependencies
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const cors = require('cors');
const app = express();
const port = 3000;
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const authenticateToken = require('./authenticateToken');
const config = require('./config');
const jwtSecret = config.jwtSecret;
const jwtOptions = {
  expiresIn: '5h', // Token expiration time
};

app.use(express.json());
// Middleware to extract and verify JWT

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

// Forgot Password
app.post('/forgotpassword', async (req, res) =>{

    const {email} = req.body;

    // Check if the user with the provided email exists
    const [user] = await db.query('SELECT * FROM User WHERE email = ?', [email]);

    if (user.length === 0) {
        return res.status(401).json({ message: 'Invalid email' });
    }

    try {
        // Generate a random verification code
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

        await db.query('UPDATE User SET verification_code = ? WHERE email = ?', [verificationCode, email])

        // Send verification code
        sendVerificationEmail(email, verificationCode);

        res.json({ message: 'Verification code sent successfully', email });
    }
    catch{

      console.error('Error sending verification code');
      res.status(500).json({ message: 'Internal server error' });
    }
  }
)


app.post('/changepassword', async (req, res) => {

  const{email, newPassword, verificationCode} = req.body;

  const [user] = await db.query('SELECT * FROM User WHERE email = ?', [email]);


  // Hash new Password
  const salt = generateSalt();
  const hashedPassword = await bcrypt.hash(newPassword + salt, 10)

  // Compare
  const passwordMatch = await bcrypt.compare(newPassword + user[0].salt, user[0].password_hash);

  if (verificationCode != user[0].verification_code) {

      return res.status(401).json({ message: 'Invalid verification code' });
  }
  else if (passwordMatch){

        return res.status(400).json({ message: 'Old password can not be new password' });
  }
  
  try{

    await db.query('UPDATE User SET password_hash = ?, salt = ?, verification_code = NULL WHERE email = ?', [hashedPassword, salt, email]);
    return res.json({ message: 'Account verified successfully' });

  }catch{

    console.error('Error in verification process');
    res.status(500).json({ message: 'Internal server error' });
  }
  
})


// Route for user registration
app.post('/register', async (req, res) => {
  const { username, email, firstname, lastname, password,picture } = req.body;

   pictureData = null;
  if(picture != null){
  pictureData = Buffer.from(picture, 'base64');}

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
    
    await db.query('INSERT INTO User (username, email, first_name, last_name, password_hash, salt, created_at, verification_code,picture) VALUES (?,?,?,?,?,?,NOW(), ?,?)', [
      username,
      email,
      firstname,
      lastname,
      hashedPassword,
      salt,
      verificationCode,
      pictureData
    ]);

    // Send the verification code to the user's email address
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
    await db.query('UPDATE User SET active = 1, verification_code = NULL WHERE email = ?', [email]);
  }

  // Compare the provided password with the hashed password
  const hashedPassword = user[0].password_hash;
  const salt = user[0].salt;
  const passwordMatch = await bcrypt.compare(password + salt, hashedPassword);

  if (passwordMatch) {
    // Issue a JSON Web Token (JWT) upon successful login
    const token = jwt.sign({ userId: user[0].user_id }, jwtSecret, jwtOptions);
    // Save user_id in a variable
    const user_id = user[0].user_id;
    console.log('User object:', user);
    console.log('User ID:', user[0].user_id);

    // Fetch and include the user's data in the response
    const userData = user[0];

    // Send the token and the user_id to the frontend
    res.json({ message: 'Login successful', token, user_id });
  } else {
    res.status(401).json({ message: 'Invalid email or password' });
  }
});


// Route to fetch user profile with JWT authentication
app.get('/user/profile', authenticateToken, async (req, res) => {
  try {
    console.log('Token:', req.headers['authorization']);
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId:', userId);
    // Fetch the user's profile data from the database based on the user ID
    const [userData] = await db.query('SELECT * FROM User WHERE user_id = ?', [userId]);

    if (userData.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    //console.log('/user/profile userData:', userData);
    // Send the user's profile data as the response
    res.json({ user: userData[0] });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

//get friends of specific user
//returns JSON with: 
app.get('/friends/:user_id', async(req, res) => {
  const user_id = req.params.user_id;  
const query =
`SELECT
CASE
    WHEN f.requester_id = ? THEN u_addressee.username
    WHEN f.addressee_id = ? THEN u_requester.username
END AS friend_username,
CASE
    WHEN f.requester_id = ? THEN u_addressee.first_name
    WHEN f.addressee_id = ? THEN u_requester.first_name
END AS friend_first_name,
CASE
    WHEN f.requester_id = ? THEN u_addressee.last_name
    WHEN f.addressee_id = ? THEN u_requester.last_name
END AS friend_last_name,
CASE
    WHEN f.requester_id = ? THEN u_addressee.picture
    WHEN f.addressee_id = ? THEN u_requester.picture
END AS friend_picture
FROM
Friendship f
JOIN
User u_requester ON f.requester_id = u_requester.user_id
JOIN
User u_addressee ON f.addressee_id = u_addressee.user_id
WHERE
f.status = 'accepted'
AND (f.requester_id = ? OR f.addressee_id = ?);
`;
const [friends] = await db.query(query, [user_id, user_id, user_id, user_id, user_id, user_id, user_id, user_id,user_id, user_id]);
res.json({friends}); 
});

//get pending friend requests of specific user
//returns JSON with: 
app.get('/friends/pending/:user_id', async(req, res) => {
  const user_id = req.params.user_id;  
const query =
`SELECT  f.requester_id, u.username, u.first_name, u.last_name, u.picture
FROM Friendship f
JOIN User u ON f.requester_id = u.user_id
WHERE f.addressee_id = ? AND f.status = 'pending';
`;
const [pendingFriends] = await db.query(query, [user_id]);
  res.json({pendingFriends}); //!
});

//check if user is already friends with another user by userID of other user and user_id of user from token. use JWT authentication. returns boolean
app.get('/checkIfFriends',authenticateToken, async(req, res) => {
  const user_id = req.user.userId;
  const {friendId} = req.body;
  const query =
  `SELECT * FROM Friendship WHERE (requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?)`;
  const [friends] = await db.query(query, [user_id, friendId, friendId, user_id]);
  console.log("user id and friend id",user_id,friendId);
  console.log("friends",friends);
  if(friends[0] == null){
    res.json({isFriend: false});
  }else{
    res.json({isFriend: true});
  }
});


//handle friend request
/*
Receives: boolean value whether request was accepted or declined
          ID of person who was accepted or declined
*/
app.post('/friends/request/:user_id', async (req, res) => {
  const user_id = req.params.user_id;  
  const{friendId, accepted} = req.body;
  var query = '';
  if(accepted){
     query =
    `Update Friendship
     Set status = 'accepted' 
     WHERE addressee_id = ? AND requester_id = ? ` ;  
  }else{
     query =
    `Update Friendship
     Set status = 'declined' 
     WHERE addressee_id = ? AND requester_id = ? ` ;
  }
 console.log(query);
   const [friendRequest] = await db.query(query, [user_id, friendId]);
   res.json({friendRequest});
    });

  //add friend (sending friend request)
      //names of routes are kinda misleading
  app.post('/friends/add/:user_id', async (req, res) => {
    const user_id = req.params.user_id;  
    const{friendUsername} = req.body;
  
    //get user_id from username
    const [temp] = await db.query('SELECT user_id FROM User WHERE username = ?', [friendUsername]);

    //checks if username even exists
    if(temp[0] != undefined){
      const friendId = temp[0].user_id; 
    //check if users are already friends
    const[friends] = await db.query(
      ` 
      SELECT * 
      FROM Friendship 
      WHERE (requester_id = ? AND addressee_id = ?)
      OR    (requester_id = ? AND addressee_id = ?)
      `
      ,[user_id,friendId,
        friendId,user_id]);

      //when they are not already friends
      if(friends[0] == null){
        const query = `
      INSERT INTO Friendship 
      (requester_id, addressee_id, status, request_time) 
      VALUES (?, ?, ?, NOW())`;
       const [addingFriend] = await db.query(query, [user_id, friendId, 'pending']);
       res.status(200).json({addingFriend});
      }else{
        //res.status(500).json({message: 'Cannot add User'});
        res.status(500).json('Cannot add User');
      }
    }else{
      //res.status(500).json({message: 'Username not found'});
      res.status(500).json('Username not found');
    }
      });
     

  //removing friend
  app.delete('/friends/:user_id', async (req, res) => {
    const user_id = req.params.user_id;
    const{friendId} = req.body;

    const query = `
    DELETE FROM Friendship
    WHERE (requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?)
    `;

    try {
        const [deletingFriend] = await db.query(query, [user_id, friendId, friend_id, user_id]);

        res.json({ success: true, message: 'Friend deleted successfully.' });
    } catch (error) {
        console.error('Error deleting friend:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});


/*
--add BLOCKED functionality? 

*/

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

//delete user
app.post('/delete_user', async (req, res) => {
  const{userid} = req.body;
  try{
    const [userInfo] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [userid]);
    const { username, email } = userInfo[0];
    sendDeletionEmail(email, username);
    await db.query('UPDATE User SET active = 0, username = null,email = null, Picture = null,password_hash = null WHERE user_id = ?', [userid]);
    await db.query('DELETE FROM Friendship WHERE (requester_id = ? ) OR (addressee_id = ?)'
      , [userid, userid]);
    
    res.json({message : 'Account deleted'});}
  catch (error) {
    console.error('User deletion failed. Error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


//editing user
app.post('/edit_user', async (req, res) => {
  const { email, firstname, lastname,new_password, userid,pw_change,picture } = req.body;
  emailChange = false;

  let pictureData = null;
  if (picture != null) {
    pictureData = Buffer.from(picture, 'base64');
  }

  // Check if the user exists based on the provided user_id
   [existingUser] = await db.query('SELECT * FROM User WHERE user_id = ?', [userid]);
  console.log(existingUser);

  if (existingUser.length === 0) {
    return res.status(404).json({ message: 'User not found' });
  }

  

  const [existingInfo] = await db.query(
    'SELECT * FROM User WHERE email = ?',
    [email]
  );

  /*const [existingUsername] = await db.query('SELECT * FROM User WHERE username = ? AND user_id != ?', [username, userid]);
  if (existingUsername.length > 0) {
    return res.status(402).json({ message: 'Username already in use' });
  }
*/
  // Check if the new email is already in use by a different user
  const [existingEmail] = await db.query('SELECT * FROM User WHERE email = ? AND user_id != ?', [email, userid]);
  if (existingEmail.length > 0) {
    return res.status(403).json({ message: 'Email already in use' });
  }

  
  const samePassword = await bcrypt.compare(new_password + existingUser[0].salt, existingUser[0].password_hash);
  if (samePassword) {
    return res.status(406).json({ message: 'Your new password cannot be your old password' });
  }

  console.log(new_password)
  console.log(samePassword)

  try {
    updateData = [email, firstname, lastname,pictureData,userid];
    query = 'UPDATE User SET email=?, first_name=?, last_name=?, picture=? WHERE user_id = ? ';

    if(pw_change == true){
      
      const salt = generateSalt();
     const passwordHash = await bcrypt.hash(new_password + salt, 10);

     updateData = [email, firstname, lastname, passwordHash,salt, pictureData,userid];
     query = 'UPDATE User SET email=?, first_name=?, last_name=?, password_hash=?,salt = ?, picture=? WHERE user_id=?';
      
  }


    await db.query(query, updateData);
    [existingUser] = await db.query('SELECT * FROM User WHERE user_id = ?', [userid]);
    const token = jwt.sign({ userid : existingUser[0].userid}, jwtSecret, jwtOptions);

    res.json({ message: 'Profile updated successfully',token,user: existingUser[0] });
  }
   catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Internal server error',error: error.message });
    console.log('Received data:', req.body);
  }
});

app.post('/edit_user/verify', async (req, res) => {
  const { userid, verificationCode } = req.body;
  console.log('Received userid:', userid);
  console.log('Received verificationCode:', verificationCode);
  
  
  const [code] = await db.query('SELECT verification_code FROM User WHERE user_id = ?', [userid]);
console.log("needed input:",code[0].verification_code);

  if(code[0].verification_code === verificationCode.trim()){
    res.json({ message: 'Verification succeeded' });
  }
  else{
    res.status(411).json({ message: 'Wrong verification code' })
  }
}
);

app.post('/edit_user/send_code', async (req, res) => {
  const {userid,email} = req.body;
   code = Math.floor(100000 + Math.random() * 900000).toString();
   query = 'UPDATE User SET verification_code = ? WHERE user_id = ? ';
   updateData = [code,userid];
   await db.query(query, updateData);
   sendVerificationEmail(email,code);
   console.log(code);
   res.json({ message: 'Email sent' });
  }
   );

app.post('/verifyPassword', async (req, res) => {
  try {
    const { userid, password } = req.body;
    console.log(userid)
    console.log(password)
    // Check if the user with the provided email exists
    const [user] = await db.query('SELECT * FROM User WHERE user_id = ?', [userid]);

    if (user.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Compare the provided password with the hashed password
    const hashedPassword = user[0].password_hash;
    const salt = user[0].salt;
    const passwordMatch = await bcrypt.compare(password + salt, hashedPassword);

    if (passwordMatch) {
      res.json({ message: 'Password is correct' });
    } else {
      res.status(401).json({ message: 'Incorrect password' });
    }
  } catch (error) {
    console.error('Error checking password:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Route to verify Password with JWT authentication
app.post('/verifyPasswort_Token', authenticateToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId:', userId);

    // Extract the password from the request body
    const { password } = req.body;

    // Check if the user with the provided email exists
    const [user] = await db.query('SELECT * FROM User WHERE user_id = ?', [userId]);

    if (user.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Compare the provided password with the hashed password
    const hashedPassword = user[0].password_hash;
    const salt = user[0].salt;
    const passwordMatch = await bcrypt.compare(password + salt, hashedPassword);

    if (passwordMatch) {
      res.json({ message: 'Password is correct' });
    } else {
      res.status(401).json({ message: 'Incorrect password' });
    }
  } catch (error) {
    console.error('Error checking password:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

//Route to get the users balance with JWT authentication
app.get('/balance', authenticateToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId:', userId);

    // Fetch the user's balance from the database based on the user ID
    const balance = await getBalance(userId);

    // Send the user's balance as the response
    res.json({ balance });
  } catch (error) {
    console.error('Error fetching balance:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Route to add money to the user's balance with JWT authentication
app.post('/addMoney', authenticateToken, async (req, res) => {
  try {
    console.log('addMoney request body:', req.body);
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId in /addmoney:', userId);

    // Extract the amount from the request body
    const { amount } = req.body;

    // Validate input
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid input' });
    }

    // Update the user's balance
    await updateBalance(userId, +amount);

    //insert as transaction into database. sender and receiver are the same. processed = 3 means it is a deposit, message is empty
    await db.query('INSERT INTO Transaction (sender_id, receiver_id, amount, transaction_type, created_at, message, processed) VALUES (?, ?, ?, ?, NOW(), ?, 3)', 
    [userId, userId, amount, 'Deposit', '']);
    // Send true as the response
    res.json({ success: true });
    
    console.log('Money added successfully');
  } catch (error) {
    console.error('Error adding money:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
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


// Route for sending money with JWT authentication
app.post('/send-money', authenticateToken, async (req, res) => {
  try {
    // Extract the authenticated user ID from the request
    const senderId = req.user.userId;
    console.log('senderId:', senderId);

    // Extract other information from the request body
    const { recipient, amount, message, event_id } = req.body;

    // Validate input
    if (!recipient || !amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid input' });
    }

    // Fetch recipient ID based on the recipient username or email
    const [recipientData] = await db.query('SELECT user_id FROM User WHERE username = ? OR email = ?', [recipient, recipient]);

    if (recipientData.length === 0) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    const recipientId = recipientData[0].user_id;

    // Insert transaction with message and event_id
    await db.query('INSERT INTO Transaction (sender_id, receiver_id, amount, transaction_type, created_at, message, processed, event_id) VALUES (?, ?, ?, ?, NOW(), ?, 1, ?)', [
      senderId,
      recipientId,
      amount,
      'Payment',
      message,
      event_id, // Assuming event_id is passed in the request body
    ]);

    // Update sender and recipient balances
    const senderBalance = await getBalance(senderId);

    if (senderBalance < amount) {
      return res.status(400).json({ message: 'Insufficient funds' });
    }

    const recipientBalance = await getBalance(recipientId);

    // Update balances in the database
    await updateBalance(senderId, -amount);
    await updateBalance(recipientId, +amount);

    res.json({ message: 'Money transfer successful' });
  } catch (error) {
    console.error('Error transferring money:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Route for requesting money with JWT authentication
app.post('/request-money', authenticateToken, async (req, res) => {
  try {
    // Extract the authenticated user ID from the request
    const requesterId = req.user.userId;
    console.log('requesterId:', requesterId);

    // Extract other information from the request body
    const { recipient, amount, message } = req.body;

    // Validate input
    if (!recipient || !amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid input' });
    }

    // Fetch recipient ID based on the recipient username or email
    const [recipientData] = await db.query('SELECT user_id FROM User WHERE username = ? OR email = ?', [recipient, recipient]);

    if (recipientData.length === 0) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    const recipientId = recipientData[0].user_id;

    // Insert transaction with message and set transaction_type to "Request"
    await db.query('INSERT INTO Transaction (sender_id, receiver_id, amount, transaction_type, created_at, message, processed) VALUES (?, ?, ?, ?, NOW(), ?, 0)', [
      requesterId,
      recipientId,
      amount,
      'Request',
      message,
    ]);

    res.json({ message: 'Money request sent successfully' });
  } catch (error) {
    console.error('Error requesting money:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Route to fetch transactions with JWT authentication
app.get('/transactions', authenticateToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId:', userId);

    // Fetch the user's transaction history from the database based on the user ID
    const transactions = await db.query(`
      SELECT 
        Transaction.*, 
        sender.username AS sender_username, 
        receiver.username AS receiver_username 
      FROM 
        Transaction 
      LEFT JOIN 
        User AS sender ON Transaction.sender_id = sender.user_id 
      LEFT JOIN 
        User AS receiver ON Transaction.receiver_id = receiver.user_id 
      WHERE 
        sender_id = ? OR receiver_id = ?
    `, [userId, userId]);

    //console.log('transactions:', transactions);

    // Send the user's transaction history as the response
    res.json(transactions);
  } catch (error) {
    console.error('Error fetching transactions:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

//Route to accept or decline a transaction Request with JWT authentication
app.post('/transactions/:transactionId', authenticateToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId:', userId);
    // Get the transaction ID from the request parameters
    const transactionId = req.params.transactionId;
    console.log('transactionId:', transactionId);
    // Extract the action from the request body
    const { action } = req.body;
    console.log('action:', action);
    // Validate input
    if (!action || (action !== 'accept' && action !== 'decline')) {
      return res.status(400).json({ message: 'Invalid input' });
    }

    // Fetch the transaction from the database based on the transaction ID
    const [transactionData] = await db.query('SELECT * FROM Transaction WHERE transaction_id = ?', [transactionId]);
    console.log('transactionData:', transactionData);
    if (transactionData.length === 0) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    const transaction = transactionData[0];

    // Check if the transaction has already been processed
    if (transaction.processed === 1) {
      return res.status(400).json({ message: 'Transaction has already been processed' });
    }

    // Check if the user is the recipient of the transaction
    if (transaction.receiver_id !== userId) {
      return res.status(401).json({ message: 'You are not authorized to perform this action' });
    }

    // Handle the transaction based on the action

    if (action === 'accept') {

      //check if user has enough money
      const senderBalance = await getBalance(transaction.receiver_id);
      if (senderBalance < transaction.amount) {
        return res.status(400).json({ message: 'Insufficient funds' });
      }
      
      // Update the transaction status to "accepted"
      await db.query('UPDATE Transaction SET processed = 1 WHERE transaction_id = ?', [transactionId]);

    
      // Update balances in the database
      await updateBalance(transaction.sender_id, +transaction.amount);
      await updateBalance(transaction.receiver_id, -transaction.amount);

      res.json({ message: 'Transaction accepted successfully' });
    }

    if (action === 'decline') {
      // Update the transaction status to "declined"
      await db.query('UPDATE Transaction SET processed = 2 WHERE transaction_id = ?', [transactionId]);

      res.json({ message: 'Transaction declined successfully' });
    }
  } catch (error) {
    console.error('Error accepting transaction:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
}
);


// Fetch Events
app.post('/events', authenticateToken, async (req, res) => {

    const senderId = req.user.userID;
    console.log('senderId: ', senderId);

    try{

        const fetchEvents = await db.query('SELECT * FROM Event WHERE creator_id = ?', [sender_id]);
        res.json(fetchEvents);

    } catch (error) {
         console.error('Error fetching events:', error);
         res.status(500).json({ message: 'Internal server error' });
       }

});


// Create Event
app.post('/create-event', authenticateToken, async (req, res) => {

  let eventId;

  try {
    const senderId = req.user.userId;
    console.log('senderId: ', senderId);


    const { category, title, description, max_participants, datetime_event, country, city, street, zipcode, price, recurrence_type } = req.body;

    // Validate input
    if (!category || !title || !description || !max_participants || !datetime_event ) {
      return res.status(400).json({ message: 'Invalid input' });
    }

    const address = `${street}, ${zipcode}, ${city}, ${country}`;

    // Validate address
    const NodeGeocoder = require('node-geocoder');
    const geocoder = NodeGeocoder({
      provider: 'opencage',
      apiKey: '7b209ea4bde844489fd0411dc1b53b9d'
    });

    const response = await geocoder.geocode(address);

    if (response && response.length > 0) {

      if (response[0].extra.confidence < 5) {

        console.log('Address does not exist');
        return res.status(401).json({ message: 'Address could not be validated' });
      }

      console.log(response);
      console.log('Address does exist');
    }

    // Create Event in Table
    const [eventQuery] = await db.query('INSERT INTO Event (category, title, description, max_participants, datetime_created, datetime_event, price, creator_id, recurrence_interval, recurrence_type) VALUES (?, ?, ?, ?, NOW(), ?, ?, ?, 0, ?)', [
      category,
      title,
      description,
      max_participants,
      datetime_event,
      price,
      senderId,
      recurrence_type,
      0
    ]);

    console.log(eventQuery);

    // Get Event ID
    const [eventIdQuery] = await db.query('SELECT * FROM Event WHERE creator_id = ? ORDER BY datetime_created DESC LIMIT 1', senderId);
    eventId = eventIdQuery[0].id;

    // Link Event -> Location
    const locationQuery = await db.query('INSERT INTO Location (event_id, country, city, street, zipcode) VALUES (?, ?, ?, ?, ?)', [eventId, country, city, street, zipcode]);
    console.log(locationQuery);

    // Link Event -> User_Event
    const user_eventQuery = await db.query('INSERT INTO User_Event (event_id, user_id) VALUES (?, ?)', [eventId, senderId]);
    console.log(user_eventQuery);

    res.status(200).json({ message: 'Event created successfully' });

  } catch (error) {

    console.error('Error creating event:', error);
    res.status(500).json({ message: 'Internal server error' });
  }

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







// Import the required nodemailer library
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'Gmail',
  auth: {
    user: 'payfriendzapp@gmail.com',
    pass: 'fmvnkjmnpdmuabcd'
  }
});

// Define your email sending function
function sendVerificationEmail(to, code) {
  const mailOptions = {
    from: 'Payfriendz App',
    to: to,
    subject: 'Payfriendz: Verification Code',
    html: `
    <html>
      <head>
        <style>
          /* Inline CSS for styling */
          .container {
            background-color: #f4f4f4;
            padding: 20px;
            border-radius: 5px;
            font-family: Arial, sans-serif;
            width: 80%;
            max-width: 600px;
            margin: 0 auto;
          }
          .header {
            background-color: #007bff;
            color: white;
            padding: 20px;
            border-top-left-radius: 5px;
            border-top-right-radius: 5px;
            text-align: center;
          }
          .header h1 {
            margin: 0;
          }
          .verification-box {
            background-color: #ffffff;
            padding: 20px;
            border-radius: 5px;
            margin-top: 20px;
            box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
          }
          .code {
            font-size: 24px;
            font-weight: bold;
            color: #007bff;
            text-align: center;
            margin-top: 20px;
          }
          .text-size-14 {
            font-size: 14px;
            color: #555;
            text-align: center;
          }
          .copyright {
            font-size: 10px;
            color: #777;
            text-align: center;
            margin-top: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Welcome to Payfriendz!</h1>
          </div>
          <div class="verification-box">
            <h2 class="code">Verification Code</h2>
            <p class="text-size-14">Your verification code is:</p>
            <p class="code">${code}</p>
          </div>
          <p class="copyright">
            &copy; Payfriendz 2023.  Payfriendz is a registered trademark of Payfriendz.
          </p>
        </div>
      </body>
    </html>
  `
    
    
  }
  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.error('Error sending email:', error);
    } else {
      console.log('Email sent:', info.response);
    }
  });
}

function sendDeletionEmail(to, username) {
  const mailOptions = {
    from: 'Payfriendz App',
    to: to,
    subject: 'Payfriendz: Your account was successfully deleted',
    html: `
    <html>
      <head>
        <style>
          /* Inline CSS for styling */
          .container {
            background-color: #f4f4f4;
            padding: 20px;
            border-radius: 5px;
            font-family: Arial, sans-serif;
            width: 80%;
            max-width: 600px;
            margin: 0 auto;
          }
          .header {
            background-color: #007bff;
            color: white;
            padding: 20px;
            border-top-left-radius: 5px;
            border-top-right-radius: 5px;
            text-align: center;
          }
          .header h1 {
            margin: 0;
          }
          .verification-box {
            background-color: #ffffff;
            padding: 20px;
            border-radius: 5px;
            margin-top: 20px;
            box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
          }
          .code {
            font-size: 24px;
            font-weight: bold;
            color: #007bff;
            text-align: center;
            margin-top: 20px;
          }
          .text-size-14 {
            font-size: 14px;
            color: #555;
            text-align: center;
          }
          .copyright {
            font-size: 10px;
            color: #777;
            text-align: center;
            margin-top: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Thank you for using Payfriendz!</h1>
          </div>
          <div class="del-box">
            <h2 class="code">Goodbye!</h2>
            <p class="text-size-14">Dear ${username},
              <br><br>
              We want to inform you that your account on Payfriendz has been successfully deleted. As a result, all of your personal data has been permanently removed from our database.
              <br><br>
              If you have any questions or concerns, please don't hesitate to contact us at <a href="mailto:payfriendzapp@gmail.com">payfriendzapp@gmail.com</a>.
              <br><br>
              Thank you for being a part of Payfriendz!
              <br><br>
              Best regards,
              <br><br>
              Your Payfriendz Team
            </p>
          </div>
          <p class="copyright">
            &copy; Payfriendz 2023.  Payfriendz is a registered trademark of Payfriendz.
          </p>
        </div>
      </body>
    </html>
  `
  }
  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.error('Error sending email:', error);
    } else {
      console.log('Email sent:', info.response);
    }
  });
}

// Function to update user balance
async function updateBalance(userId, amount) {
  try {
    // Fetch the existing balance
    const [userData] = await db.query('SELECT balance FROM User WHERE user_id = ?', [userId]);
    const currentBalance = parseFloat(userData[0].balance);

    // Update the balance accordingly
    const newBalance = currentBalance + amount;
    await db.query('UPDATE User SET balance = ? WHERE user_id = ?', [newBalance, userId]);

    return true; // Successfully updated balance
  } catch (error) {
    console.error('Error updating balance:', error);
    return false; // Failed to update balance
  }
}
// Function to get user balance
async function getBalance(userId) {
  try {
    // Fetch the user's balance
    const [userData] = await db.query('SELECT balance FROM User WHERE user_id = ?', [userId]);
    console.log('getBalance:');
    console.log('userId:', userId);
    console.log('userData:', userData);

    if (userData.length === 0) {
      console.log('User not found');
      return 0; // Return 0 if user not found
    }

    const balance = parseFloat(userData[0].balance);

    return balance;
  } catch (error) {
    console.error('Error fetching balance:', error);
    return 0; // Return 0 in case of an error
  }
}

//route to get the events the user is part of with JWT authentication
app.get('/events', authenticateToken, async (req, res) => {
  try {
    console.log('Token:', req.headers['authorization']);
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId:', userId);
    // Fetch the user's events from the database based on the user ID
    const [events] = await db.query(`
      SELECT 
        Event.*, 
        Location.*, 
        User_Event.user_id,
        User.username AS creator_username,
        User.picture AS creator_picture
      FROM
        Event 
      JOIN 
        Location ON Event.id = Location.event_id 
      JOIN 
        User_Event ON Event.id = User_Event.event_id 
      JOIN 
        User ON Event.creator_id = User.user_id 
      WHERE 
        User_Event.user_id = ?
    `, [userId]);
    console.log('events:', events);
    res.json(events);
  } catch (error) {
    console.error('Error fetching Events:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

