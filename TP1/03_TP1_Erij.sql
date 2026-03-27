-- ============================================================
--  SCRIPT 3 : TP n°1 — Fonctions SQL et Requêtes
--  À exécuter APRÈS 01_createschema.sql et 02_data.sql
-- ============================================================

SPOOL tp1_erij.log

SET COLSEP '|'
SET LINESIZE 200
SET PAGESIZE 20


-- ============================================================
--  FONCTIONS SQL — Tests sur DUAL
-- ============================================================

-- TO_CHAR : convertit une date/nombre en chaîne
SELECT TO_CHAR(SYSDATE, 'DD/MM/YYYY') AS to_char_exemple FROM DUAL;

-- RPAD : complète à droite
SELECT RPAD('SQL', 10, '*') AS rpad_exemple FROM DUAL;

-- LPAD : complète à gauche
SELECT LPAD('42', 6, '0') AS lpad_exemple FROM DUAL;

-- SUBSTR : extrait une sous-chaîne
SELECT SUBSTR('Informatique', 1, 5) AS substr_exemple FROM DUAL;

-- LENGTH : longueur d'une chaîne
SELECT LENGTH('Bonjour') AS length_exemple FROM DUAL;

-- ROUND : arrondit un nombre
SELECT ROUND(3.14159, 2) AS round_exemple FROM DUAL;

-- TRUNC : tronque sans arrondir
SELECT TRUNC(3.99) AS trunc_exemple FROM DUAL;

-- TO_DATE : convertit une chaîne en date
SELECT TO_DATE('01/01/2024', 'DD/MM/YYYY') AS to_date_exemple FROM DUAL;

-- EXTRACT : extrait une composante d'une date
SELECT EXTRACT(YEAR FROM SYSDATE) AS extract_exemple FROM DUAL;


-- ============================================================
--  EXERCICE 1
-- ============================================================

-- 4. Insertion du cours BIO-101
-- (déjà présent dans le script data, ligne ci-dessous en commentaire)
-- INSERT INTO course VALUES ('BIO-101', 'Intro. to Biology', 'Biology', 4);
-- COMMIT;


-- ============================================================
--  EXERCICE 2 — Requêtes SQL
-- ============================================================

-- Q1 : Structure et contenu de la relation section
DESC section;
SELECT * FROM section;

-- Q2 : Tous les renseignements sur les cours (relation course)
SELECT * FROM course;

-- Q3 : Titres des cours et départements
SELECT title, dept_name
FROM course;

-- Q4 : Noms des départements et leur budget
SELECT dept_name, budget
FROM department;

-- Q5 : Noms des enseignants et leur département
SELECT name, dept_name
FROM teacher;

-- Q6 : Enseignants avec salaire strictement supérieur à 65 000 $
SELECT name
FROM teacher
WHERE salary > 65000;

-- Q7 : Enseignants avec salaire entre 55 000 $ et 85 000 $
SELECT name
FROM teacher
WHERE salary BETWEEN 55000 AND 85000;

-- Q8 : Noms des départements sans doublons (depuis teacher)
SELECT DISTINCT dept_name
FROM teacher;

-- Q9 : Enseignants du département informatique avec salaire > 65 000 $
SELECT name
FROM teacher
WHERE dept_name = 'Comp. Sci.'
  AND salary > 65000;

-- Q10 : Cours proposés au printemps 2010
SELECT *
FROM section
WHERE semester = 'Spring'
  AND year = 2010;

-- Q11 : Cours du département informatique avec plus de 3 crédits
SELECT title
FROM course
WHERE dept_name = 'Comp. Sci.'
  AND credits > 3;

-- Q12 : Enseignants, département et bâtiment qui les héberge
SELECT t.name, t.dept_name, d.building
FROM teacher t
JOIN department d ON t.dept_name = d.dept_name;

-- Q13 : Étudiants ayant suivi au moins un cours en informatique
SELECT DISTINCT s.name
FROM student s
JOIN takes t  ON s.ID = t.ID
JOIN course c ON t.course_id = c.course_id
WHERE c.dept_name = 'Comp. Sci.';

-- Q14 : Étudiants ayant suivi un cours dispensé par Einstein (sans doublons)
SELECT DISTINCT s.name
FROM student s
JOIN takes t    ON s.ID = t.ID
JOIN teaches te ON t.course_id = te.course_id
               AND t.sec_id    = te.sec_id
               AND t.semester  = te.semester
               AND t.year      = te.year
JOIN teacher i  ON te.ID = i.ID
WHERE i.name = 'Einstein';

-- Q15 : Identifiants des cours et enseignants qui les ont assurés
SELECT course_id, ID
FROM teaches;

-- Q16 : Nombre d'inscrits par enseignement proposé au printemps 2010
SELECT t.course_id, t.sec_id, COUNT(*) AS nb_inscrits
FROM takes t
WHERE t.semester = 'Spring'
  AND t.year = 2010
GROUP BY t.course_id, t.sec_id;

-- Q17 : Salaire maximum des enseignants par département
SELECT dept_name, MAX(salary) AS salaire_max
FROM teacher
GROUP BY dept_name;

-- Q18 : Nombre d'inscrits par enseignement (tous semestres)
SELECT course_id, sec_id, semester, year, COUNT(*) AS nb_inscrits
FROM takes
GROUP BY course_id, sec_id, semester, year;

-- Q19 : Nombre total de cours par bâtiment (automne 2009 et printemps 2010)
SELECT building, COUNT(*) AS nb_cours
FROM section
WHERE (semester = 'Fall'   AND year = 2009)
   OR (semester = 'Spring' AND year = 2010)
GROUP BY building;

-- Q20 : Cours dispensés par chaque département dans son propre bâtiment
SELECT c.dept_name, COUNT(*) AS nb_cours
FROM section s
JOIN course     c ON s.course_id = c.course_id
JOIN department d ON c.dept_name = d.dept_name
WHERE s.building = d.building
GROUP BY c.dept_name;

-- Q21 : Titres des cours ayant eu lieu et enseignants qui les ont assurés
SELECT DISTINCT c.title, t.name
FROM course c
JOIN teaches te ON c.course_id = te.course_id
JOIN teacher t  ON te.ID       = t.ID;

-- Q22 : Nombre total de cours par période (Summer, Fall, Spring)
SELECT semester, COUNT(*) AS nb_cours
FROM section
WHERE semester IN ('Summer', 'Fall', 'Spring')
GROUP BY semester;

-- Q23 : Crédits hors département obtenus par chaque étudiant
SELECT t.ID, SUM(c.credits) AS total_credits
FROM takes t
JOIN course  c ON t.course_id = c.course_id
JOIN student s ON t.ID        = s.ID
WHERE c.dept_name != s.dept_name
GROUP BY t.ID;

-- Q24 : Crédits des cours ayant eu lieu dans le bâtiment du département
SELECT c.dept_name, SUM(c.credits) AS total_credits
FROM course     c
JOIN section    s ON c.course_id = s.course_id
JOIN department d ON c.dept_name = d.dept_name
WHERE s.building = d.building
GROUP BY c.dept_name;

SPOOL OFF
