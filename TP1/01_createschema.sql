-- ============================================================
-- CRÉATION DU SCHÉMA
--  À exécuter EN PREMIER
-- ============================================================

-- Suppression dans le bon ordre (clés étrangères d'abord)
DROP TABLE prereq      CASCADE CONSTRAINTS PURGE;
DROP TABLE time_slot   CASCADE CONSTRAINTS PURGE;
DROP TABLE advisor     CASCADE CONSTRAINTS PURGE;
DROP TABLE takes       CASCADE CONSTRAINTS PURGE;
DROP TABLE student     CASCADE CONSTRAINTS PURGE;
DROP TABLE teaches     CASCADE CONSTRAINTS PURGE;
DROP TABLE section     CASCADE CONSTRAINTS PURGE;
DROP TABLE teacher     CASCADE CONSTRAINTS PURGE;
DROP TABLE course      CASCADE CONSTRAINTS PURGE;
DROP TABLE department  CASCADE CONSTRAINTS PURGE;
DROP TABLE classroom   CASCADE CONSTRAINTS PURGE;

-- classroom
CREATE TABLE classroom (
    building     VARCHAR2(15),
    room_number  VARCHAR2(7),
    capacity     NUMERIC(4,0),
    PRIMARY KEY (building, room_number)
);

-- department
CREATE TABLE department (
    dept_name  VARCHAR2(20),
    building   VARCHAR2(15),
    budget     NUMERIC(12,2),
    PRIMARY KEY (dept_name)
);

-- course
CREATE TABLE course (
    course_id  VARCHAR2(8),
    title      VARCHAR2(50),
    dept_name  VARCHAR2(20),
    credits    NUMERIC(2,0),
    PRIMARY KEY (course_id),
    FOREIGN KEY (dept_name) REFERENCES department
);

-- teacher
CREATE TABLE teacher (
    ID         VARCHAR2(5),
    name       VARCHAR2(20),
    dept_name  VARCHAR2(20),
    salary     NUMERIC(8,2),
    PRIMARY KEY (ID),
    FOREIGN KEY (dept_name) REFERENCES department
);

-- section
CREATE TABLE section (
    course_id    VARCHAR2(8),
    sec_id       VARCHAR2(8),
    semester     VARCHAR2(6) CHECK (semester IN ('Fall', 'Winter', 'Spring', 'Summer')),
    year         NUMERIC(4,0),
    building     VARCHAR2(15),
    room_number  VARCHAR2(7),
    time_slot_id VARCHAR2(4),
    PRIMARY KEY (course_id, sec_id, semester, year),
    FOREIGN KEY (course_id) REFERENCES course,
    FOREIGN KEY (building, room_number) REFERENCES classroom
);

-- teaches
CREATE TABLE teaches (
    ID         VARCHAR2(5),
    course_id  VARCHAR2(8),
    sec_id     VARCHAR2(8),
    semester   VARCHAR2(6),
    year       NUMERIC(4,0),
    PRIMARY KEY (ID, course_id, sec_id, semester, year),
    FOREIGN KEY (course_id, sec_id, semester, year) REFERENCES section,
    FOREIGN KEY (ID) REFERENCES teacher
);

-- student
CREATE TABLE student (
    ID         VARCHAR2(5),
    name       VARCHAR2(20),
    dept_name  VARCHAR2(20),
    tot_cred   NUMERIC(3,0),
    PRIMARY KEY (ID),
    FOREIGN KEY (dept_name) REFERENCES department
);

-- takes
CREATE TABLE takes (
    ID         VARCHAR2(5),
    course_id  VARCHAR2(8),
    sec_id     VARCHAR2(8),
    semester   VARCHAR2(6),
    year       NUMERIC(4,0),
    grade      VARCHAR2(2),
    PRIMARY KEY (ID, course_id, sec_id, semester, year),
    FOREIGN KEY (course_id, sec_id, semester, year) REFERENCES section,
    FOREIGN KEY (ID) REFERENCES student
);

-- advisor
CREATE TABLE advisor (
    s_ID  VARCHAR2(5),
    i_ID  VARCHAR2(5),
    PRIMARY KEY (s_ID),
    FOREIGN KEY (i_ID) REFERENCES teacher(ID),
    FOREIGN KEY (s_ID) REFERENCES student(ID)
);

-- time_slot
CREATE TABLE time_slot (
    time_slot_id  VARCHAR2(4),
    day           VARCHAR2(1),
    start_hr      NUMERIC(2),
    start_min     NUMERIC(2),
    end_hr        NUMERIC(2),
    end_min       NUMERIC(2),
    PRIMARY KEY (time_slot_id, day, start_hr, start_min)
);

-- prereq
CREATE TABLE prereq (
    course_id  VARCHAR2(8),
    prereq_id  VARCHAR2(8),
    PRIMARY KEY (course_id, prereq_id),
    FOREIGN KEY (course_id) REFERENCES course,
    FOREIGN KEY (prereq_id) REFERENCES course
);

-- Confirmation
SELECT 'Schema cree avec succes' AS statut FROM DUAL;
