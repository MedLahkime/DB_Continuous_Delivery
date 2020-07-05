use db;
ALTER TABLE place
  ADD lane int NOT NULL DEFAULT '0';
