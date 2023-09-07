import psycopg2
from faker import Faker
import random

fake = Faker()

connection = psycopg2.connect(
    host="postgresql-database.cysdx5j6qo9f.us-east-2.rds.amazonaws.com",
    database="data",
    user="postgres",
    password="postgres"
)

cursor = connection.cursor()

for _ in range(100):
    name = fake.first_name()
    surname = fake.last_name()
    order_id = random.randint(1000, 9999)
    email = fake.email()
    order_date = fake.date_time_this_year()
    product_name = fake.catch_phrase()
    cursor.execute("INSERT INTO customer_data (customerName, customerSurname, customerOrderId, customerEmail, orderDate, productName) VALUES (%s, %s, %s, %s, %s, %s)", (name, surname, order_id, email, order_date, product_name))

connection.commit()
cursor.close()
connection.close()
