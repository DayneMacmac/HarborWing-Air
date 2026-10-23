-- HarborWing Air IT8 Midterm Drill
-- Run schema.sql, then seed_data.py, before executing these queries.
USE harborwing_air;

-- 1. View reservations with passenger, optional agent, linked payments, and flight legs.
-- Payment and leg totals are aggregated separately to avoid inflated totals from joining both links.
SELECT
    r.reservation_id,
    r.reservation_code,
    r.reservation_status_code,
    CONCAT_WS(' ', p.first_name, NULLIF(p.second_name, ''), p.last_name) AS main_passenger,
    COALESCE(ba.agent_name, 'Direct booking') AS booking_agent,
    COALESCE(pay.payment_count, 0) AS payment_count,
    COALESCE(pay.total_linked_payment_amount, 0.00) AS total_linked_payment_amount,
    COALESCE(leg.leg_count, 0) AS leg_count,
    leg.leg_list
FROM reservation AS r
JOIN passenger AS p ON p.passenger_id = r.passenger_id
LEFT JOIN booking_agent AS ba ON ba.agent_id = r.agent_id
LEFT JOIN (
    SELECT rp.reservation_id,
           COUNT(*) AS payment_count,
           SUM(pm.payment_amount) AS total_linked_payment_amount
    FROM reservation_payment AS rp
    JOIN payment AS pm ON pm.payment_id = rp.payment_id
    GROUP BY rp.reservation_id
) AS pay ON pay.reservation_id = r.reservation_id
LEFT JOIN (
    SELECT rl.reservation_id,
           COUNT(*) AS leg_count,
           GROUP_CONCAT(
               CONCAT(fl.flight_number, ' (leg ', fl.leg_id, ')')
               ORDER BY fl.leg_id SEPARATOR ', '
           ) AS leg_list
    FROM reservation_leg AS rl
    JOIN flight_leg AS fl ON fl.leg_id = rl.leg_id
    GROUP BY rl.reservation_id
) AS leg ON leg.reservation_id = r.reservation_id
ORDER BY r.reservation_id
LIMIT 25;

-- 2. Find reservations using a particular flight leg. The seeded data guarantees leg_id = 1 exists.
SELECT r.reservation_id, r.reservation_code, r.reservation_status_code
FROM reservation AS r
JOIN reservation_leg AS rl ON rl.reservation_id = r.reservation_id
WHERE rl.leg_id = 1
ORDER BY r.reservation_id;

-- 3. Find payments linked to one reservation. The seeded data guarantees reservation_id = 1 exists.
SELECT r.reservation_code, pm.payment_id, pm.payment_status_code,
       pm.payment_date_utc, pm.payment_amount, pm.payment_method
FROM reservation AS r
JOIN reservation_payment AS rp ON rp.reservation_id = r.reservation_id
JOIN payment AS pm ON pm.payment_id = rp.payment_id
WHERE r.reservation_id = 1
ORDER BY pm.payment_date_utc, pm.payment_id;

-- 4. Find the flight cost for a flight, aircraft type, and date.
-- The seed script guarantees this example returns a row.
SELECT flight_number, aircraft_type_code, valid_from_date, valid_to_date, cost_amount
FROM flight_cost
WHERE flight_number = 'HW0001'
  AND aircraft_type_code = 'AC01'
  AND '2026-06-01' BETWEEN valid_from_date AND valid_to_date;

-- 5. Row-count verification for EVERY table created by schema.sql.
-- The IT8 requirement is at least 50 rows in every table, including link/reference tables.
SELECT 'booking_agent' AS table_name, COUNT(*) AS row_count FROM booking_agent
UNION ALL SELECT 'passenger', COUNT(*) FROM passenger
UNION ALL SELECT 'airline', COUNT(*) FROM airline
UNION ALL SELECT 'aircraft_type', COUNT(*) FROM aircraft_type
UNION ALL SELECT 'reservation_status', COUNT(*) FROM reservation_status
UNION ALL SELECT 'payment_status', COUNT(*) FROM payment_status
UNION ALL SELECT 'ticket_type', COUNT(*) FROM ticket_type
UNION ALL SELECT 'travel_class', COUNT(*) FROM travel_class
UNION ALL SELECT 'airport', COUNT(*) FROM airport
UNION ALL SELECT 'calendar_date', COUNT(*) FROM calendar_date
UNION ALL SELECT 'flight_schedule', COUNT(*) FROM flight_schedule
UNION ALL SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL SELECT 'payment', COUNT(*) FROM payment
UNION ALL SELECT 'flight_leg', COUNT(*) FROM flight_leg
UNION ALL SELECT 'flight_cost', COUNT(*) FROM flight_cost
UNION ALL SELECT 'reservation_payment', COUNT(*) FROM reservation_payment
UNION ALL SELECT 'reservation_leg', COUNT(*) FROM reservation_leg
ORDER BY table_name;
