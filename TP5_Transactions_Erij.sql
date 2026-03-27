-- ============================================================
--  TP n°5 — Transactions et contrôle de concurrence
-- ============================================================

--  EXERCICE 1 — Atomicité d'une transaction
-- ============================================================

SET AUTOCOMMIT OFF


-- 1 : Créer la table (terminal 1)
CREATE TABLE transaction (
    idTransaction   VARCHAR2(44),
    valTransaction  NUMBER(10)
);


--2 : Terminal 2

-- Inserer quelques lignes
INSERT INTO transaction VALUES ('T001', 100);
INSERT INTO transaction VALUES ('T002', 200);
INSERT INTO transaction VALUES ('T003', 300);

-- Modifier une ligne
UPDATE transaction SET valTransaction = 999 WHERE idTransaction = 'T001';

-- Supprimer une ligne
DELETE FROM transaction WHERE idTransaction = 'T002';

-- Afficher le contenu AVANT rollback (T2 voit ses propres modifs)
SELECT * FROM transaction;

-- Annuler toutes les modifications
ROLLBACK;

-- Afficher après rollback -> table vide
SELECT * FROM transaction;


--  3 : Terminal 2 : INSERT puis QUIT

INSERT INTO transaction VALUES ('T010', 500);
INSERT INTO transaction VALUES ('T011', 600);

-- Fermer avec quit (sans COMMIT)
-- quit;

-- Terminal 1 : afficher le contenu
-- → La table est VIDE car quit sans commit = rollback automatique
SELECT * FROM transaction;

/*
CONCLUSION 3 :
quit sans COMMIT provoque un ROLLBACK automatique.
Les données non commitées sont perdues.
*/


--  4 : terminal 1 : INSERT puis fermeture brutale

INSERT INTO transaction VALUES ('T020', 700);
INSERT INTO transaction VALUES ('T021', 800);

-- Fermer brutalement la fenetre
-- Reconnection et vérification :
SELECT * FROM transaction;

/*
conclusion  4 :
Une fermeture brutale = ROLLBACK automatique.
Les données non commitées sont perdues.
*/


-- 5 : ROLLBACK après DDL (ALTER TABLE)

INSERT INTO transaction VALUES ('T030', 900);

-- Modification de la structure de la table 
ALTER TABLE transaction ADD (val2transaction NUMBER(10));

-- un ROLLBACK
ROLLBACK;

-- Vérifier la structure et les donnees
DESC transaction;
SELECT * FROM transaction;

/*
CONCLUSION  5 :
Un ordre DDL (CREATE, ALTER, DROP...) provoque un COMMIT implicite automatique.
Le ROLLBACK ne peut pas annuler l'ALTER TABLE ni les INSERT qui le précèdent.
Les données insérées avant le DDL sont donc commitées définitivement.
*/


-- 6 : Conclusions

/*
SESSION :
  Une session est une connexion active entre un utilisateur et Oracle.
  Elle commence à la connexion et se termine à la déconnexion (quit, exit).
  Une session peut contenir plusieurs transactions executees en série.

TRANSACTION :
  Une transaction est une unité logique de travail constituee d'une
  suite d'operations SQL (INSERT, UPDATE, DELETE).
  Elle commence implicitement au premier ordre DML et se termine par :
    - COMMIT  : validation définitive des modifications
    - ROLLBACK : annulation de toutes les modifications depuis le dernier COMMIT
    - Un ordre DDL (COMMIT implicite automatique)
    - quit/exit sans COMMIT (ROLLBACK automatique)

VALIDER une transaction   : COMMIT;
ANNULER une transaction   : ROLLBACK;
*/


--  EXERCICE 2 — Transactions concurrentes
-- ============================================================

-- Création des tables
CREATE TABLE vol (
    idVol               VARCHAR2(44),
    capaciteVol         NUMBER(10),
    nbrPlacesReserveesVol NUMBER(10)
);

CREATE TABLE client (
    idClient                VARCHAR2(44),
    prenomClient            VARCHAR2(11),
    nbrPlacesReserveesCleint NUMBER(10)
);

-- Insérer un vol et deux clients
INSERT INTO vol    VALUES ('VOL001', 100, 0);
INSERT INTO client VALUES ('C001', 'Alice', 0);
INSERT INTO client VALUES ('C002', 'Bob',   0);
COMMIT;


-- ISOLATION : T1 réserve sans valider 

-- Terminal 1 :
UPDATE vol    SET nbrPlacesReserveesVol      = nbrPlacesReserveesVol + 2    WHERE idVol    = 'VOL001';
UPDATE client SET nbrPlacesReserveesCleint   = nbrPlacesReserveesCleint + 2 WHERE idClient = 'C001';

-- Terminal 1 voit ses propres modifs :
SELECT * FROM vol;
SELECT * FROM client;

-- Terminal 2 : vérifier → NE VOIT PAS les modifs de T1
SELECT * FROM vol;
SELECT * FROM client;

-- Terminal 1 : ROLLBACK
ROLLBACK;

-- Après ROLLBACK → tout le monde voit l'état initial
SELECT * FROM vol;
SELECT * FROM client;


-- COMMIT et DURABILITÉ

