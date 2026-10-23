-- HarborWing Air IT8 Midterm Drill
-- MySQL 8.0+ | Fictional training database only
-- Uses broadly supported utf8mb4_unicode_ci collation.
-- Foreign keys, primary keys, unique keys, and indexes are defined below.
-- Business-rule values are generated validly by seed_data.py.
-- This script DROPS and recreates the project's tables. Back up anything important first.

CREATE DATABASE IF NOT EXISTS harborwing_air
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE harborwing_air;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS reservation_leg;
DROP TABLE IF EXISTS reservation_payment;
DROP TABLE IF EXISTS flight_cost;
DROP TABLE IF EXISTS flight_leg;
DROP TABLE IF EXISTS reservation;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS flight_schedule;
DROP TABLE IF EXISTS passenger;
DROP TABLE IF EXISTS booking_agent;
DROP TABLE IF EXISTS airport;
DROP TABLE IF EXISTS calendar_date;
DROP TABLE IF EXISTS airline;
DROP TABLE IF EXISTS aircraft_type;
DROP TABLE IF EXISTS reservation_status;
DROP TABLE IF EXISTS payment_status;
DROP TABLE IF EXISTS ticket_type;
DROP TABLE IF EXISTS travel_class;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE booking_agent (
  agent_id INT AUTO_INCREMENT PRIMARY KEY,
  agent_name VARCHAR(120) NOT NULL,
  email VARCHAR(254) UNIQUE,
  phone VARCHAR(30),
  agency_name VARCHAR(120),
  other_details TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE passenger (
  passenger_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  second_name VARCHAR(80) NULL,
  last_name VARCHAR(80) NOT NULL,
  phone_number VARCHAR(30),
  email_address VARCHAR(254) UNIQUE,
  address_line1 VARCHAR(160),
  address_line2 VARCHAR(160),
  city VARCHAR(100),
  state_province_county VARCHAR(100),
  country VARCHAR(100),
  other_details TEXT,
  INDEX idx_passenger_name (last_name, first_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE airline (
  airline_code VARCHAR(10) PRIMARY KEY,
  airline_name VARCHAR(120) NOT NULL UNIQUE,
  demonstration_code BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE aircraft_type (
  aircraft_type_code VARCHAR(20) PRIMARY KEY,
  aircraft_type_name VARCHAR(100) NOT NULL,
  passenger_capacity INT NOT NULL,
  demonstration_code BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reservation_status (
  status_code VARCHAR(20) PRIMARY KEY,
  status_name VARCHAR(80) NOT NULL UNIQUE,
  demonstration_code BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE payment_status (
  payment_status_code VARCHAR(20) PRIMARY KEY,
  status_name VARCHAR(80) NOT NULL UNIQUE,
  demonstration_code BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ticket_type (
  ticket_type_code VARCHAR(20) PRIMARY KEY,
  ticket_type_name VARCHAR(80) NOT NULL UNIQUE,
  demonstration_code BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE travel_class (
  travel_class_code VARCHAR(20) PRIMARY KEY,
  travel_class_name VARCHAR(80) NOT NULL UNIQUE,
  demonstration_code BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE airport (
  airport_code VARCHAR(10) PRIMARY KEY,
  airport_name VARCHAR(150) NOT NULL,
  city VARCHAR(100) NOT NULL,
  country VARCHAR(100) NOT NULL,
  other_details TEXT,
  INDEX idx_airport_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE calendar_date (
  calendar_date DATE PRIMARY KEY,
  day_of_month TINYINT NOT NULL,
  is_business_day BOOLEAN NOT NULL,
  INDEX idx_calendar_business (is_business_day, calendar_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE flight_schedule (
  flight_number VARCHAR(20) PRIMARY KEY,
  airline_code VARCHAR(10) NOT NULL,
  usual_aircraft_type_code VARCHAR(20) NOT NULL,
  origin_airport_code VARCHAR(10) NOT NULL,
  destination_airport_code VARCHAR(10) NOT NULL,
  scheduled_departure_utc DATETIME NOT NULL,
  scheduled_arrival_utc DATETIME NOT NULL,
  CONSTRAINT fk_schedule_airline FOREIGN KEY (airline_code)
    REFERENCES airline(airline_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_schedule_aircraft FOREIGN KEY (usual_aircraft_type_code)
    REFERENCES aircraft_type(aircraft_type_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_schedule_origin FOREIGN KEY (origin_airport_code)
    REFERENCES airport(airport_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_schedule_destination FOREIGN KEY (destination_airport_code)
    REFERENCES airport(airport_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_schedule_route_time (origin_airport_code, destination_airport_code, scheduled_departure_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reservation (
  reservation_id INT AUTO_INCREMENT PRIMARY KEY,
  passenger_id INT NOT NULL,
  agent_id INT NULL,
  reservation_status_code VARCHAR(20) NOT NULL,
  ticket_type_code VARCHAR(20) NOT NULL,
  travel_class_code VARCHAR(20) NOT NULL,
  reservation_code VARCHAR(20) NOT NULL UNIQUE,
  created_at_utc DATETIME NOT NULL,
  party_size INT NOT NULL,
  CONSTRAINT fk_reservation_passenger FOREIGN KEY (passenger_id)
    REFERENCES passenger(passenger_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservation_agent FOREIGN KEY (agent_id)
    REFERENCES booking_agent(agent_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_reservation_status FOREIGN KEY (reservation_status_code)
    REFERENCES reservation_status(status_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservation_ticket FOREIGN KEY (ticket_type_code)
    REFERENCES ticket_type(ticket_type_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservation_class FOREIGN KEY (travel_class_code)
    REFERENCES travel_class(travel_class_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_reservation_passenger (passenger_id),
  INDEX idx_reservation_agent (agent_id),
  INDEX idx_reservation_created (created_at_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE payment (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  payment_status_code VARCHAR(20) NOT NULL,
  payment_date_utc DATETIME NOT NULL,
  payment_amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(40) NOT NULL,
  CONSTRAINT fk_payment_status FOREIGN KEY (payment_status_code)
    REFERENCES payment_status(payment_status_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_payment_date (payment_date_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE flight_leg (
  leg_id INT AUTO_INCREMENT PRIMARY KEY,
  flight_number VARCHAR(20) NOT NULL,
  origin_airport_code VARCHAR(10) NOT NULL,
  destination_airport_code VARCHAR(10) NOT NULL,
  actual_departure_utc DATETIME NULL,
  actual_arrival_utc DATETIME NULL,
  CONSTRAINT fk_leg_schedule FOREIGN KEY (flight_number)
    REFERENCES flight_schedule(flight_number) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_leg_origin FOREIGN KEY (origin_airport_code)
    REFERENCES airport(airport_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_leg_destination FOREIGN KEY (destination_airport_code)
    REFERENCES airport(airport_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_leg_schedule (flight_number),
  INDEX idx_leg_route (origin_airport_code, destination_airport_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE flight_cost (
  flight_number VARCHAR(20) NOT NULL,
  aircraft_type_code VARCHAR(20) NOT NULL,
  valid_from_date DATE NOT NULL,
  valid_to_date DATE NOT NULL,
  cost_amount DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (flight_number, aircraft_type_code, valid_from_date),
  CONSTRAINT fk_cost_schedule FOREIGN KEY (flight_number)
    REFERENCES flight_schedule(flight_number) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cost_aircraft FOREIGN KEY (aircraft_type_code)
    REFERENCES aircraft_type(aircraft_type_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cost_valid_from FOREIGN KEY (valid_from_date)
    REFERENCES calendar_date(calendar_date) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cost_valid_to FOREIGN KEY (valid_to_date)
    REFERENCES calendar_date(calendar_date) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_cost_lookup (flight_number, aircraft_type_code, valid_from_date, valid_to_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reservation_payment (
  reservation_id INT NOT NULL,
  payment_id INT NOT NULL,
  PRIMARY KEY (reservation_id, payment_id),
  CONSTRAINT fk_rp_reservation FOREIGN KEY (reservation_id)
    REFERENCES reservation(reservation_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_rp_payment FOREIGN KEY (payment_id)
    REFERENCES payment(payment_id) ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_rp_payment (payment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reservation_leg (
  reservation_id INT NOT NULL,
  leg_id INT NOT NULL,
  PRIMARY KEY (reservation_id, leg_id),
  CONSTRAINT fk_rl_reservation FOREIGN KEY (reservation_id)
    REFERENCES reservation(reservation_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_rl_leg FOREIGN KEY (leg_id)
    REFERENCES flight_leg(leg_id) ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_rl_leg (leg_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- EXPECTED: 17 tables total.
SELECT COUNT(*) AS created_table_count
FROM information_schema.tables
WHERE table_schema = 'harborwing_air'
  AND table_type = 'BASE TABLE';
