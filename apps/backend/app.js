const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = 3000;

// PostgreSQL connection
const pool = new Pool({
  host: 'postgresql-database.cvwuww9ibcxn.us-east-2.rds.amazonaws.com',
  database: 'data',
  user: 'postgres',
  password: 'jb3a6ebZnFIvAdVkY6fDT',
});

// Set up EJS for templating
app.set('view engine', 'ejs');

// Route to fetch and display customer data
app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM customer_data');
    res.render('index', { customers: result.rows });
  } catch (err) {
    console.error(err);
    res.send('Error fetching data');
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});

