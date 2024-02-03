// Import required dependencies
const express = require('express');
const bodyParser = require('body-parser');
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


app.use(bodyParser.json({ limit: '50mb' }));
app.use(express.json());

// Middleware to extract and verify JWT

// Enable CORS to allow requests from any origin and restrict to POST requests
app.use(cors({
  origin: '*',
  methods: 'POST',
}));

// Create a connection pool to the MySQL database
const db = mysql.createPool({

  // connectionLimit: 5, //clevercloud only allows 5 connections at the same time
  /*host: 'btxppofwkgo3xl10tfwy-mysql.services.clever-cloud.com',
  user: 'ud86jc8auniwbfsm',
  password: 'ER0nIAbQy5qyAeSd4ZCV',
  database: 'btxppofwkgo3xl10tfwy',*/

  host: '80.130.111.254',
  user: 'payfriendz',
  password: 'payfriendz',
  database: 'Payfriendz',

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
const { stat } = require('fs');

const transporter = nodemailer.createTransport({
  service: 'Gmail',
  auth: {
    user: 'payfriendzapp@gmail.com',
    pass: 'fmvnkjmnpdmuabcd'
  }
});


// Forgot Password
app.post('/forgotpassword', async (req, res) => {

  const { email } = req.body;

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
  catch {

    console.error('Error sending verification code');
    res.status(500).json({ message: 'Internal server error' });
  }
}
)


app.post('/changepassword', async (req, res) => {

  const { email, newPassword, verificationCode } = req.body;

  const [user] = await db.query('SELECT * FROM User WHERE email = ?', [email]);


  // Hash new Password
  const salt = generateSalt();
  const hashedPassword = await bcrypt.hash(newPassword + salt, 10)

  // Compare
  const passwordMatch = await bcrypt.compare(newPassword + user[0].salt, user[0].password_hash);

  if (verificationCode != user[0].verification_code) {

    return res.status(401).json({ message: 'Invalid verification code' });
  }
  else if (passwordMatch) {

    return res.status(400).json({ message: 'Old password can not be new password' });
  }

  try {

    await db.query('UPDATE User SET password_hash = ?, salt = ?, verification_code = NULL WHERE email = ?', [hashedPassword, salt, email]);
    return res.json({ message: 'Account verified successfully' });

  } catch {

    console.error('Error in verification process');
    res.status(500).json({ message: 'Internal server error' });
  }

})


// Route for user registration
app.post('/register', async (req, res) => {
  const { username, email, firstname, lastname, password, picture } = req.body;

  pictureData = null;
  if (picture != null) {
    pictureData = Buffer.from(picture, 'base64');
  }

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

    //set wrong_password_attempts to 0
    await db.query('UPDATE User SET wrong_password_attempts = 0 WHERE email = ?', [email]);

    // Send the token and the user_id to the frontend
    res.json({ message: 'Login successful', token, user_id });

  } 

  // If the password does not match, set wrong_password_attempts + 1
  // If wrong_password_attempts > 3, set active = 0 and send email with verification code
  // if active is already 0 and wrong_password_attempts > 3, dont send another email
  else if (!passwordMatch){
    const wrong_password_attempts = user[0].wrong_password_attempts + 1;
    await db.query('UPDATE User SET wrong_password_attempts = ? WHERE email = ?', [wrong_password_attempts, email]);
    if (wrong_password_attempts > 3 && user[0].active === 1) {
      const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
      await db.query('UPDATE User SET active = 2, verification_code = ? WHERE email = ?', [verificationCode, email]);
      sendVerificationEmail(email, verificationCode);
      return res.status(402).json({ message: 'Account locked' });
    }
    else if (wrong_password_attempts > 3 && user[0].active === 2) {
      return res.status(402).json({ message: 'Account locked' });
    }
    else {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
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

// route to get profile picture of a user with JWT authentication and query parameter
app.get('/profilePicture', authenticateToken, async (req, res) => {
  try {
    const user_id = req.query.userId;
    console.log('user_id:', user_id);
    const query = `SELECT picture FROM User WHERE user_id = ?`;
    const [picture] = await db.query(query, [user_id]);
    console.log('picture:', picture);
    res.json({ picture: picture[0].picture });
  } catch (error) {
    console.error('Error fetching profile picture:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
}
);

app.post('/friendName', authenticateToken, async (req, res) => {
  const { friend: friendId } = req.body; // Rename the variable here
  try {
    const query = 'SELECT username FROM User WHERE user_id = ?';
    const [friend] = await db.query(query, friendId);
    console.log(friend[0].username);
    res.json({ friendname: friend[0].username });
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

///get friends of specific user (in JWT)
app.get('/friends', authenticateToken, async (req, res) => {
  try{
    const user_id = req.user.userId;
    const query =
      `SELECT
    request_time,
  CASE
      WHEN f.requester_id = ? THEN u_addressee.user_id
      WHEN f.addressee_id = ? THEN u_requester.user_id
  END AS friend_user_id,
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
    const [friends] = await db.query(query, [user_id, user_id, user_id, user_id, user_id, user_id, user_id, user_id, user_id, user_id, user_id, user_id]);
    res.json({ friends });

  }catch(error){
    console.error('Error fetching friends: ', error);
    res.status(500).json({message: 'Server: Error fetching friends'});
  }
});

//get pending friend requests of specific user
app.get('/friends/pending', authenticateToken,async (req, res) => {
  const user_id = req.user.userId;

  const query =
    `SELECT  f.requester_id, u.username, u.first_name, u.last_name, u.picture
FROM Friendship f
JOIN User u ON f.requester_id = u.user_id
WHERE f.addressee_id = ? AND f.status = 'pending';
`;
  const [pendingFriends] = await db.query(query, [user_id]);
  res.json({ pendingFriends }); //!
});



//handle friend request
/*
Receives: boolean value whether request was accepted or declined
          ID of person who was accepted or declined
*/
app.post('/friends/request/', authenticateToken, async (req, res) => {
  const user_id = req.user.userId;
  const { friendId, accepted } = req.body;
  var query = '';
  //hier noch überprüfen, dass Status auf "pending" ist?
  if (accepted) {
    query =
      `Update Friendship
     Set status = 'accepted' 
     WHERE addressee_id = ? AND requester_id = ? ` ;
  } else {
    query =
      `Update Friendship
     Set status = 'declined' 
     WHERE addressee_id = ? AND requester_id = ? ` ;
  }
  console.log(query);
  const [friendRequest] = await db.query(query, [user_id, friendId]);
  res.json({ friendRequest });
});

///add friend (sending friend request)
//names of routes are kinda misleading, maybe update
app.post('/friends/add',authenticateToken, async (req, res) => {
  const user_id = req.user.userId;
  const { friendUsername } = req.body;

  //get user_id from username
  const [temp] = await db.query('SELECT user_id FROM User WHERE username = ?', [friendUsername]);

  //checks if username even exists
  if (temp[0] != undefined && temp[0].user_id != user_id) {
    const friendId = temp[0].user_id;

    //check if users are already friends
    const [friends] = await db.query(
      ` 
          SELECT * 
          FROM Friendship 
          WHERE ((requester_id = ? AND addressee_id = ?)
          OR    (requester_id = ? AND addressee_id = ?)) 
          `  //AND status != 'declined'//added this line
      , [user_id, friendId,
        friendId, user_id]);

       //HIER DANN TESTEN OB status declined ist und wenn ja, Entry löschen bevor man einen neuen macht
      if(friends[0] !=null ){
        console.log('entry found');
        if(friends[0]['status']=='declined'){
          console.log('declined: deleting entry')
            //Delete entry
            await db.query(`
            DELETE FROM Friendship
            WHERE (requester_id = ? AND addressee_id = ?) 
                OR (requester_id = ? AND addressee_id = ?)
            `,[user_id, friendId,
              friendId, user_id]);
        }
      }
    //when they are not already friends
    if (friends[0] == null || friends[0]['status']=='declined') {
      const query = `
      INSERT INTO Friendship 
      (requester_id, addressee_id, status, request_time) 
      VALUES (?, ?, ?, NOW())`;
      const [addingFriend] = await db.query(query, [user_id, friendId, 'pending']);
      res.status(200).json({ addingFriend });
    } else {
      //res.status(500).json({message: 'Cannot add User'});
      res.status(500).json('Cannot add User');
    }
  } else {
    //res.status(500).json({message: 'Username not found'});
    res.status(500).json('Username not found'); //kommt auch wenn man versucht sich selbst zu adden
  }
});

//removing friend
app.delete('/friends/',authenticateToken, async (req, res) => {
  const user_id = req.user.userId;
  const { friendId } = req.body;

  const query = `
    DELETE FROM Friendship
    WHERE (requester_id = ? AND addressee_id = ?) 
        OR (requester_id = ? AND addressee_id = ?)
    `;

  try {
    const [deletingFriend] = await db.query(query, [user_id, friendId, friendId, user_id]);

    res.json({ success: true, message: 'Friend deleted successfully.' });
  } catch (error) {
    console.error('Error deleting friend:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

//blocking user
app.post('/friends/block', authenticateToken,async (req, res) => {
  const user_id = req.user.userId; //person who blocks - requester
  const { friendId } = req.body; //person who gets blocked - addressee

  //delete friends entry first
  const delQuery = `
  DELETE FROM Friendship
  WHERE (requester_id = ? AND addressee_id = ?) 
      OR (requester_id = ? AND addressee_id = ?)`;
  try {
    await db.query(delQuery, [user_id, friendId, friendId, user_id]);

  } catch (e) {
    console.error('Error deleting friends entry', e);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }

  //REQUESTER = PERSON WHO BLOCKs
  const blockQuery = `
      INSERT INTO Friendship 
      (requester_id, addressee_id, status, request_time) 
      VALUES (?, ?, ?, NOW())`;

  try {
    await db.query(blockQuery, [user_id, friendId, 'blocked']);

    res.json({ success: true, message: 'User blocked successfully.' });
  } catch (error) {
    console.error('Error blocking friend:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

//unblocking user
app.post('/friends/unblock',authenticateToken, async (req, res) => {
  const user_id = req.user.userId; //person who blocked - requester
  const { friendId } = req.body; //person who got blocked - addressee
  console.error(user_id);
  console.error(friendId);
  //delete entry
  const delQuery = `
  DELETE FROM Friendship
  WHERE (requester_id = ? AND addressee_id = ?) 
      OR (requester_id = ? AND addressee_id = ?)`; //and status = blocked
  try {
    await db.query(delQuery, [user_id, friendId, friendId, user_id]);

  } catch (e) {
    console.error('Error deleting friends entry', e);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

//get users that are blocked
app.get('/friends/block',authenticateToken, async (req, res) => {
  const user_id = req.user.userId; //person who blocked - requester

  const query =
    `SELECT  f.addressee_id, f.request_time, u.username, u.first_name, u.last_name, u.picture
  FROM Friendship f
  JOIN User u ON f.addressee_id = u.user_id
  WHERE f.requester_id = ? AND f.status = 'blocked';
  `;
  const [blockedUsers] = await db.query(query, [user_id]);
  res.json({ blockedUsers }); //!
});

//get users which contain String for suggestions in Searchbar
app.post('/users/', authenticateToken, async (req, res) => {
  const user_id = req.user.userId;
  const searchQuery = req.body.query;
  console.log('user_id: ', user_id, ' searchQuery: ', searchQuery);

  //get all users which match the query
  var query = `
    SELECT user_id, username, first_name, last_name, picture
    FROM User 
    WHERE user_id != ? AND
    username LIKE ?`;
  const [matchingUsers] = await db.query(query, [user_id, `%${searchQuery}%`]);

  //get all friendship entries of user 
  query = `SELECT requester_id, addressee_id, status, request_time FROM Friendship
    WHERE requester_id = ? OR
    addressee_id = ?`;
  const [friendshipEntries] = await db.query(query, [user_id, user_id]);

  //var responseFinal = JSON.parse(JSON.stringify(matchingUsers)); //hard copy of matchingUsers

  console.log('friendshipEntries', friendshipEntries);
  console.log('matchingUsers', matchingUsers);
  //console.log('copy: ', responseFinal);


  const matchingUsersFinal = matchingUsers.map(mUser => {
    const matchingEntry = friendshipEntries.find(fEntry => fEntry['requester_id'] == mUser['user_id'] || fEntry['addressee_id'] == mUser['user_id']);
    if (matchingEntry) {
      console.log('matchingEntry: ', matchingEntry);
      /* callerIsRequester = true

     pending - this user send the friend request -> show "pending" button /only other user can accept
     declined - other user declined thisUser -> dont show user at all/only other user can send again
     blocked - this user blocked other -> show "unblock" button
       */
      var callerIsRequester = true;
      //this means that THE OTHER USER is the requester in the friendship table
      if (matchingEntry['requester_id'] == mUser['user_id']) callerIsRequester = false;


      switch (matchingEntry['status']) {
        case 'accepted': //egal wie rum als friend anzeigen
          return { ...mUser, status: 'friend' , request_time: matchingEntry['request_time']};

        case 'declined':
          // if (callerIsRequester) {
          //   return { user_id: mUser['user_id'],username : mUser['username'], status: 'user' }; //caller got declined, so wie new user anzeigen
          // } else {
          // }
          return { user_id: mUser['user_id'],username : mUser['username'], status: 'user' };//so wie new user
        case 'blocked'://so oder so nicht anzeigen?
          return null;

        case 'pending':
          if (callerIsRequester) {
            return { user_id: mUser['user_id'],username : mUser['username'], status: 'requested' }; //anzeigen mit "send"
          } else {
            return null;
            //nicht anzeigen? this user must accept/decline in pendingFriends Screen
          }
        default:
          console.log('Entry status not known - ', entry);
      }
    } else {
      console.log(mUser, ' is not in Entries');
      return { user_id: mUser['user_id'],username : mUser['username'], status: 'user' };
    }
    //remove entries which are null or undefined
  }).filter(user => user != null && user != undefined);


  console.log('matchingUsersFinal: ', matchingUsersFinal);
  //for each dies das
  //1 von 4 types zurückgeben
  //friends, pending (incomming), pending (outcomming), blocked, declined, no entry


  res.json({ matchingUsersFinal });
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

//delete user
app.post('/delete_user', authenticateToken, async (req, res) => {
  const { userid } = req.body;
  try {
    const [userInfo] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [userid]);
    const { username, email } = userInfo[0];
    sendDeletionEmail(email, username);
    await db.query('UPDATE User SET active = 0, username = null,email = null, Picture = null,password_hash = null WHERE user_id = ?', [userid]);
    await db.query('DELETE FROM Friendship WHERE (requester_id = ? ) OR (addressee_id = ?)'
      , [userid, userid]);
      await db.query('DELETE FROM User_Event WHERE user_id = ? '
      , [userid]);

    res.json({ message: 'Account deleted' });
  }
  catch (error) {
    console.error('User deletion failed. Error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


//editing user
app.post('/edit_user', authenticateToken, async (req, res) => {
  const { email, firstname, lastname, new_password, userid, pw_change, picture } = req.body;
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
    updateData = [email, firstname, lastname, pictureData, userid];
    query = 'UPDATE User SET email=?, first_name=?, last_name=?, picture=? WHERE user_id = ? ';

    if (pw_change == true) {

      const salt = generateSalt();
      const passwordHash = await bcrypt.hash(new_password + salt, 10);

      updateData = [email, firstname, lastname, passwordHash, salt, pictureData, userid];
      query = 'UPDATE User SET email=?, first_name=?, last_name=?, password_hash=?,salt = ?, picture=? WHERE user_id=?';

    }


    await db.query(query, updateData);
    [existingUser] = await db.query('SELECT * FROM User WHERE user_id = ?', [userid]);
    const token = jwt.sign({ userid: existingUser[0].userid }, jwtSecret, jwtOptions);

    res.json({ message: 'Profile updated successfully', token, user: existingUser[0] });
  }
  catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
    console.log('Received data:', req.body);
  }
});

app.post('/edit_user/verify', authenticateToken, async (req, res) => {
  const { userid, verificationCode } = req.body;
  console.log('Received userid:', userid);
  console.log('Received verificationCode:', verificationCode);


  const [code] = await db.query('SELECT verification_code FROM User WHERE user_id = ?', [userid]);
  console.log("needed input:", code[0].verification_code);

  if (code[0].verification_code === verificationCode.trim()) {
    res.json({ message: 'Verification succeeded' });
  }
  else {
    res.status(411).json({ message: 'Wrong verification code' })
  }
}
);


app.post('/edit_user/send_code', authenticateToken, async (req, res) => {
  const { userid, email } = req.body;
  code = Math.floor(100000 + Math.random() * 900000).toString();
  query = 'UPDATE User SET verification_code = ? WHERE user_id = ? ';
  updateData = [code, userid];
  await db.query(query, updateData);
  sendVerificationEmail(email, code);
  console.log(code);
  res.json({ message: 'Email sent' });
}
);

app.post('/verifyPassword', authenticateToken, async (req, res) => {
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
  // Send the user's active status as the response
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

    //Fetch sender username and email
    const [senderData] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [senderId]);
    const senderUsername = senderData[0].username;
    const senderEmail = senderData[0].email;

    // Fetch recipient ID based on the recipient username or email
    const [recipientData] = await db.query('SELECT user_id, username, email FROM User WHERE username = ? OR email = ?', [recipient, recipient]);

    if (recipientData.length === 0) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    const recipientId = recipientData[0].user_id;
    const recipientUsername = recipientData[0].username;
    const recipientEmail = recipientData[0].email;

    const senderBalance = await getBalance(senderId);

    if (senderBalance < amount) {
        return res.status(400).json({ message: 'Insufficient funds' });
    }

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
    const recipientBalance = await getBalance(recipientId);

    // Update balances in the database
    await updateBalance(senderId, -amount);
    await updateBalance(recipientId, +amount);

    sendConfirmationEmail(senderEmail, senderUsername, recipientUsername, "Payment", amount, recipientEmail);

    res.json({ message: 'Money transfer successful' });
  } catch (error) {
    console.error('Error transferring money:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

//route for requesting money with JWT authentication and check users have each other blocked
app.post('/send-money-checkBlocked', authenticateToken, async (req, res) => {
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

    //check if users have each other blocked
    const [blocked] = await db.query('SELECT * FROM Friendship WHERE (requester_id = ? AND addressee_id = ?) AND status = "blocked" OR (requester_id = ? AND addressee_id = ?) AND status = "blocked"', [senderId, recipient, recipient, senderId]);
    if (blocked.length > 0) {
      return res.status(400).json({ message: 'Users have each other blocked' });
    }

    //Fetch sender username and email
    const [senderData] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [senderId]);
    const senderUsername = senderData[0].username;
    const senderEmail = senderData[0].email;

    // Fetch recipient ID based on the recipient username or email
    const [recipientData] = await db.query('SELECT user_id, username, email FROM User WHERE username = ? OR email = ?', [recipient, recipient]);

    if (recipientData.length === 0) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    const recipientId = recipientData[0].user_id;
    const recipientUsername = recipientData[0].username;
    const recipientEmail = recipientData[0].email;

    const senderBalance = await getBalance(senderId);

    if (senderBalance < amount) {
        return res.status(400).json({ message: 'Insufficient funds' });
    }

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
    const recipientBalance = await getBalance(recipientId);

    // Update balances in the database
    await updateBalance(senderId, -amount);
    await updateBalance(recipientId, +amount);

    sendConfirmationEmail(senderEmail, senderUsername, recipientUsername, "Payment", amount, recipientEmail);

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


    //Get onyl the users email and username
    const [requesterData] = await db.query('SELECT email, username FROM User WHERE user_id = ?', [requesterId]);
    const requesterEmail = requesterData[0].email;
    const requesterUsername = requesterData[0].username;

    console.log('requesterEmail:', requesterEmail);
    console.log('requesterUsername:', requesterUsername);

    // Extract other information from the request body
    const { recipient, amount, message } = req.body;

    // Validate input
    if (!recipient || !amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid input' });
    }
    
 
    // Fetch recipient ID based on the recipient username or email
    const [recipientData] = await db.query('SELECT user_id, username, email FROM User WHERE username = ? OR email = ?', [recipient, recipient]);

    if (recipientData.length === 0) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    const recipientId = recipientData[0].user_id;
    const recipientUsername = recipientData[0].username;
    const recipientEmail = recipientData[0].email;

     //check if users have each other blocked
 const [blocked] = await db.query('SELECT * FROM Friendship WHERE (requester_id = ? AND addressee_id = ?) AND status = "blocked" OR (requester_id = ? AND addressee_id = ?) AND status = "blocked"', [requesterId, recipientId, recipientId, requesterId]);
 if (blocked.length > 0) {
  console.log('Users have each other blocked');
   return res.status(400).json({ message: 'Users have each other blocked' });
 }

    // Insert transaction with message and set transaction_type to "Request"
    await db.query('INSERT INTO Transaction (sender_id, receiver_id, amount, transaction_type, created_at, message, processed) VALUES (?, ?, ?, ?, NOW(), ?, 0)', [
      requesterId,
      recipientId,
      amount,
      'Request',
      message,
    ]);
    sendConfirmationEmail(requesterEmail, requesterUsername, recipientUsername, "Request", amount, recipientEmail);

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
//check if user is already friends with another user with JWT authentication
app.get('/checkIfFriends', authenticateToken, async (req, res) => {
  const user_id = req.user.userId;
  const friendId = req.query.friendId;

  //check if entry exists and status is accepted
  const query = `SELECT * FROM Friendship WHERE (requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?)`;
  const [friendship] = await db.query(query, [user_id, friendId, friendId, user_id]);
  const isFriend = friendship.length > 0 && friendship[0].status === 'accepted';
  console.log('isFriend:', isFriend);
  res.json({ isFriend: isFriend });

});

//Route to accept or decline a transaction Request with JWT authentication
app.post('/transactions/:transactionId', authenticateToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.user.userId;
    console.log('userId:', userId);
    // Get the transaction ID from the request parameters
    const transactionId = req.params.transactionId;
    console.log('transactionId YOUR ARE LOOKING FOR:', transactionId);
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

      // Fetch sender username and email
      const [senderData] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [transaction.sender_id]);
      const senderUsername = senderData[0].username;
      const senderEmail = senderData[0].email;

      // Fetch recipient username and email
      const [recipientData] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [transaction.receiver_id]);
      const recipientUsername = recipientData[0].username;
      const recipientEmail = recipientData[0].email;

      // Update balances in the database
      await updateBalance(transaction.sender_id, +transaction.amount);
      await updateBalance(transaction.receiver_id, -transaction.amount);

      // Send confirmation emails to sender and recipient
      sendRequestConfirmationEmail(senderEmail, senderUsername, recipientUsername, 'Request', transaction.amount, "accepted");

      res.json({ message: 'Transaction accepted successfully' });
    }

    if (action === 'decline') {
      const [senderData] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [transaction.sender_id]);
      const senderUsername = senderData[0].username;
      const senderEmail = senderData[0].email;

      // Fetch recipient username and email
      const [recipientData] = await db.query('SELECT username, email FROM User WHERE user_id = ?', [transaction.receiver_id]);
      const recipientUsername = recipientData[0].username;
      const recipientEmail = recipientData[0].email;

      // Update the transaction status to "declined"
      await db.query('UPDATE Transaction SET processed = 2 WHERE transaction_id = ?', [transactionId]);
      sendRequestConfirmationEmail(senderEmail, senderUsername, recipientUsername, 'Request', transaction.amount, "declined");
      res.json({ message: 'Transaction declined successfully' });
    }
  } catch (error) {
    console.error('Error accepting transaction:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
}
);


app.post('/event-service', async (req, res) => {
  try {

        events = req.body;

    for (let i = 0; i < events.length; i++) {

        [updateInformation] = await db.query('UPDATE Event SET datetime_event = ?, recurrence_interval = ?, status = 1 WHERE id = ?',
        [
                events[i].datetime_event,
                events[i].recurrence_interval,
                events[i].event_id
        ]);
    }


    const [updateEventStatusToActive] = await db.query(`
            UPDATE Event SET status = 1 WHERE datetime_event > NOW() AND status != 0 AND recurrence_type > 0;
        `);

        const [updateEventStatusToInactive] = await db.query(`
            UPDATE Event
            SET status = 2
            WHERE datetime_event < NOW()
            AND
            status != 0
            AND
            recurrence_type = 0
        `);


    res.status(200).json({ message: 'Event Service successfully finished' });
  }
  catch (e) {
    console.log(e);
    res.status(500).json({ message: 'Event Service failed' });
  }
});



//route to get the events the user is part of with JWT authentication
app.get('/events', authenticateToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.user.userId;

    // All Events the User interacted with (being Creator or joined the Event)
    const [interactedEvents] = await db.query(`
      SELECT
          Event.*,
          Location.*,
          User_Event.user_id,
          User_Event.status AS user_event_status,
          User.username AS creator_username,
          User.user_id AS creator_id
      FROM
          Event
      JOIN
          User_Event ON User_Event.event_id = Event.id
      JOIN
          User ON Event.creator_id = User.user_id
      LEFT JOIN
          Location ON Event.id = Location.event_id
      WHERE
          User_Event.status != 0
          AND
          User_Event.user_id = ?;

    `, [userId]);

    //+  OR User_Event.status = 0    -> need to flush all events first to implement!
    res.json(interactedEvents);

  } catch (error) {
    console.error('Error fetching Events:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.get('/fetch-single-event', authenticateToken, async(req, res) => {

    try{

        const senderId = req.user.userId;
        const eventId = req.query.eventId;

        const [singleEvent] = await db.query(
            `SELECT
             Event.*,
                       Location.*,
                       User_Event.user_id,
                       User_Event.status AS user_event_status,
                       User.username AS creator_username,
                       User.user_id AS creator_id
             FROM Event
             JOIN
                       User_Event ON User_Event.event_id = Event.id
                   JOIN
                       User ON Event.creator_id = User.user_id
                   LEFT JOIN
                       Location ON Event.id = Location.event_id
             WHERE
             Event.id = ?
             AND
             User_Event.user_id = ?
             ;`, [eventId, senderId]
        );

        res.json(singleEvent);
    }
    catch(error){
       console.error('Error fetching Events:', error);
       res.status(500).json({ message: 'Internal server error' });
    }
});

app.get('/fetch-latest-created-event', authenticateToken, async(req, res) => {

    try{

            const senderId = req.user.userId;

            const [latestEvent] = await db.query(
                `SELECT Event.*,
                                  User_Event.status AS user_event_status,
                                  Event.id AS event_id
                                  FROM Event
                                  JOIN
                                  User_Event ON Event.id = User_Event.event_id
                                  WHERE Event.id = (SELECT MAX(id) FROM Event);`
            );

            console.log(latestEvent);
            res.json(latestEvent);
        }
        catch(error){
           console.error('Error fetching Events:', error);
           res.status(500).json({ message: 'Internal server error' });
        }

});

app.get('/fetch-all-events', authenticateToken, async(req, res) => {

    try{
        const senderId = req.user.userId;

        const [allEvents] = await db.query(
            `SELECT
             Event.*,
                       Location.*,
                       User_Event.user_id,
                       User_Event.status AS user_event_status,
                       User.username AS creator_username,
                       User.user_id AS creator_id
             FROM Event
             JOIN
                       User_Event ON User_Event.event_id = Event.id
                   JOIN
                       User ON Event.creator_id = User.user_id
                   LEFT JOIN
                       Location ON Event.id = Location.event_id;`
        );

        res.json(allEvents);
    }
    catch(error){
       console.error('Error fetching Events:', error);
       res.status(500).json({ message: 'Internal server error' });
    }
});


// Get the tree soonest events for the dashboard
app.get('/dashboard-events', authenticateToken, async (req, res) => {

  try {

    const senderId = req.user.userId;

    const [dashboardEventQuery] = await db.query(
      `SELECT
             Event.*,
                       Location.*,
                       User_Event.user_id,
                       User_Event.status AS user_event_status,
                       User.username AS creator_username,
                       User.user_id AS creator_id
             FROM Event
             JOIN
                    User_Event ON User_Event.event_id = Event.id
             JOIN
                    User ON Event.creator_id = User.user_id
             LEFT JOIN
                    Location ON Event.id = Location.event_id
             WHERE User_Event.status = 1
             AND
             Event.status = 1
             AND
             datetime_event > NOW()
             AND
             User_Event.user_id = ?
             ORDER BY ABS(UNIX_TIMESTAMP(datetime_event) - UNIX_TIMESTAMP(NOW()))
             LIMIT 3;`,
             [senderId]
        );


    res.json(dashboardEventQuery);
  }
  catch (error) {
    console.error('Error fetching Events:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Create Event
app.post('/create-event', authenticateToken, async (req, res) => {

  let eventId;

  try {
    const senderId = req.user.userId;
    const { category, title, description, max_participants, datetime_event, country, city, street, zipcode, price, recurrence_type } = req.body;

    // Validate input
    if (!category || !title || !description || !max_participants || !datetime_event) {
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

//edit event
app.post('/edit-event', authenticateToken, async (req, res) => {

  let eventId;

  try {
    const senderId = req.user.userId;
    const { category,OLD_title, title, description, max_participants, datetime_event, country, city, street, zipcode, price, 
      recurrence_type,eventID,participantMails,creatorName } = req.body;

    // Validate input
    if (!category || !title || !description || !max_participants || !datetime_event) {
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
    const [eventQuery] = await db.query('UPDATE Event SET category = ?, title = ?, description = ?, max_participants = ?, datetime_created = NOW(), datetime_event = ?, price = ?, creator_id = ?, recurrence_interval = 0, recurrence_type = ? WHERE id = ?', [
  category,
  title,
  description,
  max_participants,
  datetime_event,
  price,
  senderId,
  recurrence_type,
  eventID
]);

    console.log(eventQuery);

    // Link Event -> Location
    const locationQuery = await db.query('UPDATE Location SET country = ?, city = ?, street = ?, zipcode = ? WHERE event_id = ?', [country, city, street, zipcode, eventID]);
    console.log(locationQuery);

    // Link Event -> User_Event
    //const user_eventQuery = await db.query('INSERT INTO User_Event (event_id, user_id) VALUES (?, ?)', [eventId, senderId]);
    //console.log(user_eventQuery);

    sendEventEditedEmail(participantMails,creatorName,OLD_title, title,
      category, description, country, city, street, zipcode, price, recurrence_type, datetime_event)

    res.status(200).json({ message: 'Event created successfully' });

  } catch (error) {

    console.error('Error creating event:', error);
    res.status(500).json({ message: 'Internal server error' });
  }

});

// Invite to event
app.post('/invite-event', authenticateToken, async (req, res) => {
  try {
    const senderId = req.user.userId;
    const { eventId, recipient } = req.body;
    
    if (!eventId || !recipient) {
      return res.status(400).json({ message: 'Invalid Event Id or Recipient' });
    }
    
    const [recipientData] = await db.query('SELECT user_id, username, email FROM User WHERE username = ? OR email = ?', [recipient, recipient]);

    if (recipientData.length === 0){

        return res.status(402).json({ message: 'This account does not exist' });
    }

    const recipientId = recipientData[0].user_id;
    const recipientEmail = recipientData[0].email;
    const recipientUsername = recipientData[0].username;
     
    const [checkForSpam] = await db.query('SELECT * FROM User_Event WHERE event_id = ? and user_id = ?', [eventId, recipientId]);
    if (checkForSpam.length > 0) {

      return res.status(401).json({ message: 'User already interacted with the Event' });
    }
     //check if users have each other blocked
     const [blocked] = await db.query('SELECT * FROM Friendship WHERE (requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?) AND status = "blocked"', [senderId, recipientId, recipientId, senderId]);
     if (blocked.length > 0) {
       return res.status(400).json({ message: 'Users have each other blocked' });
     } 
    const [inviteQuery] = await db.query('INSERT INTO User_Event (event_id, user_id, status) VALUES (?, ?, 2)', [eventId, recipientId]);
    console.log(inviteQuery);


    const [eventData] = await db.query(
                `SELECT
                 Event.*,
                 User_Event.user_id,
                 User_Event.status AS user_event_status,
                 User.username AS creator_username
                 FROM Event
                 JOIN
                    User_Event ON User_Event.event_id = Event.id
                 JOIN
                    User ON Event.creator_id = User.user_id
                 WHERE
                 Event.id = ?
                 AND
                 User_Event.user_id = ?;
               `, [eventId, senderId]
    );

    const creatorUsername = eventData[0].creator_username;
    const eventTitle = eventData[0].title;
    const datetime_event = eventData[0].datetime_event;

    sendEventInvitationEmail(recipientEmail, recipientUsername, creatorUsername, eventTitle, datetime_event);

    res.status(200).json({ message: 'Successfully invited to Event' });

  }
  catch (error) {
    console.error('Error sending invite to Event:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Join event
app.post('/join-event', authenticateToken, async (req, res) => {
  try {

    const senderId = req.user.userId;
    const { amount, message, eventId } = req.body;

    if( !message || !eventId){
        return res.status(400).json({ message: 'Invalid input' });
    }

     // Additional validation if needed
       const [checkStatus] = await db.query('SELECT * FROM User_Event WHERE event_id = ? AND user_id = ?', [eventId, senderId]);

       if (checkStatus.length === 0) {
            return res.status(400).json({ message: 'Event not found' });
       }

       if (checkStatus[0].status === 1) {
            return res.status(401).json({ message: 'Event is already joined' });
       }


    const [joinQuery] = await db.query('UPDATE User_Event SET status = 1 WHERE event_id = ? AND user_id = ?', [eventId, senderId]);
    console.log(joinQuery);

    const [increaseParticipantsQuery] = await db.query('UPDATE Event SET participants = participants + 1 WHERE id = ?', [eventId]);
    console.log(increaseParticipantsQuery);

    res.status(200).json({ message: 'Event successfully joined' });

  }catch (error) {

    console.error('Error joining event:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Leave event
app.post('/leave-event', authenticateToken, async (req, res) => {
  try {
        const senderId = req.user.userId;
        const eventId = req.query.eventId;

        if (!eventId || !senderId) {
            console.log('Invalid Event Id or Sender Id');
            return res.status(400).json({ message: 'Invalid input' });
        }

        // Additional validation if needed
        const [checkStatus] = await db.query('SELECT * FROM User_Event WHERE event_id = ? AND user_id = ?', [eventId, senderId]);

        if (checkStatus.length === 0) {
            return res.status(404).json({ message: 'Event not found' });
        }

        if (checkStatus[0].status === 0) {
            return res.status(401).json({ message: 'Event is already leaved' });
        }

        const [leaveQuery] = await db.query('UPDATE User_Event SET status = 0 WHERE event_id = ? AND user_id = ?', [eventId, senderId]);
        console.log(leaveQuery);

        const [decreaseParticipants] = await db.query('UPDATE Event SET participants = participants - 1 WHERE id = ?', [eventId]);
        console.log(decreaseParticipants);

        res.status(200).json({ message: 'Event successfully leaved' });

       } catch (error) {
          console.error('Error leaving event:', error);
          res.status(500).json({ message: 'Internal server error' });
       }
});



// Cancel event
app.post('/cancel-event', authenticateToken, async (req, res) => {
  try {
    const senderId = req.user.userId;
    const { eventId, participants } = req.body;

    if (!eventId) {
      console.log('Invalid Event Id');
      return res.status(400).json({ message: 'Invalid input' });
    }

       const [event] = await db.query(
                        `SELECT
                         Event.*,
                         User_Event.user_id,
                         User_Event.status AS user_event_status,
                         User.username AS creator_username
                         FROM Event
                         JOIN
                            User_Event ON User_Event.event_id = Event.id
                         JOIN
                            User ON Event.creator_id = User.user_id
                         WHERE
                         Event.id = ?
                         AND
                         User_Event.user_id = ?;
                       `, [eventId, senderId]
       );


    if (event.length === 0) {
      return res.status(404).json({ message: 'Event not found' });
    }

    if (event[0].status === 0) {
      return res.status(401).json({ message: 'Event is already canceled' });
    }


    // Set Event Status to canceled
    const creatorUsername = event[0].creator_username;
    const eventTitle = event[0].title;
    const eventPrice = event[0].price;



    const [cancelQuery] = await db.query('UPDATE Event SET status = 0 WHERE id = ? AND creator_id = ?',
      [
        eventId,
        senderId
      ]);

    console.log(cancelQuery);

    // Send Email to participants
    const participantsUsername = [];
    const participantsId = [];

    // Loop through the participants and query their data
    for (let i = 0; i < participants.length; i++) {
      const [participant] = await db.query('SELECT User.username FROM User WHERE User.email = ?', [participants[i]]);


      // Check if participant data is found
      if (participant) {
        participantsUsername.push(participant);
      }
    }

    // Loop through the participants and query their data
        for (let i = 0; i < participants.length; i++) {
          const [participantId] = await db.query('SELECT User.user_id FROM User WHERE User.email = ?', [participants[i]]);


          // Check if participant data is found
          if (participantId) {
            participantsId.push(participantId);
          }
        }



    for(let i = 0; i < participants.length; i++){


        if(eventPrice > 0){

                    const senderBalance = await getBalance(senderId);
                    console.log(senderBalance);

                    /* // Case if User does not have enough money to apy all participants
                    if(senderBalance < eventPrice){

                        console.log("User does not have enough money to refund the event costs")
                        return res.status(402).json({ message: ' User does not have enough money to refund the event costs  ' });
                    }
                    */

                    const message = "Event costs paid back";

                    await db.query('INSERT INTO Transaction (sender_id, receiver_id, amount, transaction_type, created_at, message, processed, event_id) VALUES (?, ?, ?, ?, NOW(), ?, 1, ?);',
                    [senderId,
                     participantsId[i][0].user_id,
                     eventPrice,
                     'Payment',
                     message,
                     eventId]);


                    await updateBalance(senderId, -eventPrice);
                    await updateBalance(participantsId[i][0].user_id, +eventPrice);

                    const [kickParticipant] = await db.query(`
                                         UPDATE User_Event SET User_Event.status = 0
                                         WHERE User_Event.event_id = ?
                                         AND
                                         User_Event.user_id = ?;
                                       `, [eventId, participantsId[i][0].user_id]);
                }


        sendEventCanceledEmail(participants[i], participantsUsername[i][0].username, creatorUsername, eventTitle);
    }


    res.status(200).json({ message: 'Event successfully canceled' });

  } catch (error) {
    console.error('Error canceling event:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.post('/kick-participant',  authenticateToken, async (req, res) => {

    try {

        const senderId = req.user.userId;
        const eventId = req.query.eventId;
        const participantUsername = req.query.participantUsername;

        if (!eventId || !participantUsername) {
            console.log('Invalid Event Id or participant Username');
            return res.status(400).json({ message: 'Invalid input' });
        }

        const [participantIdAndEmail] = await db.query(`
            SELECT User.user_id, User.email FROM User WHERE User.username = ?;
            `, [participantUsername]);


        const participantId = participantIdAndEmail[0].user_id;
        const participantEmail = participantIdAndEmail[0].email;


        const [eventInformation] = await db.query(`
            SELECT
                User.username AS creator_username,
                Event.*,
                User_Event.status AS user_event_status
            FROM
                User
            JOIN
                Event ON Event.creator_id = User.user_id
            JOIN
                User_Event ON Event.id = User_Event.event_id
            WHERE
                Event.id = ?
                AND
                User.user_id = ?;
            `, [eventId, senderId]);


        const eventPrice = eventInformation[0].price;
        const user_event_status = eventInformation[0].user_event_status;

        if(user_event_status != 1){
            return res.status(401).json({ message: ' User already kicked from the Event' });
        }

        if(eventPrice == 0){

            const [kickParticipant] = await db.query(`
                                 UPDATE User_Event SET User_Event.status = 0
                                 WHERE User_Event.event_id = ?
                                 AND
                                 User_Event.user_id = ?;
                               `, [eventId, participantId]);
        }

        if(eventPrice > 0){

            const senderBalance = await getBalance(senderId);
            console.log(senderBalance);

            if(senderBalance < eventPrice){

                console.log("User does not have enough money to refund the event costs")
                return res.status(402).json({ message: ' User does not have enough money to refund the event costs  ' });
            }

            const message = "Event costs paid back";

            await db.query('INSERT INTO Transaction (sender_id, receiver_id, amount, transaction_type, created_at, message, processed, event_id) VALUES (?, ?, ?, ?, NOW(), ?, 1, ?);',
            [senderId, participantId, eventPrice, 'Payment', message, eventId]);


            await updateBalance(senderId, -eventPrice);
            await updateBalance(participantId, +eventPrice);

            const [kickParticipant] = await db.query(`
                                 UPDATE User_Event SET User_Event.status = 0
                                 WHERE User_Event.event_id = ?
                                 AND
                                 User_Event.user_id = ?;
                               `, [eventId, participantId]);
        }

        // Decrease Participant number by one
        const [decreaseParticipants] = await db.query('UPDATE Event SET participants = participants - 1 WHERE id = ?', [eventId]);
        console.log(decreaseParticipants);

        console.log('Participant successfully kicked from the event');

        sendKickedFromEvent(participantEmail, participantUsername, eventInformation[0].creator_username, eventInformation[0].title);

        res.status(200).json({message: 'Participant successfully kicked from the event'});


      } catch (error) {
        console.error('Error kicking participant: ', error);
        res.status(500).json({ message: ' Error kicking participant ' });
      }

});

// Fetch participants of event
app.get('/event-participants', authenticateToken, async (req, res) => {
  try {

    const senderId = req.user.userId;
    const eventId = req.query.eventId;
    const type = req.query.type;

    if (!eventId || !type) {
        console.log('Invalid Event Id');
        return res.status(400).json({ message: 'Invalid input' });
    }

    // Type:
    // 1 -> Joined
    // 2 -> Pending

    const [joinedParticipants] = await db.query(`
                 SELECT
                 	User.username
                    FROM User
                    JOIN
                    User_Event
                    ON User.user_id = User_Event.user_id
                    WHERE User_Event.event_id = ?
                    AND
                    User.user_id != ?
                    AND
                    User_Event.status = ?;
               `, [eventId, senderId, type]);

    console.log('Participants:', joinedParticipants);
    res.json(joinedParticipants);


  } catch (error) {
    console.error('Error fetching event participants:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.get('/event-participant-mails', authenticateToken, async (req, res) => {
  try {

    const senderId = req.user.userId;
    const eventId = req.query.eventId;
    const type = req.query.type;

    console.log(type);

    if (!eventId || !type) {
        console.log('Invalid Event Id');
        return res.status(400).json({ message: 'Invalid input' });
    }

    // Type:
    // 1 -> Joined
    // 2 -> Pending

    const [joinedParticipants] = await db.query(`
             SELECT
             	User.email
                FROM User
                JOIN
                User_Event
                ON User.user_id = User_Event.user_id
                WHERE User_Event.event_id = ?
                AND
                User.user_id != ?
                AND
                User_Event.status = ?;
           `, [eventId, senderId, type]);


    console.log('Participants:', joinedParticipants);
    res.json(joinedParticipants);

  } catch (error) {
    console.error('Error fetching event participants:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Fetch pending events
app.get('/pending-events', authenticateToken, async (req, res) => {
  try {

    const userId = req.user.userId;

    const [pendingEvents] = await db.query(`
             SELECT
                        Event.*,
                        Location.*,
                        User_Event.user_id,
                        User_Event.status AS user_event_status,
                        User.username AS creator_username,
                        User.user_id AS creator_id
                    FROM
                        Event
                    JOIN
                        User_Event ON User_Event.event_id = Event.id
                    JOIN
                        User ON Event.creator_id = User.user_id
                    LEFT JOIN
                        Location ON Event.id = Location.event_id
                    WHERE
                        Event.status = 1
                        AND
                        User_Event.status = 2
                        AND
                        User_Event.user_id = ?;
        `, [userId]);


    console.log('events:', pendingEvents);
    res.json(pendingEvents);

  } catch (error) {
    console.error('Error fetching pending Events:', error);
    res.status(500).json({ message: 'Internal server error' });
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

function sendConfirmationEmail(senderEmail, username, receiver, requestType, amount, recipientEmail) {

  const mailOptions = {
    from: 'Payfriendz App',
    to: senderEmail,
    subject: 'Payfriendz: Your ' + requestType + ' to ' + receiver + ' was successfully send',
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
            <h2 class="code">${requestType} send!</h2>
            <p class="text-size-14">Dear ${username},
              <br><br>
              Your ${requestType} of ${amount} € was successfully send to ${receiver}. For more information, please check your transaction history.
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

  const mailToRecipient = {
    from: 'Payfriendz App',
    to: recipientEmail,
    subject: 'Payfriendz: You received a ' + requestType + ' from ' + username + '',
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
            <h2 class="code">${requestType} received!</h2>
            <p class="text-size-14">Dear ${receiver},
              <br><br>
              You received a ${requestType} of ${amount} € from ${username}. For more information, please check your transaction history.
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
  transporter.sendMail(mailToRecipient, (error, info) => {
    if (error) {
      console.error('Error sending email:', error);
    } else {
      console.log('Email sent:', info.response);
    }
  });
}

function sendRequestConfirmationEmail(senderEmail, username, receiver, requestType, amount, status) {
  const mailOptions = {
    from: 'Payfriendz App',
    to: senderEmail,
    subject: 'Payfriendz: Your ' + requestType + ' to ' + receiver + ' has been ' + status,
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
            <h1>Request ${status}</h1>
          </div>
          <div class="del-box">
            <h2 class="code">${amount}€ from ${receiver}</h2>
            <p class="text-size-14">Dear ${username},
              <br><br>
              Your ${requestType} of ${amount} € to ${receiver} has been ${status}. For more information, please check your transaction history.
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


function sendEventInvitationEmail(recipientEmail, recipientUsername, creatorUsername, eventTitle, datetime_event) {

    const options = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      hour12: true, // Use 12-hour format
      timeZone: 'UTC', // Specify the desired time zone (change 'UTC' to your preferred time zone)
    };

    const formattedDateTime = datetime_event.toLocaleString('en-US', options);

  const mailOptions = {
    from: 'Payfriendz App',
    to: recipientEmail,
    subject: 'Payfriendz: ' +  creatorUsername  + ' invited you to the Event: ' + eventTitle,
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
          .email-text {
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Event Invitation</h1>
          </div>
          <div class="del-box email-text">
            <h2 class="code">${creatorUsername} invited you to an Event</h2>
            <p class="text-size-14">Dear ${recipientUsername},
              <br><br>
              <p class="text-size-14">
                You received an event invitation from ${creatorUsername} to the Event: ${eventTitle}.
                For more information, please check your event page to accept or decline the event invitation.
              </p>
              <p class="text-size-14">
                The event starts at ${formattedDateTime}, after that you can no longer participate at the event!
              </p>
              <br><br>
              <p class="text-size-14">
                If you have any questions or concerns, please don't hesitate to contact us at <a href="mailto:payfriendzapp@gmail.com">payfriendzapp@gmail.com</a>.
              </p>
              <br><br>
              <p class="text-size-14">
                Thank you for being a part of Payfriendz!
              </p>
              <br><br>
              <p class="text-size-14">
              Best regards,
              </p>
              <br><br>
              <p class="text-size-14">
                Your Payfriendz Team
              </p>
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

function sendEventCanceledEmail(recipientEmail, recipientUsername, creatorUsername, eventTitle) {

  const mailOptions = {
    from: 'Payfriendz App',
    to: recipientEmail,
    subject: 'Payfriendz: ' +  creatorUsername  + ' canceled the Event: ' + eventTitle,
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
          .email-text {
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Event canceled</h1>
          </div>
          <div class="del-box email-text">
            <h2 class="code">${creatorUsername} canceled the Event</h2>
            <p class="text-size-14">Dear ${recipientUsername},
              <br><br>
              <p class="text-size-14">
                We are really sorry to inform you that the creator of the Event: ${eventTitle} decided to cancel the event.
                In the case that you have already paid to take part in the event, we will transfer the money back to your account as quickly as possible.
              </p>
              <br><br>
              <p class="text-size-14">
                If you have any questions or concerns, please don't hesitate to contact us at <a href="mailto:payfriendzapp@gmail.com">payfriendzapp@gmail.com</a>.
              </p>
              <br><br>
              <p class="text-size-14">
                Thank you for being a part of Payfriendz!
              </p>
              <br><br>
              <p class="text-size-14">
              Best regards,
              </p>
              <br><br>
              <p class="text-size-14">
                Your Payfriendz Team
              </p>
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

function sendKickedFromEvent(recipientEmail, recipientUsername, creatorUsername, eventTitle) {

  const mailOptions = {
    from: 'Payfriendz App',
    to: recipientEmail,
    subject: 'Payfriendz: You were kicked from the Event: ' + eventTitle,
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
          .email-text {
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Kicked from event</h1>
          </div>
          <div class="del-box email-text">
            <h2 class="code">${creatorUsername} kicked you from the Event</h2>
            <p class="text-size-14">Dear ${recipientUsername},
              <br><br>
              <p class="text-size-14">
                We are really sorry to inform you that the creator of the Event: ${eventTitle} decided to kick you from the event.
                In the case that you have already paid to take part in the event, we will transfer the money back to your account as quickly as possible.
              </p>
              <br><br>
              <p class="text-size-14">
                If you have any questions or concerns, please don't hesitate to contact us at <a href="mailto:payfriendzapp@gmail.com">payfriendzapp@gmail.com</a>.
              </p>
              <br><br>
              <p class="text-size-14">
                Thank you for being a part of Payfriendz!
              </p>
              <br><br>
              <p class="text-size-14">
              Best regards,
              </p>
              <br><br>
              <p class="text-size-14">
                Your Payfriendz Team
              </p>
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

function sendEventEditedEmail(recipientEmails, creatorUsername,OLD_eventTitle, eventTitle,
  category, description, country, city, street, zipcode, price, recurrence_type, datetime_event) {

  const options = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    hour12: true, // Use 12-hour format
    timeZone: 'UTC', // Specify the desired time zone (change 'UTC' to your preferred time zone)
  };

  const formattedDateTime = datetime_event.toLocaleString('en-US', options);

  const mailOptions = {
    from: 'Payfriendz App',
    to: recipientEmails,
    subject: 'Payfriendz: Event "' + OLD_eventTitle + '" Information Updated',
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
        .info-box {
          background-color: #ffffff;
          padding: 20px;
          border-radius: 5px;
          margin-top: 20px;
          box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
        }
        .text-size-14 {
          font-size: 14px;
          color: #555;
        }
        .bold {
          font-weight: bold;
        }
        .email-text {
          text-align: center;
        }
        .updated-info {
          margin-top: 20px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Event Information Updated</h1>
        </div>
        <div class="info-box email-text">
          <h2 class="text-size-14 bold">${creatorUsername} updated the information for the Event: ${OLD_eventTitle}</h2>
          <div class="updated-info">
            <p class="text-size-14 bold">New Event Information:</p>
            <p class="text-size-14"><span class="bold">Title:</span> ${eventTitle}</p>
            <p class="text-size-14"><span class="bold">Category:</span> ${category}</p>
            <p class="text-size-14"><span class="bold">Description:</span> ${description}</p>
            <p class="text-size-14"><span class="bold">Location:</span> ${street}, ${city}, ${zipcode}, ${country}</p>
            <p class="text-size-14"><span class="bold">Price:</span> ${price}</p>
            <p class="text-size-14"><span class="bold">Recurrence Type:</span> ${recurrence_type}</p>
            <p class="text-size-14"><span class="bold">Event Date and Time:</span> ${formattedDateTime}</p>
          </div>
          <p class="text-size-14">
            For more information, please check your event page.
          </p>
          <br><br>
          <p class="text-size-14">
            If you have any questions or concerns, please don't hesitate to contact us at <a href="mailto:payfriendzapp@gmail.com">payfriendzapp@gmail.com</a>.
          </p>
          <br><br>
          <p class="text-size-14">
            Thank you for being a part of Payfriendz!
          </p>
          <br><br>
          <p class="text-size-14">
            Best regards,
          </p>
          <br><br>
          <p class="text-size-14">
            Your Payfriendz Team
          </p>
        </div>
        <p class="text-size-14 updated-info">
          &copy; Payfriendz 2023. Payfriendz is a registered trademark of Payfriendz.
        </p>
      </div>
    </body>
  </html>
  `
  };

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






//  new route /addFriend?friendId=$friendId with JWT authentication
app.post('/addFriendId', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const friendId = req.body.friendId;
    console.log("user_id: ", userId, "- friendId: ", friendId);

    //check if users are already friends
    const [friends] = await db.query(
      `SELECT * FROM Friendship 
       WHERE (requester_id = ? AND addressee_id = ?)
       OR    (requester_id = ? AND addressee_id = ?)`,
      [userId, friendId, friendId, userId]
    );

    console.log(friends);
    //when they are not already friends
    if (friends[0] == null) {
      const query = `
      INSERT INTO Friendship 
      (requester_id, addressee_id, status, request_time) 
      VALUES (?, ?, ?, NOW())`;
      const [addingFriend] = await db.query(query, [userId, friendId, 'pending']);
      res.status(200).json({ addingFriend });
    } else {
      //res.status(500).json({message: 'Cannot add User'});
      res.status(500).json('Cannot add User');
    }
  } catch (error) {
    console.error('Error adding friend:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});