-- Terminal 1 : refaire la réservation et COMMIT
UPDATE vol    SET nbrPlacesReserveesVol      = nbrPlacesReserveesVol + 2    WHERE idVol    = 'VOL001';
UPDATE client SET nbrPlacesReserveesCleint   = nbrPlacesReserveesCleint + 2 WHERE idClient = 'C001';
COMMIT;

-- ROLLBACK après COMMIT → aucun effet
ROLLBACK;

-- Terminal 2 voit maintenant les modifs de T1
SELECT * FROM vol;
SELECT * FROM client;


-- PROBLEME DES MISES À JOUR PERDUES 

-- Reinitialiser
UPDATE vol    SET nbrPlacesReserveesVol = 0 WHERE idVol = 'VOL001';
UPDATE client SET nbrPlacesReserveesCleint = 0 WHERE idClient = 'C001';
UPDATE client SET nbrPlacesReserveesCleint = 0 WHERE idClient = 'C002';
COMMIT;

-- Deroulement en // :

-- T1 : Lire vol et client C001
-- Terminal 1 :
SELECT nbrPlacesReserveesVol FROM vol WHERE idVol = 'VOL001';        -- → 0
SELECT nbrPlacesReserveesCleint FROM client WHERE idClient = 'C001'; -- → 0

-- T2 : Lire vol et client C002
-- Terminal 2 :
SELECT nbrPlacesReserveesVol FROM vol WHERE idVol = 'VOL001';        -- → 0 (T1 pas encore validé)
SELECT nbrPlacesReserveesCleint FROM client WHERE idClient = 'C002'; -- → 0

-- T1 : Mettre à jour et valider (+2 billets)
-- Terminal 1 :
UPDATE vol    SET nbrPlacesReserveesVol      = 0 + 2 WHERE idVol    = 'VOL001';
UPDATE client SET nbrPlacesReserveesCleint   = 0 + 2 WHERE idClient = 'C001';
COMMIT;

-- T2 : Mettre à jour et valider (+3 billets) -> ÉCRASE la valeur de T1
-- Terminal 2 :
UPDATE vol    SET nbrPlacesReserveesVol      = 0 + 3 WHERE idVol    = 'VOL001'; -- ← repart de 0 lu avant
UPDATE client SET nbrPlacesReserveesCleint   = 0 + 3 WHERE idClient = 'C002';
COMMIT;

-- Resultat final : vol = 3 au lieu de 5 -> incoherence
SELECT * FROM vol;
SELECT * FROM client;

/*
CONCLUSION MISE À JOUR PERDUE :
T2 a lu la valeur 0 AVANT que T1 ne valide ses +2.
T2 écrase donc le résultat de T1 avec 0+3=3 au lieu de 2+3=5.
-> Probleme classique de "lost update" en READ COMMITTED.
*/


-- MODE SERIALIZABLE : isolation complete

-- Reinitialiser
UPDATE vol    SET nbrPlacesReserveesVol = 0 WHERE idVol = 'VOL001';
UPDATE client SET nbrPlacesReserveesCleint = 0 WHERE idClient = 'C001';
UPDATE client SET nbrPlacesReserveesCleint = 0 WHERE idClient = 'C002';
COMMIT;

-- Activer SERIALIZABLE dans les deux terminaux
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Terminal 1 (T1) :
SELECT nbrPlacesReserveesVol FROM vol WHERE idVol = 'VOL001';
UPDATE vol    SET nbrPlacesReserveesVol    = nbrPlacesReserveesVol + 2 WHERE idVol    = 'VOL001';
UPDATE client SET nbrPlacesReserveesCleint = nbrPlacesReserveesCleint + 2 WHERE idClient = 'C001';
COMMIT;

-- Terminal2 (T2) en // :
SELECT nbrPlacesReserveesVol FROM vol WHERE idVol = 'VOL001';
UPDATE vol    SET nbrPlacesReserveesVol    = nbrPlacesReserveesVol + 3 WHERE idVol    = 'VOL001';
-- -> ORA-08177 : can't serialize access for this transaction
-- T2 est rejetée automatiquement

/*
CONCLUSION SERIALIZABLE :
En mode SERIALIZABLE, Oracle détecte le conflit et rejette T2.
La cohérence est garantie mais au prix d'un possible rejet de transaction.
*/


-- Réinitialiser
UPDATE vol SET nbrPlacesReserveesVol = 10 WHERE idVol = 'VOL001';
COMMIT;

-- Mode READ COMMITTED (défaut Oracle)

-- Terminal 1 : r1(d) — lire d
SELECT nbrPlacesReserveesVol FROM vol WHERE idVol = 'VOL001'; -- → 10

-- Terminal 2 : w2(d) — écrire d
UPDATE vol SET nbrPlacesReserveesVol = 20 WHERE idVol = 'VOL001';

-- Terminal 2 : w2(d') — écrire d'
UPDATE vol SET nbrPlacesReserveesVol = 30 WHERE idVol = 'VOL001';

-- Terminal 2 : C2 — valider T2
COMMIT;

-- Terminal 1 : w1(d') — écrire d'
UPDATE vol SET nbrPlacesReserveesVol = 50 WHERE idVol = 'VOL001';

-- Terminal 1 : C1 — valider T1
COMMIT;

-- Résultat
SELECT * FROM vol;

