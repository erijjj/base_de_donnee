-- ============================================================
--  TP n°2 — Exercice 1 : Requêtes SQL
-- ============================================================

SPOOL tp2_erij.log
SET COLSEP '|'
SET LINESIZE 200
SET PAGESIZE 30

-- Q1 : Département avec le budget le plus élevé
SELECT dept_name
FROM department
WHERE budget = (SELECT MAX(budget) FROM department);

-- Q2 : Enseignants gagnant plus que le salaire moyen
SELECT name, salary
FROM teacher
WHERE salary > (SELECT AVG(salary) FROM teacher)
ORDER BY salary DESC;

-- Q3 : Pour chaque enseignant, étudiants ayant suivi plus de 2 cours avec lui (HAVING)
SELECT te.ID AS teacher_id, t.name AS teacher_name,
       tk.ID AS student_id, s.name AS student_name,
       COUNT(*) AS nb_cours
FROM teaches te
JOIN teacher  t  ON te.ID        = t.ID
JOIN takes    tk ON te.course_id = tk.course_id
                AND te.sec_id    = tk.sec_id
                AND te.semester  = tk.semester
                AND te.year      = tk.year
JOIN student  s  ON tk.ID        = s.ID
GROUP BY te.ID, t.name, tk.ID, s.name
HAVING COUNT(*) > 2;

-- Q4 : Même requête SANS HAVING
SELECT *
FROM (
    SELECT te.ID AS teacher_id, t.name AS teacher_name,
           tk.ID AS student_id, s.name AS student_name,
           COUNT(*) AS nb_cours
    FROM teaches te
    JOIN teacher  t  ON te.ID        = t.ID
    JOIN takes    tk ON te.course_id = tk.course_id
                    AND te.sec_id    = tk.sec_id
                    AND te.semester  = tk.semester
                    AND te.year      = tk.year
    JOIN student  s  ON tk.ID        = s.ID
    GROUP BY te.ID, t.name, tk.ID, s.name
)
WHERE nb_cours > 2;

-- Q5 : Étudiants n'ayant pas suivi de cours avant 2010
SELECT DISTINCT s.ID, s.name
FROM student s
WHERE s.ID NOT IN (
    SELECT ID FROM takes WHERE year < 2010
);

-- Q6 : Enseignants dont le nom commence par E
SELECT name
FROM teacher
WHERE name LIKE 'E%';

-- Q7 : Enseignants avec le 4ème salaire le plus élevé
SELECT name, salary
FROM teacher t1
WHERE 3 = (
    SELECT COUNT(DISTINCT salary)
    FROM teacher t2
    WHERE t2.salary > t1.salary
);

-- Q8 : Les 3 enseignants avec les salaires les plus bas
SELECT name, salary
FROM (
    SELECT name, salary
    FROM teacher
    ORDER BY salary ASC
)
WHERE ROWNUM <= 3
ORDER BY salary DESC;

-- Q9 : Étudiants ayant suivi un cours en automne 2009 (IN)
SELECT DISTINCT name
FROM student
WHERE ID IN (
    SELECT ID FROM takes
    WHERE semester = 'Fall' AND year = 2009
);

-- Q10 : Étudiants ayant suivi un cours en automne 2009 (SOME/ANY)
SELECT DISTINCT s.name
FROM student s
WHERE s.ID = SOME (
    SELECT ID FROM takes
    WHERE semester = 'Fall' AND year = 2009
);

-- Q11 : Étudiants ayant suivi un cours en automne 2009 (NATURAL INNER JOIN)
SELECT DISTINCT s.name
FROM student s
NATURAL INNER JOIN takes t
WHERE t.semester = 'Fall' AND t.year = 2009;

-- Q12 : Étudiants ayant suivi un cours en automne 2009 (EXISTS)
SELECT DISTINCT s.name
FROM student s
WHERE EXISTS (
    SELECT 1 FROM takes t
    WHERE t.ID = s.ID
      AND t.semester = 'Fall'
      AND t.year = 2009
);

-- Q13 : Toutes les paires d'étudiants ayant suivi au moins un cours ensemble
SELECT DISTINCT s1.name AS etudiant1, s2.name AS etudiant2
FROM takes t1
JOIN takes t2 ON t1.course_id = t2.course_id
             AND t1.sec_id    = t2.sec_id
             AND t1.semester  = t2.semester
             AND t1.year      = t2.year
             AND t1.ID        < t2.ID
JOIN student s1 ON t1.ID = s1.ID
JOIN student s2 ON t2.ID = s2.ID
ORDER BY s1.name, s2.name;

-- Q14 : Pour chaque enseignant ayant assuré un cours : nb total d'étudiants
SELECT t.name AS teacher_name, COUNT(*) AS nb_etudiants
FROM teaches te
JOIN teacher  t  ON te.ID        = t.ID
JOIN takes    tk ON te.course_id = tk.course_id
                AND te.sec_id    = tk.sec_id
                AND te.semester  = tk.semester
                AND te.year      = tk.year
GROUP BY t.name
ORDER BY nb_etudiants DESC;

-- Q15 : Pour TOUS les enseignants : nb total d'étudiants (LEFT JOIN)
SELECT t.name AS teacher_name, COUNT(tk.ID) AS nb_etudiants
FROM teacher t
LEFT JOIN teaches te ON t.ID         = te.ID
LEFT JOIN takes   tk ON te.course_id = tk.course_id
                    AND te.sec_id    = tk.sec_id
                    AND te.semester  = tk.semester
                    AND te.year      = tk.year
GROUP BY t.name
ORDER BY nb_etudiants DESC;

-- Q16 : Pour chaque enseignant, nombre total de grades A attribués
SELECT t.name AS teacher_name, COUNT(*) AS nb_grades_A
FROM teaches te
JOIN teacher  t  ON te.ID        = t.ID
JOIN takes    tk ON te.course_id = tk.course_id
                AND te.sec_id    = tk.sec_id
                AND te.semester  = tk.semester
                AND te.year      = tk.year
WHERE tk.grade = 'A'
GROUP BY t.name
ORDER BY nb_grades_A DESC;

-- Q17 : Paires enseignant-étudiant + nb de fois que l'étudiant a suivi un cours de l'enseignant
SELECT t.name AS teacher_name, s.name AS student_name, COUNT(*) AS nb_cours
FROM teaches te
JOIN teacher  t  ON te.ID        = t.ID
JOIN takes    tk ON te.course_id = tk.course_id
                AND te.sec_id    = tk.sec_id
                AND te.semester  = tk.semester
                AND te.year      = tk.year
JOIN student  s  ON tk.ID        = s.ID
GROUP BY t.name, s.name
ORDER BY t.name, s.name;

-- Q18 : Paires enseignant-étudiant où l'étudiant a suivi AU MOINS 2 cours de cet enseignant
SELECT t.name AS teacher_name, s.name AS student_name, COUNT(*) AS nb_cours
FROM teaches te
JOIN teacher  t  ON te.ID        = t.ID
JOIN takes    tk ON te.course_id = tk.course_id
                AND te.sec_id    = tk.sec_id
                AND te.semester  = tk.semester
                AND te.year      = tk.year
JOIN student  s  ON tk.ID        = s.ID
GROUP BY t.name, s.name
HAVING COUNT(*) >= 2
ORDER BY t.name, s.name;

SPOOL OFF
