import psycopg2
from faker import Faker
import random

fake = Faker()

connection = psycopg2.connect(
    host="postgresql-database.cvwuww9ibcxn.us-east-2.rds.amazonaws.com",
    database="data",
    user="postgres",
    password="jb3a6ebZnFIvAdVkY6fDT"
)

cursor = connection.cursor()

for _ in range(100):
    name = fake.first_name()
    surname = fake.last_name()
    order_id = random.randint(1000, 9999)  # Example of generating a random order ID
    cursor.execute("INSERT INTO customer_data (customerName, customerSurname, customerOrderId) VALUES (%s, %s, %s)", (name, surname, order_id))

connection.commit()
cursor.close()
connection.close()
