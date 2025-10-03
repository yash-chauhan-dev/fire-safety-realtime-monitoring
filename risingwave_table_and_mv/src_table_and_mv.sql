-- # PUMP METER 1 SOURCE TABLE
CREATE TABLE pump_meter_1 (
  device_id VARCHAR,
  device_name VARCHAR,
  time_stamp TIMESTAMPTZ,
  currentA DOUBLE PRECISION,
  currentB DOUBLE PRECISION,
  currentC DOUBLE PRECISION,
  voltageAB DOUBLE PRECISION,
  voltageBC DOUBLE PRECISION,
  voltageCA DOUBLE PRECISION,
  voltageAN DOUBLE PRECISION,
  voltageBN DOUBLE PRECISION,
  voltageCN DOUBLE PRECISION,
  activepower DOUBLE PRECISION,
  apparentpower DOUBLE PRECISION,
  powerfactor DOUBLE PRECISION,
  unit DOUBLE PRECISION
)
WITH (
  connector = 'mqtt',
  url = 'tcp://host.docker.internal:1883',
  topic = '/firesafety/pump/1/em',
  qos = 'at_least_once'
)
FORMAT PLAIN ENCODE JSON;

-- # PUMP METER 1 SOURCE TABLE
CREATE TABLE pump_meter_2 (
  device_id VARCHAR,
  device_name VARCHAR,
  time_stamp TIMESTAMPTZ,
  currentA DOUBLE PRECISION,
  currentB DOUBLE PRECISION,
  currentC DOUBLE PRECISION,
  voltageAB DOUBLE PRECISION,
  voltageBC DOUBLE PRECISION,
  voltageCA DOUBLE PRECISION,
  voltageAN DOUBLE PRECISION,
  voltageBN DOUBLE PRECISION,
  voltageCN DOUBLE PRECISION,
  activepower DOUBLE PRECISION,
  apparentpower DOUBLE PRECISION,
  powerfactor DOUBLE PRECISION,
  unit DOUBLE PRECISION
)
WITH (
  connector = 'mqtt',
  url = 'tcp://host.docker.internal:1883',
  topic = '/firesafety/pump/2/em',
  qos = 'at_least_once'
)
FORMAT PLAIN ENCODE JSON;

-- # PUMP STATUS SOURCE TABLE
CREATE TABLE pump_status (
    device_id VARCHAR,
    pump_id VARCHAR,
    device_name VARCHAR,
    time_stamp TIMESTAMPTZ,
    status VARCHAR  -- 'ON' or 'OFF'
)
WITH (
    connector = 'mqtt',
    url = 'tcp://host.docker.internal:1883',
    topic = '/firesafety/pump/status',
    qos = 'at_least_once'
)
FORMAT PLAIN ENCODE JSON;

-- # PUMP METER ALL MATERIALIZED VIEW
CREATE MATERIALIZED VIEW pump_meter_all AS
SELECT
    device_id,
    device_name,
    time_stamp,
    currentA,
    currentB,
    currentC,
    voltageAB,
    voltageBC,
    voltageCA,
    voltageAN,
    voltageBN,
    voltageCN,
    activepower,
    apparentpower,
    powerfactor,
    unit
FROM pump_meter_1

UNION ALL

SELECT
    device_id,
    device_name,
    time_stamp,
    currentA,
    currentB,
    currentC,
    voltageAB,
    voltageBC,
    voltageCA,
    voltageAN,
    voltageBN,
    voltageCN,
    activepower,
    apparentpower,
    powerfactor, 
    unit
FROM pump_meter_2;

-- # PUMP METER SUMMARY MATERIALIZED VIEW
CREATE MATERIALIZED VIEW pump_meter_summary AS
SELECT
    device_id,
    device_name,
    window_start AS minute_start,
    AVG(currentA) AS avg_currentA,
    AVG(currentB) AS avg_currentB,
    AVG(currentC) AS avg_currentC,
    AVG(voltageAB) AS avg_voltageAB,
    AVG(voltageBC) AS avg_voltageBC,
    AVG(voltageCA) AS avg_voltageCA,
    AVG(voltageAN) AS avg_voltageAN,
    AVG(voltageBN) AS avg_voltageBN,
    AVG(voltageCN) AS avg_voltageCN,
    AVG(activepower) AS avg_activepower,
    AVG(apparentpower) AS avg_apparentpower,
    AVG(powerfactor) AS avg_powerfactor,
    AVG(unit) AS unit
FROM TUMBLE(
    pump_meter_all,
    time_stamp,
    INTERVAL '1 MINUTE'
)
GROUP BY device_id, device_name, window_start;

-- # PUMP METER REALTIME MATERIALIZED VIEW
CREATE MATERIALIZED VIEW pump_meter_realtime AS
SELECT
    device_id,
    device_name,
    window_start AS window_start_time,
    AVG(currentA) AS avg_currentA,
    AVG(currentB) AS avg_currentB,
    AVG(currentC) AS avg_currentC,
    AVG(voltageAB) AS avg_voltageAB,
    AVG(voltageBC) AS avg_voltageBC,
    AVG(voltageCA) AS avg_voltageCA,
    AVG(voltageAN) AS avg_voltageAN,
    AVG(voltageBN) AS avg_voltageBN,
    AVG(voltageCN) AS avg_voltageCN,
    AVG(activepower) AS avg_activepower,
    AVG(apparentpower) AS avg_apparentpower,
    AVG(powerfactor) AS avg_powerfactor
FROM TUMBLE(
    pump_meter_all,
    time_stamp,
    INTERVAL '10 SECOND'
)
GROUP BY device_id, device_name, window_start;

-- # PUMP STATUS WITH ENERGY MATERIALIZED VIEW
CREATE MATERIALIZED VIEW pump_status_with_energy AS
SELECT
    s.device_id,
    s.device_name,
    s.pump_id,
    s.time_stamp AS status_time,
    s.status,
    e.currentA,
    e.currentB,
    e.currentC,
    e.voltageAB,
    e.voltageBC,
    e.voltageCA,
    e.voltageAN,
    e.voltageBN,
    e.voltageCN,
    e.activepower,
    e.apparentpower,
    e.powerfactor
FROM pump_status AS s
LEFT JOIN LATERAL (
    SELECT *
    FROM pump_meter_all AS e
    WHERE e.device_id = s.device_id
      AND e.time_stamp <= s.time_stamp
    ORDER BY e.time_stamp DESC
    LIMIT 1
) AS e ON TRUE;

-- # PUMP STATUS CHANGES MATERIALIZED VIEW
CREATE MATERIALIZED VIEW pump_status_changes AS
SELECT
    s.device_id,      -- energy meter id
    s.device_name,
    s.pump_id,        -- pump id we want to track
    s.time_stamp AS change_time,
    s.status,
    e.currentA,
    e.currentB,
    e.currentC,
    e.voltageAB,
    e.voltageBC,
    e.voltageCA,
    e.voltageAN,
    e.voltageBN,
    e.voltageCN,
    e.activepower,
    e.apparentpower,
    e.powerfactor
FROM (
    SELECT
        device_id,
        device_name,
        pump_id,
        time_stamp,
        status,
        LAG(status) OVER (
            PARTITION BY pump_id
            ORDER BY time_stamp
        ) AS prev_status
    FROM pump_status
) s
LEFT JOIN LATERAL (
    SELECT *
    FROM pump_meter_all AS e
    WHERE e.device_id = s.device_id
      AND e.time_stamp <= s.time_stamp
    ORDER BY e.time_stamp DESC
    LIMIT 1
) e ON TRUE
WHERE s.prev_status IS NULL OR s.status <> s.prev_status;

