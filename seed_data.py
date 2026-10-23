import os
import random
import sys
from datetime import date, datetime, time, timedelta

import mysql.connector
from faker import Faker

SEED = 20261016
random.seed(SEED)
Faker.seed(SEED)
fake = Faker()

TABLES_IN_DELETE_ORDER = [
    "reservation_leg", "reservation_payment", "flight_cost", "flight_leg",
    "reservation", "payment", "flight_schedule", "passenger", "booking_agent",
    "airport", "calendar_date", "airline", "aircraft_type", "reservation_status",
    "payment_status", "ticket_type", "travel_class",
]


def connect():
    """Connect using environment variables, with beginner-friendly defaults."""
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "localhost"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database="harborwing_air",
        charset="utf8mb4",
    )


def insert_many(cursor, sql, rows):
    rows = list(rows)
    if rows:
        cursor.executemany(sql, rows)


def main():
    try:
        conn = connect()
    except mysql.connector.Error as exc:
        print("Could not connect to MySQL or open harborwing_air.")
        print("First run schema.sql in MySQL Workbench, then check your MySQL password.")
        print(f"MySQL message: {exc}")
        sys.exit(1)

    try:
        cur = conn.cursor()
        # Disable FK checks only while clearing this project's tables, then restore them.
        cur.execute("SET FOREIGN_KEY_CHECKS = 0")
        for table in TABLES_IN_DELETE_ORDER:
            cur.execute(f"DELETE FROM `{table}`")
        cur.execute("SET FOREIGN_KEY_CHECKS = 1")
        conn.commit()
        # Make generated IDs predictable after repeated runs.
        for table in ["booking_agent", "passenger", "reservation", "payment", "flight_leg"]:
            cur.execute(f"ALTER TABLE `{table}` AUTO_INCREMENT = 1")

        # Reference tables: standard codes plus clearly marked demo codes to satisfy 50+ rows.
        airlines = [(f"HW{i:02d}", f"HarborWing Demonstration Airline {i:02d}", 1)
                    for i in range(1, 51)]
        insert_many(cur, "INSERT INTO airline (airline_code, airline_name, demonstration_code) VALUES (%s,%s,%s)", airlines)

        aircraft = [(f"AC{i:02d}", f"Demonstration Aircraft Type {i:02d}", random.randint(40, 240), 1)
                    for i in range(1, 51)]
        insert_many(cur, "INSERT INTO aircraft_type (aircraft_type_code, aircraft_type_name, passenger_capacity, demonstration_code) VALUES (%s,%s,%s,%s)", aircraft)

        reservation_statuses = [("CONF", "Confirmed", 0), ("PEND", "Pending", 0), ("CANC", "Cancelled", 0)]
        reservation_statuses += [(f"R{i:02d}", f"Demonstration reservation status {i:02d}", 1) for i in range(4, 51)]
        insert_many(cur, "INSERT INTO reservation_status VALUES (%s,%s,%s)", reservation_statuses)

        payment_statuses = [("PAID", "Paid", 0), ("PEND", "Pending", 0), ("FAIL", "Failed", 0)]
        payment_statuses += [(f"P{i:02d}", f"Demonstration payment status {i:02d}", 1) for i in range(4, 51)]
        insert_many(cur, "INSERT INTO payment_status VALUES (%s,%s,%s)", payment_statuses)

        ticket_types = [("STD", "Standard", 0), ("REF", "Refundable", 0), ("FLEX", "Flexible", 0)]
        ticket_types += [(f"T{i:02d}", f"Demonstration ticket type {i:02d}", 1) for i in range(4, 51)]
        insert_many(cur, "INSERT INTO ticket_type VALUES (%s,%s,%s)", ticket_types)

        travel_classes = [("ECO", "Economy", 0), ("BUS", "Business", 0), ("FST", "First", 0)]
        travel_classes += [(f"C{i:02d}", f"Demonstration travel class {i:02d}", 1) for i in range(4, 51)]
        insert_many(cur, "INSERT INTO travel_class VALUES (%s,%s,%s)", travel_classes)

        # Synthetic airports only; these are not real navigation codes or locations.
        airport_rows = [
            (f"HW{i:03d}", f"Fictional HarborWing Airport {i:03d}",
             f"Fictional Coastal City {i:03d}",
             random.choice(["Philippines", "Indonesia", "Malaysia", "Thailand", "Fictional Isles"]),
             "Synthetic demonstration airport; not for real navigation.")
            for i in range(1, 61)
        ]
        insert_many(cur, "INSERT INTO airport VALUES (%s,%s,%s,%s,%s)", airport_rows)

        # All calendar dates used by flight-cost records are present as FK targets.
        calendar_start, calendar_end = date(2024, 1, 1), date(2030, 12, 31)
        calendar_rows = []
        current = calendar_start
        while current <= calendar_end:
            calendar_rows.append((current, current.day, int(current.weekday() < 5)))
            current += timedelta(days=1)
        insert_many(cur, "INSERT INTO calendar_date VALUES (%s,%s,%s)", calendar_rows)

        agents = [
            (f"Booking Agent {i:03d}", f"agent{i:03d}@example.test", f"+63-900-{i:07d}",
             f"Fictional Travel Agency {i:03d}", "Synthetic training record.")
            for i in range(1, 61)
        ]
        insert_many(cur, "INSERT INTO booking_agent (agent_name,email,phone,agency_name,other_details) VALUES (%s,%s,%s,%s,%s)", agents)

        passengers = []
        for i in range(1, 151):
            passengers.append((
                fake.first_name(), random.choice([None, fake.first_name()]), fake.last_name(),
                f"+63-9{random.randint(10, 99)}-{random.randint(1000000, 9999999)}",
                f"passenger{i:04d}@example.test", f"{random.randint(1,999)} Example Street",
                random.choice([None, f"Unit {random.randint(1,40)}"]), fake.city(),
                random.choice(["Palawan", "Cebu", "Bohol", "Laguna", "Batangas"]),
                random.choice(["Philippines", "Indonesia", "Malaysia"]),
                "Fictional passenger generated for the IT8 exercise.",
            ))
        insert_many(cur, """INSERT INTO passenger
            (first_name,second_name,last_name,phone_number,email_address,address_line1,address_line2,
             city,state_province_county,country,other_details)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", passengers)

        # Create 120 schedules; all route/time values satisfy schema checks.
        flights = []
        flight_info = []
        for i in range(1, 121):
            origin_idx = random.randint(1, 60)
            dest_idx = random.randint(1, 60)
            while dest_idx == origin_idx:
                dest_idx = random.randint(1, 60)
            depart_day = date(2026, 1, 1) + timedelta(days=random.randint(0, 900))
            dep = datetime.combine(depart_day, time(random.randint(5, 20), random.choice([0, 15, 30, 45])))
            arr = dep + timedelta(minutes=random.randint(45, 360))
            flight_no = f"HW{i:04d}"
            airline_code = random.choice(airlines)[0]
            aircraft_code = random.choice(aircraft)[0]
            origin, destination = f"HW{origin_idx:03d}", f"HW{dest_idx:03d}"
            flights.append((flight_no, airline_code, aircraft_code, origin, destination, dep, arr))
            flight_info.append((flight_no, origin, destination, dep, arr, aircraft_code))
        insert_many(cur, """INSERT INTO flight_schedule
            (flight_number,airline_code,usual_aircraft_type_code,origin_airport_code,destination_airport_code,
             scheduled_departure_utc,scheduled_arrival_utc)
            VALUES (%s,%s,%s,%s,%s,%s,%s)""", flights)

        # 160 legs. Some actual times are NULL because flights may not have operated yet.
        legs = []
        for _ in range(160):
            flight_no, origin, destination, dep, _arr, _ac = random.choice(flight_info)
            actual_dep = dep + timedelta(minutes=random.randint(-20, 35)) if random.random() < 0.72 else None
            actual_arr = actual_dep + timedelta(minutes=random.randint(45, 360)) if actual_dep and random.random() < 0.90 else None
            legs.append((flight_no, origin, destination, actual_dep, actual_arr))
        insert_many(cur, """INSERT INTO flight_leg
            (flight_number,origin_airport_code,destination_airport_code,actual_departure_utc,actual_arrival_utc)
            VALUES (%s,%s,%s,%s,%s)""", legs)

        reservations = []
        for i in range(1, 151):
            created = datetime(2025, 1, 1) + timedelta(
                days=random.randint(0, 650), hours=random.randint(0, 23), minutes=random.choice([0, 15, 30, 45]))
            agent_id = None if i % 3 == 0 else random.randint(1, 60)  # direct and agent-assisted
            status = ["CONF", "PEND", "CANC"][i % 3]
            ticket = ["STD", "REF", "FLEX"][i % 3]
            travel_class = ["ECO", "BUS", "FST"][i % 3]
            reservations.append((random.randint(1, 150), agent_id, status, ticket, travel_class,
                                 f"HWA{i:06d}", created, random.randint(1, 8)))
        insert_many(cur, """INSERT INTO reservation
            (passenger_id,agent_id,reservation_status_code,ticket_type_code,travel_class_code,
             reservation_code,created_at_utc,party_size)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""", reservations)

        payments = []
        for i in range(1, 151):
            pay_date = datetime(2025, 1, 1) + timedelta(days=random.randint(0, 800), hours=random.randint(0, 23))
            pay_status = ["PAID", "PEND", "FAIL"][i % 3]
            payments.append((pay_status, pay_date, round(random.uniform(25, 1800), 2),
                             random.choice(["Card", "Bank transfer", "Cash", "E-wallet"])))
        insert_many(cur, "INSERT INTO payment (payment_status_code,payment_date_utc,payment_amount,payment_method) VALUES (%s,%s,%s,%s)", payments)

        # Guarantee the sample query in queries.sql returns a row for HW0001 / AC01 / 2026-06-01.
        costs = [("HW0001", "AC01", date(2026, 1, 1), date(2026, 12, 31), 12500.00)]
        used_cost_keys = {("HW0001", "AC01", date(2026, 1, 1))}
        while len(costs) < 150:
            flight_no = random.choice(flight_info)[0]
            aircraft_code = random.choice(aircraft)[0]
            valid_from = calendar_start + timedelta(days=random.randint(0, 1800))
            key = (flight_no, aircraft_code, valid_from)
            if key in used_cost_keys:
                continue
            valid_to = min(valid_from + timedelta(days=random.randint(30, 240)), calendar_end)
            costs.append((flight_no, aircraft_code, valid_from, valid_to, round(random.uniform(0, 25000), 2)))
            used_cost_keys.add(key)
        insert_many(cur, "INSERT INTO flight_cost VALUES (%s,%s,%s,%s,%s)", costs)

        # Each reservation gets at least one payment and one leg. Extra pairs deliberately
        # create multiple payments/legs and shared payments, without duplicate pairs.
        reservation_payment_pairs = set()
        for reservation_id in range(1, 151):
            reservation_payment_pairs.add((reservation_id, reservation_id))
            for payment_id in random.sample(range(1, 151), random.randint(1, 2)):
                reservation_payment_pairs.add((reservation_id, payment_id))
        for payment_id in range(1, 31):
            for reservation_id in random.sample(range(1, 151), 3):
                reservation_payment_pairs.add((reservation_id, payment_id))
        insert_many(cur, "INSERT INTO reservation_payment (reservation_id,payment_id) VALUES (%s,%s)", sorted(reservation_payment_pairs))

        reservation_leg_pairs = set()
        for reservation_id in range(1, 151):
            reservation_leg_pairs.add((reservation_id, reservation_id))
            for leg_id in random.sample(range(1, 161), random.randint(1, 2)):
                reservation_leg_pairs.add((reservation_id, leg_id))
        insert_many(cur, "INSERT INTO reservation_leg (reservation_id,leg_id) VALUES (%s,%s)", sorted(reservation_leg_pairs))

        conn.commit()

        tables = [
            "booking_agent", "passenger", "airline", "aircraft_type", "reservation_status",
            "payment_status", "ticket_type", "travel_class", "airport", "calendar_date",
            "flight_schedule", "reservation", "payment", "flight_leg", "flight_cost",
            "reservation_payment", "reservation_leg",
        ]
        print("\nROW COUNTS (each table should contain at least 50 rows)")
        failures = []
        for table in tables:
            cur.execute(f"SELECT COUNT(*) FROM `{table}`")
            count = cur.fetchone()[0]
            print(f"{table}: {count}")
            if count < 50:
                failures.append(f"{table} has only {count} rows")
        if failures:
            raise RuntimeError("Row-count requirement failed: " + "; ".join(failures))
        print("\nSUCCESS: all tables contain at least 50 rows. Synthetic data generation completed.")
        print("The sample query values in queries.sql are supported by this data set.")
        cur.close()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
