# HarborWing Air IT8 Midterm Drill — Corrected Files

This folder contains the corrected project files. The database is expected to contain **17 tables**:
1. booking_agent
2. passenger
3. airline
4. aircraft_type
5. reservation_status
6. payment_status
7. ticket_type
8. travel_class
9. airport
10. calendar_date
11. flight_schedule
12. reservation
13. payment
14. flight_leg
15. flight_cost
16. reservation_payment
17. reservation_leg

## Important: create all 17 tables

1. Open MySQL Workbench and connect to your local MySQL server.
2. Choose **File → Open SQL Script** and open `schema.sql` from this folder.
3. Click inside the SQL editor, then press **Ctrl+A** so the whole script is selected.
4. Click the lightning-bolt **Execute** button. Do not execute only the first selected section.
5. Check the **Action Output** panel for any red error row. The final query should show `created_table_count = 17`.
6. In the SCHEMAS panel, right-click `harborwing_air` and choose **Refresh All**. Expand **Tables**. If the list still shows only 10 tables, check Action Output for the first red error and rerun the full script after correcting that error.

The schema script drops and recreates this project's tables. Do not run it in a database containing important data.

## Install Python packages

Open Command Prompt in this folder and run:

```bat
py -m pip install -r requirements.txt
```

## Run the fictional seed data

The script connects to the local MySQL server. If your MySQL root account has a password, set it in the same Command Prompt window before running the script:

```bat
set MYSQL_PASSWORD=YOUR_MYSQL_PASSWORD
py seed_data.py
```

Replace `YOUR_MYSQL_PASSWORD` with your actual MySQL password. Do not include the words `YOUR_MYSQL_PASSWORD`.

If your MySQL account uses a different username, set it too:

```bat
set MYSQL_USER=your_mysql_username
set MYSQL_PASSWORD=your_mysql_password
py seed_data.py
```

The seed script creates fictional demonstration data and prints a row count for every table. Every created table should have at least 50 rows. Do not use this script with real data.

## Run the SQL queries

1. Open `queries.sql` in MySQL Workbench.
2. Execute each of the first four queries separately to demonstrate:
   - reservations with passenger, agent, payments, and flight legs;
   - reservations using a selected flight leg;
   - payments linked to a reservation;
   - a flight cost valid on a chosen date.
3. Execute the final row-count query to show the counts for all 17 tables.

## Notes

- All generated people, airlines, airports, and transactions are fictional.
- The schema keeps scheduled flight times separate from nullable actual flight times.
- `reservation_payment` and `reservation_leg` are link tables for many-to-many relationships.
- `flight_cost` uses a composite primary key: flight number, aircraft type, and valid-from date.
- The schema retains primary keys, foreign keys, unique keys, and indexes. The seed data is generated to follow the assignment's business rules.
